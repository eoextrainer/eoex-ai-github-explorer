import { Pool } from 'pg';
import { config } from './config';

export const db = new Pool({
  connectionString: config.DB_URL,
});

// Helper for DB migrations/seeding
export async function runMigrations() {
  // Create table if not exists
  await db.query(`
    CREATE TABLE IF NOT EXISTS github_results (
      id SERIAL PRIMARY KEY,
      url TEXT NOT NULL,
      status INTEGER NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  `);
}
