PRAGMA foreign_keys = ON;

-- ============================================================
-- USERS
-- ============================================================

CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT NOT NULL COLLATE NOCASE UNIQUE,
    password_hash TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- ============================================================
-- MEDICINES
-- ============================================================

CREATE TABLE IF NOT EXISTS medicines (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL COLLATE NOCASE UNIQUE,
    description TEXT,
    reorder_threshold INTEGER NOT NULL CHECK (reorder_threshold >= 0),
    reorder_alert_active INTEGER NOT NULL DEFAULT 0
        CHECK (reorder_alert_active IN (0, 1)),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- ============================================================
-- BATCHES
-- ============================================================

CREATE TABLE IF NOT EXISTS batches (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    medicine_id INTEGER NOT NULL,
    batch_number TEXT NOT NULL COLLATE NOCASE,
    initial_quantity INTEGER NOT NULL CHECK (initial_quantity > 0),
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    expiry_date TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'ACTIVE'
        CHECK (status IN ('ACTIVE', 'QUARANTINED')),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (medicine_id)
        REFERENCES medicines(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    UNIQUE (medicine_id, batch_number)
);


-- ============================================================
-- DISPENSATIONS
-- ============================================================

CREATE TABLE IF NOT EXISTS dispensations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    medicine_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    FOREIGN KEY (medicine_id)
        REFERENCES medicines(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);


-- ============================================================
-- DISPENSATION ITEMS
-- ============================================================

CREATE TABLE IF NOT EXISTS dispensation_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    dispensation_id INTEGER NOT NULL,
    batch_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),

    FOREIGN KEY (dispensation_id)
        REFERENCES dispensations(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    FOREIGN KEY (batch_id)
        REFERENCES batches(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);


-- ============================================================
-- IMPORT BATCHES
-- ============================================================

CREATE TABLE IF NOT EXISTS import_batches (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- ============================================================
-- IMPORT ROWS
-- ============================================================

CREATE TABLE IF NOT EXISTS import_rows (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    import_batch_id INTEGER NOT NULL,
    row_number INTEGER NOT NULL,

    raw_medicine_name TEXT,
    raw_batch_number TEXT,
    raw_quantity TEXT,
    raw_expiry_date TEXT,

    normalized_medicine_name TEXT,
    normalized_batch_number TEXT,
    normalized_quantity INTEGER,
    normalized_expiry_date TEXT,

    status TEXT NOT NULL
        CHECK (status IN ('IMPORTED', 'DEDUPED', 'REJECTED')),

    reason TEXT,

    FOREIGN KEY (import_batch_id)
        REFERENCES import_batches(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);


-- ============================================================
-- NOTIFICATION OUTBOX
-- ============================================================

CREATE TABLE IF NOT EXISTS outbox (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_type TEXT NOT NULL,
    medicine_id INTEGER NOT NULL,
    payload TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    processed_at TEXT,

    FOREIGN KEY (medicine_id)
        REFERENCES medicines(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);


-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_batches_medicine
    ON batches(medicine_id);

CREATE INDEX IF NOT EXISTS idx_batches_medicine_expiry
    ON batches(medicine_id, expiry_date);

CREATE INDEX IF NOT EXISTS idx_batches_medicine_status_expiry
    ON batches(medicine_id, status, expiry_date);

CREATE INDEX IF NOT EXISTS idx_batches_expiry
    ON batches(expiry_date);

CREATE INDEX IF NOT EXISTS idx_batches_status
    ON batches(status);

CREATE INDEX IF NOT EXISTS idx_dispensations_medicine
    ON dispensations(medicine_id);

CREATE INDEX IF NOT EXISTS idx_dispensation_items_dispensation
    ON dispensation_items(dispensation_id);

CREATE INDEX IF NOT EXISTS idx_dispensation_items_batch
    ON dispensation_items(batch_id);

CREATE INDEX IF NOT EXISTS idx_import_rows_import_batch
    ON import_rows(import_batch_id);

CREATE INDEX IF NOT EXISTS idx_outbox_medicine
    ON outbox(medicine_id);

CREATE INDEX IF NOT EXISTS idx_outbox_event_type
    ON outbox(event_type);

CREATE INDEX IF NOT EXISTS idx_outbox_created_at
    ON outbox(created_at);