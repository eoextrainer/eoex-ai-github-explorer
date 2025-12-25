"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.saveGithubResults = saveGithubResults;
exports.getGithubResults = getGithubResults;
exports.seedGithubResults = seedGithubResults;
const db_1 = require("../config/db");
async function saveGithubResults(results) {
    if (!results.length)
        return;
    const values = results.map(r => `('${r.url.replace(/'/g, "''")}', ${r.status})`).join(',');
    await db_1.db.query(`
    INSERT INTO github_results (url, status)
    VALUES ${values}
    ON CONFLICT (url) DO NOTHING;
  `);
}
async function getGithubResults(page = 1, limit = 20) {
    const offset = (page - 1) * limit;
    const { rows } = await db_1.db.query('SELECT * FROM github_results ORDER BY created_at DESC LIMIT $1 OFFSET $2', [limit, offset]);
    return rows;
}
async function seedGithubResults(seedData) {
    await saveGithubResults(seedData);
}
