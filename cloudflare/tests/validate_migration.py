"""SQLite contract tests for the initial GUZA GURA D1 migration."""
from pathlib import Path
import sqlite3

DB = Path(__file__).resolve().parents[1] / "migrations" / "0001_initial.sql"


def expect_integrity_error(connection, statement, params=()):
    try:
        connection.execute(statement, params)
    except sqlite3.IntegrityError:
        return
    raise AssertionError(f"Expected integrity failure: {statement}")


def main():
    db = sqlite3.connect(":memory:")
    db.execute("PRAGMA foreign_keys=ON")
    db.executescript(DB.read_text(encoding="utf-8"))

    tables = {row[0] for row in db.execute(
        "SELECT name FROM sqlite_master WHERE type='table'"
    )}
    required = {
        "profiles", "categories", "listings", "listing_images", "saved_listings",
        "conversations", "messages", "orders", "order_items", "payments",
        "reports", "audit_events", "listings_fts",
    }
    assert required <= tables, required - tables

    db.execute(
        """INSERT INTO profiles(id,display_name,created_at,updated_at)
           VALUES('seller-1','Seller One','now','now')"""
    )
    db.execute(
        """INSERT INTO profiles(id,display_name,created_at,updated_at)
           VALUES('buyer-1','Buyer One','now','now')"""
    )
    db.execute(
        """INSERT INTO categories(id,name,slug,created_at)
           VALUES('cat-1','Phones','phones','now')"""
    )
    db.execute(
        """INSERT INTO listings(id,seller_id,category_id,title,slug,description,price_ugx,
           created_at,updated_at) VALUES('l1','seller-1','cat-1','Phone A','phone-a',
           'A tested second-hand phone for sale',120000,'now','now')"""
    )
    db.execute(
        """INSERT INTO orders(id,order_number,buyer_id,seller_id,subtotal_ugx,
           delivery_fee_ugx,platform_fee_ugx,created_at,updated_at)
           VALUES('ord-1','GG-123','buyer-1','seller-1',120000,5000,2000,'now','now')"""
    )
    total = db.execute("SELECT total_ugx FROM orders WHERE id='ord-1'").fetchone()[0]
    assert total == 127000, total
    db.execute(
        """INSERT INTO order_items(id,order_id,listing_id,title_snapshot,unit_price_ugx,quantity)
           VALUES('oi-1','ord-1','l1','Phone A',120000,2)"""
    )
    line_total = db.execute("SELECT line_total_ugx FROM order_items WHERE id='oi-1'").fetchone()[0]
    assert line_total == 240000, line_total
    expect_integrity_error(
        db,
        """INSERT INTO listings(id,seller_id,category_id,title,slug,description,price_ugx,
           created_at,updated_at) VALUES('bad','seller-1','cat-1','Bad','bad','Short',-1,'now','now')""",
    )
    assert db.execute("SELECT count(*) FROM listings_fts WHERE listings_fts MATCH 'Phone'").fetchone()[0] == 1
    db.execute("UPDATE listings SET title='Updated handset' WHERE id='l1'")
    assert db.execute("SELECT count(*) FROM listings_fts WHERE listings_fts MATCH 'Updated'").fetchone()[0] == 1
    assert db.execute("SELECT count(*) FROM listings_fts WHERE listings_fts MATCH '\"Phone A\"'").fetchone()[0] == 0
    db.execute("DELETE FROM listings WHERE id='l1'")
    assert db.execute("SELECT count(*) FROM listings_fts WHERE listings_fts MATCH 'Updated'").fetchone()[0] == 0
    assert db.execute("PRAGMA foreign_key_check").fetchall() == []
    print("GUZA GURA D1 migration: schema, constraints, generated totals, FTS5 and relationships passed")


if __name__ == "__main__":
    main()
