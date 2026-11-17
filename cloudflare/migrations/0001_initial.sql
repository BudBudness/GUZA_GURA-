-- D1 port of the marketplace domain schema.
-- No identity provider, payments provider, public writes or production data are configured here.
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS profiles (
  id TEXT PRIMARY KEY,
  display_name TEXT NOT NULL CHECK(length(display_name) BETWEEN 2 AND 80),
  phone TEXT,
  avatar_key TEXT,
  home_town TEXT NOT NULL DEFAULT 'Mbarara',
  role TEXT NOT NULL DEFAULT 'buyer' CHECK(role IN ('buyer','seller','merchant','admin')),
  is_verified INTEGER NOT NULL DEFAULT 0 CHECK(is_verified IN (0,1)),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS categories (
  id TEXT PRIMARY KEY,
  parent_id TEXT REFERENCES categories(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  icon TEXT,
  is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0,1)),
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS listings (
  id TEXT PRIMARY KEY,
  seller_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
  category_id TEXT NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
  title TEXT NOT NULL CHECK(length(title) BETWEEN 5 AND 120),
  slug TEXT NOT NULL UNIQUE,
  description TEXT NOT NULL CHECK(length(description) BETWEEN 20 AND 10000),
  price_ugx INTEGER NOT NULL CHECK(price_ugx>=0),
  negotiable INTEGER NOT NULL DEFAULT 0 CHECK(negotiable IN (0,1)),
  condition TEXT NOT NULL DEFAULT 'used' CHECK(condition IN ('new','used','refurbished')),
  transaction_mode TEXT NOT NULL DEFAULT 'classified' CHECK(transaction_mode IN ('classified','checkout')),
  status TEXT NOT NULL DEFAULT 'pending_review' CHECK(status IN ('draft','pending_review','published','rejected','sold','archived')),
  town TEXT NOT NULL DEFAULT 'Mbarara',
  area TEXT,
  latitude REAL,
  longitude REAL,
  stock_quantity INTEGER NOT NULL DEFAULT 1 CHECK(stock_quantity>=0),
  view_count INTEGER NOT NULL DEFAULT 0 CHECK(view_count>=0),
  published_at TEXT,
  expires_at TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  CHECK((latitude IS NULL AND longitude IS NULL) OR (latitude IS NOT NULL AND longitude IS NOT NULL))
);

CREATE INDEX IF NOT EXISTS listings_discovery_idx ON listings(status,town,category_id,published_at DESC);
CREATE INDEX IF NOT EXISTS listings_price_idx ON listings(price_ugx) WHERE status='published';
CREATE INDEX IF NOT EXISTS listings_seller_idx ON listings(seller_id,created_at DESC);

CREATE TABLE IF NOT EXISTS listing_images (
  id TEXT PRIMARY KEY,
  listing_id TEXT NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
  r2_key TEXT NOT NULL,
  alt_text TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  UNIQUE(listing_id,r2_key)
);

CREATE TABLE IF NOT EXISTS saved_listings (
  user_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  listing_id TEXT NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
  created_at TEXT NOT NULL,
  PRIMARY KEY(user_id,listing_id)
);

CREATE TABLE IF NOT EXISTS conversations (
  id TEXT PRIMARY KEY,
  listing_id TEXT NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
  buyer_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  seller_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  UNIQUE(listing_id,buyer_id,seller_id),
  CHECK(buyer_id<>seller_id)
);

CREATE TABLE IF NOT EXISTS messages (
  id TEXT PRIMARY KEY,
  conversation_id TEXT NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  body TEXT NOT NULL CHECK(length(body) BETWEEN 1 AND 4000),
  read_at TEXT,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS orders (
  id TEXT PRIMARY KEY,
  order_number TEXT NOT NULL UNIQUE,
  buyer_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
  seller_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
  status TEXT NOT NULL DEFAULT 'pending_seller' CHECK(status IN ('pending_seller','accepted','ready_for_collection','out_for_delivery','completed','cancelled','disputed')),
  payment_method TEXT NOT NULL DEFAULT 'cash_on_collection' CHECK(payment_method IN ('cash_on_collection','mobile_money','card','bank_transfer')),
  subtotal_ugx INTEGER NOT NULL CHECK(subtotal_ugx>=0),
  delivery_fee_ugx INTEGER NOT NULL DEFAULT 0 CHECK(delivery_fee_ugx>=0),
  platform_fee_ugx INTEGER NOT NULL DEFAULT 0 CHECK(platform_fee_ugx>=0),
  total_ugx INTEGER GENERATED ALWAYS AS (subtotal_ugx+delivery_fee_ugx+platform_fee_ugx) STORED,
  delivery_mode TEXT NOT NULL DEFAULT 'collection' CHECK(delivery_mode IN ('collection','local_delivery','courier')),
  delivery_notes TEXT,
  buyer_note TEXT,
  accepted_at TEXT,
  completed_at TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  CHECK(buyer_id<>seller_id)
);

CREATE TABLE IF NOT EXISTS order_items (
  id TEXT PRIMARY KEY,
  order_id TEXT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  listing_id TEXT NOT NULL REFERENCES listings(id) ON DELETE RESTRICT,
  title_snapshot TEXT NOT NULL,
  unit_price_ugx INTEGER NOT NULL CHECK(unit_price_ugx>=0),
  quantity INTEGER NOT NULL CHECK(quantity>0),
  line_total_ugx INTEGER GENERATED ALWAYS AS (unit_price_ugx*quantity) STORED
);

CREATE TABLE IF NOT EXISTS payments (
  id TEXT PRIMARY KEY,
  order_id TEXT NOT NULL REFERENCES orders(id) ON DELETE RESTRICT,
  provider TEXT NOT NULL,
  provider_reference TEXT,
  method TEXT NOT NULL CHECK(method IN ('cash_on_collection','mobile_money','card','bank_transfer')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','initiated','succeeded','failed','cancelled','refunded')),
  amount_ugx INTEGER NOT NULL CHECK(amount_ugx>=0),
  currency TEXT NOT NULL DEFAULT 'UGX' CHECK(currency='UGX'),
  idempotency_key TEXT NOT NULL UNIQUE,
  initiated_at TEXT,
  settled_at TEXT,
  provider_payload_json TEXT NOT NULL DEFAULT '{}' CHECK(json_valid(provider_payload_json)),
  created_at TEXT NOT NULL,
  UNIQUE(provider,provider_reference)
);

CREATE TABLE IF NOT EXISTS reports (
  id TEXT PRIMARY KEY,
  reporter_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  listing_id TEXT REFERENCES listings(id) ON DELETE SET NULL,
  reported_user_id TEXT REFERENCES profiles(id) ON DELETE SET NULL,
  reason TEXT NOT NULL CHECK(length(reason) BETWEEN 3 AND 100),
  details TEXT CHECK(details IS NULL OR length(details)<=4000),
  status TEXT NOT NULL DEFAULT 'open' CHECK(status IN ('open','reviewing','actioned','dismissed')),
  resolution_note TEXT,
  created_at TEXT NOT NULL,
  resolved_at TEXT
);

CREATE TABLE IF NOT EXISTS audit_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  actor_id TEXT REFERENCES profiles(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id TEXT,
  metadata_json TEXT NOT NULL DEFAULT '{}' CHECK(json_valid(metadata_json)),
  created_at TEXT NOT NULL
);

CREATE VIRTUAL TABLE IF NOT EXISTS listings_fts USING fts5(
  listing_id UNINDEXED,title,description,town,content='',
  tokenize='unicode61'
);

CREATE INDEX IF NOT EXISTS messages_conversation_created_idx ON messages(conversation_id,created_at);
CREATE INDEX IF NOT EXISTS orders_buyer_created_idx ON orders(buyer_id,created_at DESC);
CREATE INDEX IF NOT EXISTS orders_seller_created_idx ON orders(seller_id,created_at DESC);
CREATE INDEX IF NOT EXISTS payments_order_idx ON payments(order_id,created_at DESC);
CREATE INDEX IF NOT EXISTS reports_status_created_idx ON reports(status,created_at DESC);
