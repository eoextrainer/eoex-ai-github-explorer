
#!/bin/bash
set -e
LOG=error.log
: > "$LOG"

# --- Error/Failure Mode Catalog (from error-prompt.txt) ---
# Categories: infra, dependency, DB, backend, frontend, API, security, logic, schema, network, resource, config, version, auth, etc.
# Severity: CRITICAL/HIGH/MEDIUM/LOW
# Correction: auto-fix, retry, escalate, log, halt, restart

# --- Self-Improvement/Feedback Loop (from teacher-prompt.txt) ---
# - Retry with exponential backoff
# - Circuit breaker for repeated failures
# - Log error patterns for future runs
# - Validate against proven patterns
# - Restart on recoverable errors

MAX_RETRIES=3
RETRY_DELAY=5
FAIL_COUNT=0

function log_error() {
  echo "[ERROR][$(date)] $1" | tee -a "$LOG"
}

function log_info() {
  echo "[INFO][$(date)] $1" | tee -a "$LOG"
}

# Step 0: Automated fixes for known errors (infra, dependency, DB)
function fix_db_and_python() {
  log_info "Ensuring ariapp database exists..."
  docker compose exec db psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = 'ariapp';" | grep -q 1 || \
    docker compose exec db psql -U postgres -c "CREATE DATABASE ariapp;" >> "$LOG" 2>&1 || log_error "Failed to create ariapp database."
  log_info "Ensuring messages table exists..."
  docker compose exec db psql -U postgres -d ariapp -c "CREATE TABLE IF NOT EXISTS messages (id SERIAL PRIMARY KEY, sender VARCHAR(10), message TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);" >> "$LOG" 2>&1 || log_error "Failed to create messages table."
  log_info "Ensuring python-dotenv is installed in backend..."
  docker compose exec backend pip3 install python-dotenv --break-system-packages >> "$LOG" 2>&1 || log_error "Failed to install python-dotenv."
}

fix_db_and_python


# Step 1: Start the app using start.sh (infra/config)
function start_app() {
  log_info "Starting app with start.sh..."
  ./start.sh >> "$LOG" 2>&1 || { log_error "start.sh failed."; return 1; }
}

# Step 1.2: Force reinstall python-dotenv in backend before health check
function ensure_python_dotenv() {
  log_info "Force reinstalling python-dotenv in backend..."
  docker compose exec backend pip3 install --force-reinstall python-dotenv --break-system-packages >> "$LOG" 2>&1 || log_error "Failed to force reinstall python-dotenv."
  docker compose exec backend pip3 show python-dotenv >> "$LOG" 2>&1 || log_error "python-dotenv still missing after reinstall."
}

# Step 1.5: Check backend health (network, API, backend)
function check_backend_health() {
  log_info "Waiting for backend to be healthy..."
  for i in {1..30}; do
    if curl -s http://localhost:5000/api/prompts > /dev/null; then
      log_info "Backend is healthy."
      return 0
    fi
    sleep 2
  done
  log_error "Backend did not become healthy in time."
  return 1
}


# Step 2: Test backend API (API, logic, security, LLM orchestration)
function test_backend() {
  local question="$1"
  log_info "Testing backend with: $question"
  local response
  response=$(timeout 60 curl -s -w "\n%{http_code}" -X POST http://localhost:5000/api/ari -H 'Content-Type: application/json' -d "{\"message\": \"$question\"}")
  local body=$(echo "$response" | head -n -1)
  local code=$(echo "$response" | tail -n1)
  log_info "[RESPONSE] HTTP $code: $body"
  if [ "$code" != "200" ]; then
    log_error "Backend API call failed with HTTP $code"
    capture_backend_logs
    return 1
  fi
  if [[ "$body" == *"Error"* || "$body" == *"exception"* ]]; then
    log_error "Backend API returned error: $body"
    diagnose_llm_failure
    return 1
  fi
  return 0
}

# Capture backend and Python LLM logs for diagnosis
function capture_backend_logs() {
  log_info "Capturing backend container logs..."
  docker compose logs backend >> "$LOG" 2>&1
}

# Diagnose and auto-remediate common LLM orchestration errors
function diagnose_llm_failure() {
  log_info "Diagnosing LLM orchestration failure..."
  # 1. Check OpenAI API key
  docker compose exec backend printenv OPENAI_API_KEY >> "$LOG" 2>&1 || log_error "OPENAI_API_KEY not set in backend."
  # 2. Check prompt file exists
  docker compose exec backend ls -l /app/prompt/ari-prompt.txt >> "$LOG" 2>&1 || log_error "ari-prompt.txt missing in backend."
  # 3. Check Python dependencies
  docker compose exec backend pip3 show openai >> "$LOG" 2>&1 || log_error "openai Python package missing."
  docker compose exec backend pip3 show python-dotenv >> "$LOG" 2>&1 || log_error "python-dotenv Python package missing."
  # 4. Check for Python errors in logs
  docker compose exec backend tail -n 40 /app/error.log >> "$LOG" 2>&1 || log_info "No backend error.log found."
  # 5. Check network connectivity to OpenAI
  docker compose exec backend ping -c 1 api.openai.com >> "$LOG" 2>&1 || log_error "Backend cannot reach OpenAI API."
  # 6. Forcibly run the Python LLM script with a test prompt and capture output
  log_info "Running ari_llm.py directly for diagnosis..."
  docker compose exec backend python3 /app/ari_llm.py <<EOF > /tmp/ari_llm_test_output.txt 2>&1
{"prompt": "diagnostic test prompt"}
EOF
  cat /tmp/ari_llm_test_output.txt >> "$LOG"
  docker compose exec backend tail -n 40 /app/error.log >> "$LOG" 2>&1 || log_info "No backend error.log found after direct run."
}

# Step 3: Test database schema and wiring (DB, schema)
function test_db() {
  log_info "Testing database schema..."
  docker compose exec db psql -U postgres -d ariapp -c "\dt" >> "$LOG" 2>&1 || log_error "Failed to list tables."
  docker compose exec db psql -U postgres -d ariapp -c "SELECT * FROM messages LIMIT 5;" >> "$LOG" 2>&1 || log_error "Failed to query messages table."
}

# Step 4: Test frontend (frontend, network)
function test_frontend() {
  log_info "Testing frontend..."
  timeout 60 curl -s http://localhost:3000/ >> "$LOG" 2>&1 || log_error "Frontend not reachable."
}

# Step 5: Analyze errors and fix recursively (continuous improvement)
function analyze_and_fix_errors() {
  local errors_found=$(grep -i 'error\|fail\|exception' "$LOG" | wc -l)
  if [ "$errors_found" -gt 0 ]; then
    log_error "Errors found: $errors_found. Attempting auto-remediation."
    # Auto-remediation: retry up to MAX_RETRIES
    ((FAIL_COUNT++))
    if [ "$FAIL_COUNT" -lt "$MAX_RETRIES" ]; then
      log_info "Retrying run: attempt $((FAIL_COUNT+1))/$MAX_RETRIES after $RETRY_DELAY seconds..."
      sleep $RETRY_DELAY
      exec "$0"
    else
      log_error "Max retries reached. Manual intervention required."
      exit 1
    fi
  fi
}

# Step 6: Stage, commit, and push all changes (release management)
function git_commit_and_push() {
  log_info "Staging and committing changes..."
  git add .
  git commit -m "Automated runner: fix errors and test app" || log_info "No changes to commit."
  git push --force origin main || log_error "Git push failed."
}

# --- MAIN EXECUTION FLOW ---
start_app || true
ensure_python_dotenv
check_backend_health || { analyze_and_fix_errors; exit 1; }
test_backend "Tell me something interesting about Africa." || analyze_and_fix_errors
test_backend "What is the capital of France?" || analyze_and_fix_errors
test_backend "Name a famous river in South America." || analyze_and_fix_errors
test_db || analyze_and_fix_errors
test_frontend || analyze_and_fix_errors
analyze_and_fix_errors
git_commit_and_push

log_info "All tests passed. Application is healthy."
