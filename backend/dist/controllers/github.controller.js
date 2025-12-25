"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.batchGithubSearch = batchGithubSearch;
exports.getGithubResultsPaginated = getGithubResultsPaginated;
exports.seedGithub = seedGithub;
const githubBatchSearch_service_1 = require("../services/githubBatchSearch.service");
const githubDb_service_1 = require("../services/githubDb.service");
async function batchGithubSearch(req, res, next) {
    try {
        const { queries } = req.body; // expects: { queries: string[] }
        if (!Array.isArray(queries) || queries.length === 0) {
            return res.status(400).json({ error: 'queries must be a non-empty array' });
        }
        const results = await (0, githubBatchSearch_service_1.githubBatchSearchService)(queries);
        await (0, githubDb_service_1.saveGithubResults)(results);
        res.json({ results });
    }
    catch (err) {
        next(err);
    }
}
async function getGithubResultsPaginated(req, res, next) {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const results = await (0, githubDb_service_1.getGithubResults)(page, limit);
        res.json({ results, page, limit });
    }
    catch (err) {
        next(err);
    }
}
async function seedGithub(req, res, next) {
    try {
        const { seedData } = req.body; // expects: { seedData: [{ url, status }] }
        if (!Array.isArray(seedData) || seedData.length === 0) {
            return res.status(400).json({ error: 'seedData must be a non-empty array' });
        }
        await (0, githubDb_service_1.seedGithubResults)(seedData);
        res.json({ success: true });
    }
    catch (err) {
        next(err);
    }
}
