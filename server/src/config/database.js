const Database = require('better-sqlite3')
const fs = require('fs')
const path = require('path')

const databasePath = path.join(__dirname, '../../database/pharmacy.db')
const schemaPath = path.join(__dirname, '../../database/schema.sql')

const db = new Database(databasePath)

// SQLite configuration
db.pragma('foreign_keys = ON')
db.pragma('journal_mode = WAL')

// Initialize database schema
const schema = fs.readFileSync(schemaPath, 'utf8')

db.exec(schema)

console.log(`SQLite database connected: ${databasePath}`)

module.exports = db