"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.githubBatchSearchService = githubBatchSearchService;
const node_fetch_1 = __importDefault(require("node-fetch"));
const config_1 = require("../config/config");
async function githubBatchSearchService(queries) {
    // For each query, search GitHub and validate URLs
    const results = [];
    for (const query of queries) {
        // Search GitHub repositories (simple example, can be improved)
        const searchUrl = `https://api.github.com/search/repositories?q=${encodeURIComponent(query)}`;
        // Only include defined headers
        const headers = { 'Accept': 'application/vnd.github.v3+json' };
        if (config_1.config.GITHUB_TOKEN)
            headers['Authorization'] = `token ${config_1.config.GITHUB_TOKEN}`;
        const resp = await (0, node_fetch_1.default)(searchUrl, { headers });
        if (!resp.ok)
            continue;
        const data = await resp.json();
        for (const repo of data.items || []) {
            // Validate repo URL with HTTP 200 check
            const repoUrl = repo.html_url;
            try {
                const check = await (0, node_fetch_1.default)(repoUrl, { method: 'HEAD' });
                if (check.status === 200) {
                    results.push({ url: repoUrl, status: 200 });
                }
            }
            catch (e) {
                // skip
            }
        }
    }
    return results;
}
