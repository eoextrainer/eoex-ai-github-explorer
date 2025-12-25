#!/bin/bash

# GitHub Repository Discovery Script for EOEX Explorer
# This script discovers and imports GitHub repositories

set -e

API_URL="http://localhost:8000/api/github/discover"
LOG_FILE="scripts/github_discovery.log"

echo "Starting GitHub repository discovery..."

response=$(curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d "{\"keywords\": [\"web3\", \"blockchain\", \"defi\", \"dao\", \"nft\"]}")

if echo "$response" | grep -q "discovery initiated"; then
  echo "Discovery initiated successfully. Check backend logs for details."
  echo "$(date): Discovery initiated" >> "$LOG_FILE"
else
  echo "Error initiating discovery: $response"
  echo "$(date): ERROR: $response" >> "$LOG_FILE"
  exit 1
fi
