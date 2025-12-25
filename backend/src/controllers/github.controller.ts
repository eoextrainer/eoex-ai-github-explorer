import { Request, Response, NextFunction } from 'express';
import { githubBatchSearchService } from '../services/githubBatchSearch.service';
import { saveGithubResults, getGithubResults, seedGithubResults } from '../services/githubDb.service';

export async function batchGithubSearch(req: Request, res: Response, next: NextFunction) {
  try {
    const { queries } = req.body; // expects: { queries: string[] }
    if (!Array.isArray(queries) || queries.length === 0) {
      return res.status(400).json({ error: 'queries must be a non-empty array' });
    }
    const results = await githubBatchSearchService(queries);
    await saveGithubResults(results);
    res.json({ results });
  } catch (err) {
    next(err);
  }
}

export async function getGithubResultsPaginated(req: Request, res: Response, next: NextFunction) {
  try {
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 20;
    const results = await getGithubResults(page, limit);
    res.json({ results, page, limit });
  } catch (err) {
    next(err);
  }
}

export async function seedGithub(req: Request, res: Response, next: NextFunction) {
  try {
    const { seedData } = req.body; // expects: { seedData: [{ url, status }] }
    if (!Array.isArray(seedData) || seedData.length === 0) {
      return res.status(400).json({ error: 'seedData must be a non-empty array' });
    }
    await seedGithubResults(seedData);
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
}
