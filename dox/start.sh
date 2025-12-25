#!/bin/bash

# Ensure OPENAI_API_KEY is set
if [ -z "$OPENAI_API_KEY" ]; then
  echo "OPENAI_API_KEY is not set. Please enter your OpenAI API key:"
  read -s OPENAI_API_KEY
  export OPENAI_API_KEY
fi

echo "Using OPENAI_API_KEY: ${OPENAI_API_KEY:0:8}..."

docker compose down

docker compose up -d --build
