import { db } from '../config/db';

export async function saveGithubResults(results: { url: string; status: number }[]) {
  if (!results.length) return;
  const values = results.map(r => `('${r.url.replace(/'/g, "''")}', ${r.status})`).join(',');
  await db.query(`
    INSERT INTO github_results (url, status)
    VALUES ${values}
    ON CONFLICT (url) DO NOTHING;
  `);
}

export async function getGithubResults(page = 1, limit = 20) {
  const offset = (page - 1) * limit;
  const { rows } = await db.query(
    'SELECT * FROM github_results ORDER BY created_at DESC LIMIT $1 OFFSET $2',
    [limit, offset]
  );
  return rows;
}

export async function seedGithubResults(seedData: { url: string; status: number }[]) {
  await saveGithubResults(seedData);
}
