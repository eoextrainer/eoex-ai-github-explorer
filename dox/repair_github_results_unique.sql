-- Migration: Add UNIQUE constraint to github_results.url
ALTER TABLE github_results ADD CONSTRAINT github_results_url_unique UNIQUE (url);