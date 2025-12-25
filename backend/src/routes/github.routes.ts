import { Router } from 'express';
import { batchGithubSearch, getGithubResultsPaginated, seedGithub } from '../controllers/github.controller';

const router = Router();


// POST /api/github/batch-search
router.post('/batch-search', batchGithubSearch);
// POST /api/github/search (alias for batch-search)
router.post('/search', batchGithubSearch);

// GET /api/github/results?page=1&limit=20
router.get('/results', getGithubResultsPaginated);

// POST /api/github/seed
router.post('/seed', seedGithub);

export default router;
