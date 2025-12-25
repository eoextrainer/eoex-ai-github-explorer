#!/bin/bash
set -e

# 1. Create folders
mkdir -p backend frontend scripts

# 2. Backend: FastAPI + SQLAlchemy + PostgreSQL
cd backend
python3 -m venv venv
source venv/bin/activate
pip install fastapi uvicorn sqlalchemy psycopg2-binary pydantic python-dotenv requests

cat > .env <<EOF
DATABASE_URL=postgresql://eoex:eoexpass@localhost:5432/eoex_explorer
EOF

cat > main.py <<EOF
from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy import create_engine, Column, Integer, String, Text, DateTime
from sqlalchemy.orm import sessionmaker, declarative_base, Session
from pydantic import BaseModel
import os, datetime

DATABASE_URL = os.getenv("DATABASE_URL")
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
Base = declarative_base()

class Repo(Base):
    __tablename__ = "repos"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    url = Column(String, unique=True, index=True)
    description = Column(Text)
    category = Column(String)
    last_commit = Column(DateTime)

class RepoCreate(BaseModel):
    name: str
    url: str
    description: str
    category: str
    last_commit: datetime.datetime

app = FastAPI()

def get_db():
    db = SessionLocal()
    try: yield db
    finally: db.close()

@app.post("/repos/", response_model=dict)
def create_repo(repo: RepoCreate, db: Session = Depends(get_db)):
    db_repo = Repo(**repo.dict())
    db.add(db_repo)
    db.commit()
    db.refresh(db_repo)
    return {"id": db_repo.id}

@app.get("/repos/", response_model=list)
def list_repos(skip: int = 0, limit: int = 50, db: Session = Depends(get_db)):
    return db.query(Repo).offset(skip).limit(limit).all()

@app.get("/repos/{repo_id}", response_model=dict)
def get_repo(repo_id: int, db: Session = Depends(get_db)):
    repo = db.query(Repo).filter(Repo.id == repo_id).first()
    if not repo: raise HTTPException(404)
    return repo.__dict__

@app.put("/repos/{repo_id}", response_model=dict)
def update_repo(repo_id: int, repo: RepoCreate, db: Session = Depends(get_db)):
    db_repo = db.query(Repo).filter(Repo.id == repo_id).first()
    if not db_repo: raise HTTPException(404)
    for k, v in repo.dict().items(): setattr(db_repo, k, v)
    db.commit()
    return db_repo.__dict__

@app.delete("/repos/{repo_id}", response_model=dict)
def delete_repo(repo_id: int, db: Session = Depends(get_db)):
    db_repo = db.query(Repo).filter(Repo.id == repo_id).first()
    if not db_repo: raise HTTPException(404)
    db.delete(db_repo)
    db.commit()
    return {"ok": True}

if __name__ == "__main__":
    Base.metadata.create_all(bind=engine)
EOF

cat > init_db.py <<EOF
import os
from main import Base, engine
Base.metadata.create_all(bind=engine)
EOF

deactivate
cd ..

# 3. PostgreSQL: Docker setup
cat > docker-compose.yml <<EOF
version: '3.8'
services:
  db:
    image: postgres:15
    restart: always
    environment:
      POSTGRES_USER: eoex
      POSTGRES_PASSWORD: eoexpass
      POSTGRES_DB: eoex_explorer
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
volumes:
  pgdata:
EOF

# 4. Frontend: Vite + React + Brandkit
cd frontend
npm create vite@latest eoex-explorer-frontend -- --template react
cd eoex-explorer-frontend
npm install
npm install @mui/material @emotion/react @emotion/styled axios

# Add brandkit CSS
cat > src/brandkit.css <<EOF
/* Paste the CSS from brandkit-ui-frontend-google.txt here */
:root {
  --color-play-green: #34A853;
  --color-play-blue:  #4285F4;
  --color-play-yellow:#FBBC04;
  --color-play-red:   #EA4335;
  --color-primary: var(--color-play-green);
  --color-bg:           #FFFFFF;
  --color-bg-alt:       #F1F3F4;
  --color-surface:      #FFFFFF;
  --color-surface-alt:  #F8F9FA;
  --color-border-subtle:#E0E0E0;
  --color-divider:      #E5E7EB;
  --color-text-primary:   #202124;
  --color-text-secondary: #5F6368;
  --color-text-muted:     #80868B;
  --color-text-on-primary:#FFFFFF;
  --color-hover:          #F5F7F7;
  --color-focus-ring:     #4285F4;
  --color-ripple:         rgba(66, 133, 244, 0.16);
  --color-rating-star:    #F4B400;
  --color-badge-free:     #34A853;
  --color-badge-sale:     #EA4335;
  --font-display: "Google Sans", "Product Sans", system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  --font-body:    "Roboto", system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  --fs-display-xl: 32px;
  --fs-display-lg: 28px;
  --fs-display-md: 24px;
  --fs-title-md:   20px;
  --fs-title-sm:   16px;
  --fs-body-lg:    16px;
  --fs-body-md:    14px;
  --fs-body-sm:    12px;
  --lh-tight: 1.2;
  --lh-normal:1.4;
  --lh-loose: 1.6;
}
/* ...rest of brandkit styles... */
EOF

# Replace App.jsx with a premium SPA layout (header, search, dropdown, table, footer)
cat > src/App.jsx <<EOF
import React, { useState, useEffect } from "react";
import axios from "axios";
import "./brandkit.css";

const categories = [
  "Web Apps",
  "Hybrid Mobile Apps",
  "Basketball Clubs",
  "Basketball Scouts",
  "Basketball Agents",
  "Basketball Players",
  "Basketball Games",
  "Online Warehousing Platforms",
  "Online CRM Projects",
  "Voice-Activated AI Prompt Engines"
];

function App() {
  const [repos, setRepos] = useState([]);
  const [search, setSearch] = useState("");
  const [category, setCategory] = useState(categories[0]);
  const [page, setPage] = useState(0);

  useEffect(() => {
    axios.get(\`/api/repos?skip=\${page*50}&limit=50\`).then(res => setRepos(res.data));
  }, [page]);

  const handleSearch = async () => {
    // Call backend to search and update repos
    // For demo, just reload
    setPage(0);
    axios.get(\`/api/repos?skip=0&limit=50&search=\${search}&category=\${category}\`).then(res => setRepos(res.data));
  };

  return (
    <div className="gp-body" style={{ minHeight: "100vh", display: "flex", flexDirection: "column" }}>
      <header className="gp-topbar">
        <div className="gp-topbar-inner">
          <div className="gp-logo" style={{ flex: 1, textAlign: "center", fontSize: "2rem", fontWeight: "bold" }}>EOEX Explorer</div>
          <div style={{ flex: 0 }}>
            <button className="gp-btn gp-btn-primary gp-ripple">Sign In | Login</button>
          </div>
        </div>
      </header>
      <main className="gp-main" style={{ flex: 1 }}>
        <aside className="gp-sidebar"></aside>
        <section className="gp-content">
          <div style={{ marginBottom: 24 }}>
            <input
              className="gp-search-input"
              style={{ width: "60%", marginRight: 12 }}
              placeholder="Enter repo name, description, or URL"
              value={search}
              onChange={e => setSearch(e.target.value)}
            />
            <select
              className="gp-chip"
              value={category}
              onChange={e => setCategory(e.target.value)}
              style={{ marginRight: 12 }}
            >
              {categories.map(c => <option key={c}>{c}</option>)}
            </select>
            <button className="gp-btn gp-btn-primary gp-ripple" onClick={handleSearch}>Search</button>
          </div>
          <div className="gp-app-grid" style={{ maxHeight: 600, overflowY: "auto" }}>
            {repos.map((repo, i) => (
              <article className="gp-app-card" key={repo.id}>
                <a href={repo.url} className="gp-app-card-link" target="_blank" rel="noopener noreferrer">
                  <div className="gp-app-card-body">
                    <h3 className="gp-app-card-title">{repo.name}</h3>
                    <p className="gp-app-card-subtitle">{repo.category}</p>
                    <div className="gp-app-card-meta">{repo.description}</div>
                  </div>
                </a>
              </article>
            ))}
          </div>
          <div style={{ marginTop: 16, display: "flex", justifyContent: "center", gap: 8 }}>
            <button className="gp-link-button" onClick={() => setPage(Math.max(0, page-1))}>Prev</button>
            <span>Page {page+1}</span>
            <button className="gp-link-button" onClick={() => setPage(page+1)}>Next</button>
          </div>
        </section>
      </main>
      <footer style={{ background: "var(--color-bg-alt)", padding: 24, textAlign: "center", color: "var(--color-text-muted)" }}>
        <div>EOEX Explorer &copy; 2025 | AI-powered GitHub Repository Discovery</div>
      </footer>
    </div>
  );
}

export default App;
EOF

cd ../../..

# 5. Scripts: GitHub repo discovery/validation stub
cat > scripts/discover_github_repos.sh <<EOF
#!/bin/bash
# This script discovers, validates, and saves GitHub repos to the backend

CATEGORIES=(
  "web apps"
  "hybrid mobile apps"
  "basketball clubs"
  "basketball scouts"
  "basketball agents"
  "basketball players"
  "basketball games"
  "online warehousing platforms"
  "online CRM projects"
  "voice activated ai prompt engines"
)

for CATEGORY in "\${CATEGORIES[@]}"; do
  echo "Searching for: \$CATEGORY"
  # Example: Use GitHub API (requires token)
  # Replace YOUR_GITHUB_TOKEN with your token
  curl -s -H "Authorization: token YOUR_GITHUB_TOKEN" \
    "https://api.github.com/search/repositories?q=\$(echo \$CATEGORY | sed 's/ /+/g')+in:name,description,readme&per_page=100" \
    | jq -c '.items[]' | while read -r repo; do
      URL=\$(echo \$repo | jq -r '.html_url')
      NAME=\$(echo \$repo | jq -r '.full_name')
      DESC=\$(echo \$repo | jq -r '.description')
      # Validation
      STATUS=\$(curl -s -o /dev/null -w '%{http_code}' -L --max-time 10 "\$URL")
      if [ "\$STATUS" -eq 200 ]; then
        # Save to backend
        curl -X POST -H "Content-Type: application/json" -d "{\"name\":\"\$NAME\",\"url\":\"\$URL\",\"description\":\"\$DESC\",\"category\":\"\$CATEGORY\",\"last_commit\":\"$(date -Iseconds)\"}" http://localhost:8000/repos/
        echo "VALID: \$URL"
      else
        echo "INVALID (\$STATUS): \$URL"
      fi
    done
done
EOF
chmod +x scripts/discover_github_repos.sh

# 6. Build & Run instructions
echo "Building and starting EOEX Explorer..."

# Start PostgreSQL
docker-compose up -d

# Init DB
cd backend
source venv/bin/activate
python init_db.py
deactivate
cd ..

# Start backend
cd backend
source venv/bin/activate
nohup uvicorn main:app --host 0.0.0.0 --port 8000 &
deactivate
cd ..

# Start frontend
cd frontend/eoex-explorer-frontend
npm run build
npm run preview &

echo "EOEX Explorer is running!"
echo "Run scripts/discover_github_repos.sh to populate the database with GitHub repos."