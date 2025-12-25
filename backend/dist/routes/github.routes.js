"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const github_controller_1 = require("../controllers/github.controller");
const router = (0, express_1.Router)();
// POST /api/github/batch-search
router.post('/batch-search', github_controller_1.batchGithubSearch);
// POST /api/github/search (alias for batch-search)
router.post('/search', github_controller_1.batchGithubSearch);
// GET /api/github/results?page=1&limit=20
router.get('/results', github_controller_1.getGithubResultsPaginated);
// POST /api/github/seed
router.post('/seed', github_controller_1.seedGithub);
exports.default = router;
