#!/bin/bash

# GitHub Repository Discovery Script for EOEX Explorer
# This script discovers and imports GitHub repositories

set -e

API_URL="http://localhost:3001/api/github/batch-search"
LOG_FILE="scripts/github_discovery.log"

echo "Starting GitHub repository discovery..."


# Use queries array as expected by batch-search endpoint
response=$(curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d '{"queries": ["web3", "blockchain", "defi", "dao", "nft"]}')

if echo "$response" | grep -q '"results"'; then
  echo "Batch search completed. Results saved to database."
  echo "$(date): Batch search success" >> "$LOG_FILE"
else
  echo "Error in batch search: $response"
  echo "$(date): ERROR: $response" >> "$LOG_FILE"
  exit 1
fi
