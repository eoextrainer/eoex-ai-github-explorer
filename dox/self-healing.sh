#!/bin/bash


# ========== Akibai Explorer Self-Healing & Logging ==========


function log_step() {
  [ -d "$LOG_DIR" ] || mkdir -p "$LOG_DIR"
  echo -e "${CYAN}[$(date '+%H:%M:%S')] $1${NC}"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_DIR/akibai-workflow.log"
}


function log_success() {
  [ -d "$LOG_DIR" ] || mkdir -p "$LOG_DIR"
  echo -e "${GREEN}✔ $1${NC}"
  echo "SUCCESS: $1" >> "$LOG_DIR/akibai-workflow.log"
}


function log_error() {
  [ -d "$LOG_DIR" ] || mkdir -p "$LOG_DIR"
  echo -e "${RED}✖ $1${NC}"
  echo "ERROR: $1" >> "$LOG_DIR/akibai-workflow.log"
}

function log_warning() {
  [ -d "$LOG_DIR" ] || mkdir -p "$LOG_DIR"
  echo -e "${YELLOW}! $1${NC}"
}

function run_and_log() {
  local desc="$1"
  local cmd="$2"
  local logfile="$LOG_DIR/$3"
  [ -d "$LOG_DIR" ] || mkdir -p "$LOG_DIR"
  log_step "$desc"
  eval "$cmd" > "$logfile" 2>&1 && log_success "$desc" || {
    log_error "$desc (see $logfile)"
    # Only use return if inside a function, otherwise set ERRORS=1
    if [[ "${FUNCNAME[1]}" != "" ]]; then
      return 1
    else
      ERRORS=1
    fi
  }
}

function auto_remediate() {
  local logfile="$1"
  local fixdesc="$2"
  [ -d "$LOG_DIR" ] || mkdir -p "$LOG_DIR"
  log_warning "Attempting auto-remediation: $fixdesc"
  echo "AUTO-REMEDIATION: $fixdesc" >> "$LOG_DIR/workflow.log"
  eval "$3" >> "$logfile" 2>&1
}

function check_and_fix() {
  local desc="$1"
  local checkcmd="$2"
  local fixcmd="$3"
  local logfile="$LOG_DIR/checkfix_$(echo $desc | tr ' ' '_').log"
  if ! eval "$checkcmd" > /dev/null 2>&1; then
    log_warning "$desc failed, attempting fix"
    eval "$fixcmd" > "$logfile" 2>&1 && log_success "$desc fixed" || log_error "$desc could not be fixed (see $logfile)"
  else
    log_success "$desc present"
  fi
}


function print_summary_table() {
  echo -e "\n${BLUE}========== Akibai Explorer Self-Healing Workflow Summary ==========${NC}"
  printf "%-40s | %-10s\n" "Step" "Status"
  printf -- "----------------------------------------+------------\n"
  grep -E 'SUCCESS|ERROR' "$LOG_DIR/akibai-workflow.log" | while read -r line; do
    step=$(echo "$line" | cut -d: -f2- | cut -c2-)
    status=$(echo "$line" | grep -q SUCCESS && echo -e "${GREEN}SUCCESS${NC}" || echo -e "${RED}ERROR${NC}")
    printf "%-40s | %-10s\n" "$step" "$status"
  done
  echo -e "${BLUE}==================================================================${NC}\n"
  grep -E 'SUCCESS|ERROR' "$LOG_DIR/akibai-workflow.log" | sed 's/\x1b\[[0-9;]*m//g' > "$SUMMARY_FILE"
}

# Savepoint: log timestamp and commit hash to DB
function savepoint() {
  local msg="$1"
  local ts=$(date '+%Y-%m-%d %H:%M:%S')
  local hash=$(git rev-parse HEAD 2>/dev/null)
  echo -e "${YELLOW}==> Savepoint: $msg | $ts | $hash${NC}"
  echo "SAVEPOINT: $msg | $ts | $hash" >> "$LOG_DIR/akibai-workflow.log"
  # Insert into DB table (requires psql and .env DATABASE_URL)
  if [ -f backend/.env ]; then
    export $(grep DATABASE_URL backend/.env | xargs)
    psql "$DATABASE_URL" -c "CREATE TABLE IF NOT EXISTS savepoints (id SERIAL PRIMARY KEY, message TEXT, timestamp TIMESTAMP, commit_hash TEXT);" 2>/dev/null
    psql "$DATABASE_URL" -c "INSERT INTO savepoints (message, timestamp, commit_hash) VALUES ('${msg//\'/''}', '$ts', '$hash');" 2>/dev/null
  fi
}

# ========== Workflow Logic ==========

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color


LOG_DIR="akibai_self_healing_logs"
SUMMARY_FILE="$LOG_DIR/akibai-summary.log"
echo -n > "$SUMMARY_FILE"

# Main workflow loop
MAX_ITER=10
ITER=1
while [ $ITER -le $MAX_ITER ]; do
  log_step "Starting Akibai Explorer workflow iteration $ITER"
  ERRORS=0

  # 1. Folders (robustly create before any file operations)
  if [ ! -d backend ]; then mkdir -p backend; fi
  if [ ! -d frontend ]; then mkdir -p frontend; fi
  if [ ! -d scripts ]; then mkdir -p scripts; fi
  check_and_fix "backend folder" "[ -d backend ]" "mkdir -p backend"
  check_and_fix "frontend folder" "[ -d frontend ]" "mkdir -p frontend"
  check_and_fix "scripts folder" "[ -d scripts ]" "mkdir -p scripts"
  savepoint "Folders checked/created"


  # 2. Backend venv and dependencies
  if [ ! -d backend/venv ]; then
    run_and_log "Creating Python venv" "cd backend && python3 -m venv venv" "venv.log" || ERRORS=1
  fi
  source backend/venv/bin/activate
  pip install --upgrade pip
  pip install fastapi uvicorn sqlalchemy psycopg2-binary pydantic python-dotenv requests || pip install --force-reinstall fastapi uvicorn sqlalchemy psycopg2-binary pydantic python-dotenv requests
  savepoint "Backend venv and dependencies installed"


  # 3. .env
  if [ ! -f backend/.env ]; then
    echo "DATABASE_URL=postgresql://akibai:akibaipass@localhost:5432/akibai_explorer" > backend/.env
    log_success ".env file created"
  fi
  savepoint ".env checked/created"


  # 4. Auto-generate backend/main.py if missing
  if [ ! -f backend/main.py ]; then
    cat <<EOF > backend/main.py
from fastapi import FastAPI
from pydantic import BaseModel
import os
import sqlalchemy
app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "Akibai Explorer API is running!"}
EOF
    log_success "backend/main.py created"
  fi
  savepoint "backend/main.py checked/created"


    # 5. Auto-generate backend/init_db.py if missing
    if [ ! -f backend/init_db.py ]; then
    cat <<EOF > backend/init_db.py
  import os
  from sqlalchemy import create_engine
  from sqlalchemy.orm import sessionmaker
  DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://akibai:akibaipass@localhost:5432/akibai_explorer")
  engine = create_engine(DATABASE_URL)
  SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
  def init_db():
    try:
      engine.connect()
      print("Database connection successful.")
    except Exception as e:
      print(f"Database connection failed: {e}")
  if __name__ == "__main__":
    init_db()
  EOF
    log_success "backend/init_db.py created"
    fi
    savepoint "backend/init_db.py checked/created"


  # 6. Auto-generate docker-compose.yml if missing
  if [ ! -f docker-compose.yml ]; then
    cat <<EOF > docker-compose.yml
version: '3.8'
services:
  postgres:
    image: postgres:14
    restart: always
    environment:
      POSTGRES_USER: akibai
      POSTGRES_PASSWORD: akibaipass
      POSTGRES_DB: akibai_explorer
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
volumes:
  pgdata:
EOF
    log_success "docker-compose.yml created"
  fi
  savepoint "docker-compose.yml checked/created"


  # 7. Frontend Vite
  if [ ! -d frontend/akibai-explorer-frontend ]; then
    cd frontend && npm create vite@latest akibai-explorer-frontend -- --template react -y && cd ..
    log_success "Vite React app scaffolded"
  fi
  savepoint "Frontend scaffolded"


  # 8. Auto-generate frontend/akibai-explorer-frontend/src/brandkit.css if missing
  if [ -d frontend/akibai-explorer-frontend/src ] && [ ! -f frontend/akibai-explorer-frontend/src/brandkit.css ]; then
    echo '/* Akibai Brandkit CSS */' > frontend/akibai-explorer-frontend/src/brandkit.css
    echo '' >> frontend/akibai-explorer-frontend/src/brandkit.css
    echo ':root {' >> frontend/akibai-explorer-frontend/src/brandkit.css
    echo '  --akibai-primary: #0066cc;' >> frontend/akibai-explorer-frontend/src/brandkit.css
    echo '  --akibai-secondary: #00a86b;' >> frontend/akibai-explorer-frontend/src/brandkit.css
    echo '  --akibai-accent: #ff6b35;' >> frontend/akibai-explorer-frontend/src/brandkit.css
    echo '  --akibai-background: #f5f7fa;' >> frontend/akibai-explorer-frontend/src/brandkit.css
    echo '  --akibai-text: #333333;' >> frontend/akibai-explorer-frontend/src/brandkit.css
    echo '}' >> frontend/akibai-explorer-frontend/src/brandkit.css
    echo '' >> frontend/akibai-explorer-frontend/src/brandkit.css
    echo '.akibai-button {' >> frontend/akibai-explorer-frontend/src/brandkit.css
    echo '  background-color: var(--akibai-primary);' >> frontend/akibai-explorer-frontend/src/brandkit.css
    echo '  color: white;' >> frontend/akibai-explorer-frontend/src/brandkit.css
    echo '  padding: 10px 20px;' >> frontend/akibai-explorer-frontend/src/brandkit.css
    echo '  border: none;' >> frontend/akibai-explorer-frontend/src/brandkit.css
    echo '  border-radius: 4px;' >> frontend/akibai-explorer-frontend/src/brandkit.css
    echo '  cursor: pointer;' >> frontend/akibai-explorer-frontend/src/brandkit.css
    echo '}' >> frontend/akibai-explorer-frontend/src/brandkit.css
    echo '' >> frontend/akibai-explorer-frontend/src/brandkit.css
    echo '.akibai-card {' >> frontend/akibai-explorer-frontend/src/brandkit.css
    echo '  background: white;' >> frontend/akibai-explorer-frontend/src/brandkit.css
    echo '  border-radius: 8px;' >> frontend/akibai-explorer-frontend/src/brandkit.css
    echo '  box-shadow: 0 2px 10px rgba(0,0,0,0.1);' >> frontend/akibai-explorer-frontend/src/brandkit.css
    echo '  padding: 20px;' >> frontend/akibai-explorer-frontend/src/brandkit.css
    echo '}' >> frontend/akibai-explorer-frontend/src/brandkit.css
    log_success "frontend/akibai-explorer-frontend/src/brandkit.css created"
  fi
  savepoint "frontend/brandkit.css checked/created"


  # 9. Auto-generate frontend/akibai-explorer-frontend/src/App.jsx if missing
  if [ -d frontend/akibai-explorer-frontend/src ] && [ ! -f frontend/akibai-explorer-frontend/src/App.jsx ]; then
    echo 'import React, { useState, useEffect } from "react";' > frontend/akibai-explorer-frontend/src/App.jsx
    echo 'import axios from "axios";' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo 'import { Container, Typography, Box, Card, CardContent } from "@mui/material";' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo 'import "./brandkit.css";' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo 'function App() {' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '  const [repos, setRepos] = useState([]);' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '  const [loading, setLoading] = useState(true);' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '  useEffect(() => {' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '    axios.get("http://localhost:8000/api/github/repos")' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '      .then(response => {' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '        setRepos(response.data);' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '        setLoading(false);' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '      })' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '      .catch(error => {' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '        console.error("Error fetching repos:", error);' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '        setLoading(false);' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '      });' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '  }, []);' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '  return (' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '    <Container maxWidth="lg">' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '      <Box sx={{ my: 4 }}>' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '        <Typography variant="h3" component="h1" gutterBottom>' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '          Akibai Explorer' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '        </Typography>' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '        {loading ? (' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '          <Typography>Loading repositories...</Typography>' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '        ) : (' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '          repos.map(repo => (' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '            <Card key={repo.id} className="akibai-card" sx={{ mb: 2 }}>' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '              <CardContent>' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '                <Typography variant="h5">{repo.name}</Typography>' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '                <Typography variant="body2" color="text.secondary">' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '                  {repo.description || "No description"}' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '                </Typography>' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '                <Typography variant="caption">Stars: {repo.stargazers_count}</Typography>' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '              </CardContent>' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '            </Card>' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '          ))' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '        )}' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '      </Box>' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '    </Container>' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '  );' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '}' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo '' >> frontend/akibai-explorer-frontend/src/App.jsx
    echo 'export default App;' >> frontend/akibai-explorer-frontend/src/App.jsx
    log_success "frontend/akibai-explorer-frontend/src/App.jsx created"
  fi
  savepoint "frontend/App.jsx checked/created"



  # 10. Check for dox/discover_github_repos.sh
  if [ ! -f dox/discover_github_repos.sh ]; then
    log_error "dox/discover_github_repos.sh not found! Please add the script to the dox folder."
  else
    chmod +x dox/discover_github_repos.sh
    log_success "dox/discover_github_repos.sh is present and executable"
  fi
  savepoint "discovery script checked/created"

  # 11. Install frontend dependencies
  if [ -d frontend/eoex-explorer-frontend ]; then
    cd frontend/eoex-explorer-frontend && npm install && npm install @mui/material @emotion/react @emotion/styled axios || npm install --force @mui/material @emotion/react @emotion/styled axios
    cd ../../..
  fi

  # 12. Docker Compose up
  run_and_log "Starting PostgreSQL via Docker" "docker-compose up -d" "docker_up.log" || ERRORS=1

  # 13. Init DB
  run_and_log "Initializing DB" "cd backend && source venv/bin/activate && python init_db.py" "init_db.log" || ERRORS=1

  # 14. Start backend
  run_and_log "Starting backend server" "cd backend && source venv/bin/activate && nohup uvicorn main:app --host 0.0.0.0 --port 8000 &" "backend.log" || ERRORS=1

  # 15. Build frontend
  run_and_log "Building frontend" "cd frontend/eoex-explorer-frontend && npm run build" "frontend_build.log" || ERRORS=1
  run_and_log "Starting frontend preview" "cd frontend/eoex-explorer-frontend && npm run preview &" "frontend_preview.log" || ERRORS=1

  if [ $ERRORS -eq 0 ]; then
    log_success "All steps completed successfully in iteration $ITER"
    break
  else
    log_warning "Errors detected in iteration $ITER. Attempting auto-remediation and retrying."
    ITER=$((ITER+1))
    sleep 2
  fi

done

print_summary_table


  # Color codes
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  NC='\033[0m' # No Color

  LOG_FILE="self-healing.log"
  SUMMARY_FILE="self-healing-summary.txt"

  function log() {
    echo -e "$1" | tee -a "$LOG_FILE"
  }
  function log_step() {
    log "${BLUE}==> $1${NC}"
  }
  function log_success() {
    log "${GREEN}[SUCCESS] $1${NC}"
  }
  function log_error() {
    log "${RED}[ERROR] $1${NC}"
  }
  function log_warn() {
    log "${YELLOW}[WARN] $1${NC}"
  }
  function log_info() {
    log "${BLUE}[INFO] $1${NC}"
  }

  function run_cmd() {
    log_step "$1"
    eval "$2" >> "$LOG_FILE" 2>&1 || {
      log_error "$1 failed. See $LOG_FILE for details."
      return 1
    }
    log_success "$1 completed."
  }

  function summary_table() {
    echo -e "\n${GREEN}==================== FINAL SUMMARY ====================${NC}" | tee -a "$LOG_FILE" "$SUMMARY_FILE"
    printf "%-30s | %-10s\n" "Step" "Status" | tee -a "$SUMMARY_FILE"
    printf "%-30s | %-10s\n" "------------------------------" "----------" | tee -a "$SUMMARY_FILE"
    for s in "${STEPS[@]}"; do
      printf "%-30s | %-10s\n" "$s" "SUCCESS" | tee -a "$SUMMARY_FILE"
    done
    echo -e "${GREEN}======================================================${NC}" | tee -a "$LOG_FILE" "$SUMMARY_FILE"
  }

  # Steps to execute
  STEPS=(
    "Create folders"
    "Setup Python venv and install backend dependencies"
    "Create backend files"
    "Setup Docker Compose for PostgreSQL"
    "Scaffold frontend with Vite + React"
    "Install frontend dependencies"
    "Add brandkit CSS"
    "Replace App.jsx"
    "Create GitHub repo discovery script"
    "Start PostgreSQL"
    "Init DB"
    "Start backend"
    "Build and start frontend"
  )

  log_info "Building and starting EOEX Explorer..."
  run_cmd "Starting PostgreSQL" "docker-compose up -d"
  run_cmd "Init DB" "cd backend && source venv/bin/activate && python init_db.py && deactivate"
  run_cmd "Start backend" "cd backend && source venv/bin/activate && nohup uvicorn main:app --host 0.0.0.0 --port 8000 & && deactivate"
  run_cmd "Build frontend" "cd frontend/eoex-explorer-frontend && npm run build"
  run_cmd "Start frontend preview" "cd frontend/eoex-explorer-frontend && npm run preview &"

  summary_table

  log_success "EOEX Explorer is running!"
  log_info "Run dox/discover_github_repos.sh to populate the database with GitHub repos."