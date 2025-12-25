import fetch from 'node-fetch';
import { config } from '../config/config';

interface GithubResult {
  url: string;
  status: number;
}

export async function githubBatchSearchService(queries: string[]): Promise<GithubResult[]> {
  // For each query, search GitHub and validate URLs
  const results: GithubResult[] = [];
  for (const query of queries) {
    // Search GitHub repositories (simple example, can be improved)
    const searchUrl = `https://api.github.com/search/repositories?q=${encodeURIComponent(query)}`;
    // Only include defined headers
    const headers: Record<string, string> = { 'Accept': 'application/vnd.github.v3+json' };
    if (config.GITHUB_TOKEN) headers['Authorization'] = `token ${config.GITHUB_TOKEN}`;
    const resp = await fetch(searchUrl, { headers });
    if (!resp.ok) continue;
    const data = await resp.json();
    for (const repo of data.items || []) {
      // Validate repo URL with HTTP 200 check
      const repoUrl = repo.html_url;
      try {
        const check = await fetch(repoUrl, { method: 'HEAD' });
        if (check.status === 200) {
          results.push({ url: repoUrl, status: 200 });
        }
      } catch (e) {
        // skip
      }
    }
  }
  return results;
}
