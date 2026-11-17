interface D1Result<T = Record<string, unknown>> {
  results?: T[];
  success: boolean;
  meta?: { changes?: number };
}
interface D1PreparedStatement {
  bind(...values: unknown[]): D1PreparedStatement;
  all<T = Record<string, unknown>>(): Promise<D1Result<T>>;
  first<T = Record<string, unknown>>(): Promise<T | null>;
}
interface D1Database {
  prepare(query: string): D1PreparedStatement;
}
interface Env {
  DB: D1Database;
}

type Listing = {
  id: string;
  slug: string;
  title: string;
  description: string;
  price_ugx: number;
  negotiable: number;
  condition: string;
  transaction_mode: string;
  town: string;
  area: string | null;
  category_name: string;
  category_slug: string;
  published_at: string | null;
};

const json = (data: unknown, status = 200): Response =>
  new Response(JSON.stringify(data), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": status === 200 ? "public, max-age=60, stale-while-revalidate=300" : "no-store",
      "x-content-type-options": "nosniff",
    },
  });

const textParam = (params: URLSearchParams, key: string, max: number): string | null => {
  const value = params.get(key)?.trim();
  return value ? value.slice(0, max) : null;
};

const integerParam = (params: URLSearchParams, key: string, fallback: number, min: number, max: number): number => {
  const raw = params.get(key);
  if (raw === null || raw === "") return fallback;
  if (!/^\d+$/.test(raw)) return fallback;
  return Math.min(max, Math.max(min, Number(raw)));
};

// FTS5 operators are not accepted from clients. Convert input to literal word tokens.
const searchExpression = (input: string | null): string | null => {
  if (!input) return null;
  const words = input.normalize("NFKC").match(/[\p{L}\p{N}]+/gu)?.slice(0, 8) ?? [];
  return words.length ? words.map((word) => `"${word.replace(/"/g, '""')}"`).join(" AND ") : null;
};

async function categories(env: Env): Promise<Response> {
  const result = await env.DB.prepare(
    `SELECT id, name, slug, icon, sort_order
       FROM categories
      WHERE is_active = 1
      ORDER BY sort_order ASC, name COLLATE NOCASE ASC`,
  ).all();
  return json({ data: result.results ?? [] });
}

async function catalogue(url: URL, env: Env): Promise<Response> {
  const params = url.searchParams;
  const page = integerParam(params, "page", 1, 1, 10000);
  const limit = integerParam(params, "limit", 20, 1, 50);
  const offset = (page - 1) * limit;
  const category = textParam(params, "category", 80);
  const town = textParam(params, "town", 80);
  const query = searchExpression(textParam(params, "q", 160));
  const minPrice = integerParam(params, "min_price", 0, 0, 2_000_000_000);
  const maxPriceRaw = params.get("max_price");
  const maxPrice = maxPriceRaw && /^\d+$/.test(maxPriceRaw)
    ? Math.min(2_000_000_000, Number(maxPriceRaw))
    : null;
  if (maxPrice !== null && maxPrice < minPrice) {
    return json({ error: "max_price must be greater than or equal to min_price" }, 400);
  }

  const sort = params.get("sort");
  const orderBy = sort === "price_asc" ? "l.price_ugx ASC, l.published_at DESC"
    : sort === "price_desc" ? "l.price_ugx DESC, l.published_at DESC"
    : "l.published_at DESC, l.created_at DESC";

  const conditions = [
    "l.status = 'published'",
    "c.is_active = 1",
    "l.price_ugx >= ?",
  ];
  const values: unknown[] = [minPrice];
  if (category) { conditions.push("c.slug = ?"); values.push(category); }
  if (town) { conditions.push("l.town = ?"); values.push(town); }
  if (maxPrice !== null) { conditions.push("l.price_ugx <= ?"); values.push(maxPrice); }
  if (query) {
    conditions.push("l.id IN (SELECT listing_id FROM listings_fts WHERE listings_fts MATCH ?)");
    values.push(query);
  }

  const where = conditions.join(" AND ");
  const count = await env.DB.prepare(
    `SELECT COUNT(*) AS total
       FROM listings l
       JOIN categories c ON c.id = l.category_id
      WHERE ${where}`,
  ).bind(...values).first<{ total: number }>();

  const result = await env.DB.prepare(
    `SELECT l.id, l.slug, l.title, l.description, l.price_ugx, l.negotiable,
            l.condition, l.transaction_mode, l.town, l.area,
            c.name AS category_name, c.slug AS category_slug, l.published_at
       FROM listings l
       JOIN categories c ON c.id = l.category_id
      WHERE ${where}
      ORDER BY ${orderBy}
      LIMIT ? OFFSET ?`,
  ).bind(...values, limit, offset).all<Listing>();

  return json({
    data: result.results ?? [],
    pagination: {
      page,
      limit,
      total: count?.total ?? 0,
      pages: Math.ceil((count?.total ?? 0) / limit),
    },
  });
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method !== "GET") {
      return json({ error: "Method not allowed" }, 405);
    }
    const url = new URL(request.url);
    try {
      if (url.pathname === "/health") return json({ ok: true, service: "guza-gura-catalogue" });
      if (url.pathname === "/api/categories") return await categories(env);
      if (url.pathname === "/api/catalogue") return await catalogue(url, env);
      return json({ error: "Not found" }, 404);
    } catch {
      return json({ error: "Catalogue temporarily unavailable" }, 503);
    }
  },
};
