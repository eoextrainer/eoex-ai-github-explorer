"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.db = void 0;
exports.runMigrations = runMigrations;
const pg_1 = require("pg");
const config_1 = require("./config");
exports.db = new pg_1.Pool({
    connectionString: config_1.config.DB_URL,
});
// Helper for DB migrations/seeding
async function runMigrations() {
    // Create table if not exists
    await exports.db.query(`
    CREATE TABLE IF NOT EXISTS github_results (
      id SERIAL PRIMARY KEY,
      url TEXT NOT NULL,
      status INTEGER NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  `);
}
