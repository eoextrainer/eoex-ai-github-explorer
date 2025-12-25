import subprocess

app = Flask(__name__)
CORS(app)

GITHUB_TOKEN = os.getenv('GITHUB_TOKEN')
OPENAI_API_KEY = os.getenv('OPENAI_API_KEY')
DATABASE_URL = os.getenv('DATABASE_URL', 'postgresql://explorer:explorerpass@db:5432/explorer_db')
openai.api_key = OPENAI_API_KEY

def get_db_connection():
    return psycopg2.connect(DATABASE_URL)

def init_db():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute('''
        CREATE TABLE IF NOT EXISTS categories (
            id SERIAL PRIMARY KEY,
            name VARCHAR(100) UNIQUE NOT NULL,
app = Flask(__name__)
CORS(app)

GITHUB_TOKEN = os.getenv('GITHUB_TOKEN')
OPENAI_API_KEY = os.getenv('OPENAI_API_KEY')
DATABASE_URL = os.getenv('DATABASE_URL', 'postgresql://explorer:explorerpass@db:5432/explorer_db')
openai.api_key = OPENAI_API_KEY

def get_db_connection():
    return psycopg2.connect(DATABASE_URL)

def init_db():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute('''
        CREATE TABLE IF NOT EXISTS categories (
            id SERIAL PRIMARY KEY,
            name VARCHAR(100) UNIQUE NOT NULL,
            description TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        CREATE TABLE IF NOT EXISTS repositories (
            id SERIAL PRIMARY KEY,
            category_id INTEGER REFERENCES categories(id),
            repo_name VARCHAR(200) NOT NULL,
            owner VARCHAR(100) NOT NULL,
            full_name VARCHAR(300) UNIQUE NOT NULL,
            url VARCHAR(500) UNIQUE NOT NULL,
            description TEXT,
            language VARCHAR(50),
            stars INTEGER DEFAULT 0,
            forks INTEGER DEFAULT 0,
            last_commit TIMESTAMP,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            validation_status VARCHAR(50) DEFAULT 'pending',
            validation_level INTEGER DEFAULT 0,
            http_status INTEGER,
            is_active BOOLEAN DEFAULT true
        );
        CREATE TABLE IF NOT EXISTS search_queries (
            id SERIAL PRIMARY KEY,
            category_id INTEGER REFERENCES categories(id),
            query_text TEXT NOT NULL,
            results_count INTEGER DEFAULT 0,
            success_rate DECIMAL(5,2),
            executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        CREATE TABLE IF NOT EXISTS validation_logs (
            id SERIAL PRIMARY KEY,
            repo_id INTEGER REFERENCES repositories(id),
            validation_type VARCHAR(50),
            status_code INTEGER,
            result BOOLEAN,
            details TEXT,
            executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        CREATE TABLE IF NOT EXISTS logs (
            id SERIAL PRIMARY KEY,
            event TEXT,
            level TEXT,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        CREATE TABLE IF NOT EXISTS savepoints (
            id SERIAL PRIMARY KEY,
            commit_hash TEXT,
            description TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    ''')
    # Insert default categories
    categories = [
        ('Web Apps (HTML/CSS/JS/Python/PostgreSQL)', 'Full-stack web applications'),
        ('Hybrid Mobile Apps (HTML/CSS/JS/Python/PostgreSQL)', 'Cross-platform mobile apps'),
        ('Basketball Clubs', 'Team management and club systems'),
        ('Basketball Scouts', 'Scouting and talent evaluation tools'),
        ('Basketball Agents', 'Agent and player management systems'),
        ('Basketball Players', 'Player profiles and statistics'),
        ('Basketball Games', 'Basketball-related games and simulations'),
        ('Online Warehousing Platforms', 'Warehouse management systems'),
        ('Online CRM Projects', 'Customer relationship management'),
        ('Voice-Activated AI Prompt Engines', 'Voice-controlled AI systems')
    ]
    for category in categories:
        cur.execute(
            'INSERT INTO categories (name, description) VALUES (%s, %s) ON CONFLICT (name) DO NOTHING',
            category
        )
    conn.commit()
    cur.close()
    conn.close()

class GitHubDiscoveryEngine:
    def __init__(self):
        self.base_url = "https://api.github.com/search/repositories"
        self.headers = {
            "Authorization": f"token {GITHUB_TOKEN}",
            "Accept": "application/vnd.github.v3+json"
        }

    def generate_search_query(self, category_name, user_input=None):
        query_templates = {
            'Web Apps (HTML/CSS/JS/Python/PostgreSQL)': [
                'language:python language:javascript language:html language:css topic:web-app topic:fullstack',
                'django flask postgresql in:readme in:description',
                'full-stack web application python javascript postgresql'
            ],
            'Hybrid Mobile Apps (HTML/CSS/JS/Python/PostgreSQL)': [
                'language:javascript language:python topic:mobile-app topic:hybrid',
                'react-native capacitor cordova postgresql backend',
                'mobile app python api javascript postgresql'
            ],
            'Basketball Clubs': [
                'topic:basketball topic:sports-club topic:team-management',
                'basketball club management system in:readme',
                'sports team basketball administration'
            ],
            'Basketball Scouts': [
                'basketball scouting talent evaluation in:readme',
                'sports analytics basketball scout',
                'player evaluation basketball system'
            ],
            'Basketball Agents': [
                'basketball agent player management in:readme',
                'sports agency management system',
                'player representation basketball'
            ],
            'Basketball Players': [
                'basketball player statistics profile in:readme',
                'sports athlete data basketball',
                'player stats basketball tracker'
            ],
            'Basketball Games': [
                'basketball game simulation in:readme',
                'sports game basketball unity pygame',
                'basketball video game development'
            ],
            'Online Warehousing Platforms': [
                'warehouse management system in:readme',
                'inventory management system postgresql',
                'logistics warehouse tracking system'
            ],
            'Online CRM Projects': [
                'customer relationship management crm in:readme',
                'crm system django flask postgresql',
                'sales pipeline management system'
            ],
            'Voice-Activated AI Prompt Engines': [
                'voice recognition ai prompt engine in:readme',
                'speech-to-text ai assistant',
                'voice activated chatbot openai'
            ]
        }
        if user_input:
            keywords = self.parse_user_input(user_input)
            return f"{' '.join(keywords)} language:python language:javascript"
        return query_templates.get(category_name, [category_name])[0]

    def parse_user_input(self, user_input):
        clean_input = re.sub(r'[^\w\s,]', '', user_input.lower())
        if ',' in clean_input:
            return [word.strip() for word in clean_input.split(',')]
        words = clean_input.split()
        stop_words = {'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by'}
        keywords = [word for word in words if word not in stop_words]
        return keywords

    async def search_github(self, query, per_page=10):
        params = {
            'q': query,
            'per_page': per_page,
            'sort': 'stars',
            'order': 'desc'
        }
        async with aiohttp.ClientSession(headers=self.headers) as session:
            async with session.get(self.base_url, params=params) as response:
                if response.status == 200:
                    data = await response.json()
                    return data.get('items', [])
                else:
                    print(f"GitHub API Error: {response.status}")
                    return []

    async def validate_repository(self, repo_url):
        validation_results = {
            'level1': False,
            'level2': False,
            'level3': False,
            'http_status': None,
            'redirect_chain': [],
            'content_check': 0
        }
        try:
            async with aiohttp.ClientSession() as session:
                async with session.head(repo_url, allow_redirects=False) as response:
                    validation_results['http_status'] = response.status
                    validation_results['level1'] = response.status == 200
                async with session.get(repo_url, allow_redirects=True) as response:
                    redirect_history = [str(resp.url) for resp in response.history]
                    validation_results['redirect_chain'] = redirect_history
                    validation_results['level2'] = not any('404' in url.lower() for url in redirect_history)
                async with session.get(repo_url) as response:
                    content = await response.text()
                    not_found_patterns = ['not found', '404', 'page not found', 'repository not found']
                    matches = sum(1 for pattern in not_found_patterns if pattern in content.lower())
                    validation_results['content_check'] = matches
                    validation_results['level3'] = matches == 0
            return validation_results
        except Exception as e:
            print(f"Validation error for {repo_url}: {e}")
            return validation_results

    def check_repository_activity(self, owner, repo_name):
        api_url = f"https://api.github.com/repos/{owner}/{repo_name}"
        try:
            response = requests.get(api_url, headers=self.headers)
            if response.status_code == 200:
                repo_data = response.json()
                pushed_at = repo_data.get('pushed_at')
                if pushed_at:
                    last_commit = datetime.strptime(pushed_at, '%Y-%m-%dT%H:%M:%SZ')
                    days_since = (datetime.utcnow() - last_commit).days
                    if days_since > 730:
                        return False, f"Last commit {days_since} days ago"
                    return True, f"Active ({days_since} days since last commit)"
            return False, "Could not fetch activity data"
        except Exception as e:
            return False, f"Error: {str(e)}"

discovery_engine = GitHubDiscoveryEngine()

@app.route("/", methods=["GET"])
def index():
    return {"status": "akibai explorer backend running"}

@app.route("/api/categories", methods=["GET"])
def get_categories():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT id, name, description FROM categories ORDER BY id")
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify([
        {"id": r[0], "name": r[1], "description": r[2]} for r in rows
    ])

@app.route("/api/repositories", methods=["GET"])
def get_repositories():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT id, repo_name, owner, full_name, url, description, language, stars, forks, last_commit, validation_status, http_status FROM repositories ORDER BY stars DESC LIMIT 100")
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify([
        {
            "id": r[0], "repo_name": r[1], "owner": r[2], "full_name": r[3], "url": r[4],
            "description": r[5], "language": r[6], "stars": r[7], "forks": r[8],
            "last_commit": r[9], "validation_status": r[10], "http_status": r[11]
        } for r in rows
    ])

@app.route("/api/github/discover", methods=["POST"])
def github_discover():
    data = request.get_json()
    keywords = data.get("keywords", [])
    category = data.get("category", None)
    user_input = ' '.join(keywords) if keywords else None
    query = discovery_engine.generate_search_query(category or 'Web Apps (HTML/CSS/JS/Python/PostgreSQL)', user_input)
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    repos = loop.run_until_complete(discovery_engine.search_github(query, per_page=10))
    # Insert discovered repos into DB
    conn = get_db_connection()
    cur = conn.cursor()
    for repo in repos:
        cur.execute('''
            INSERT INTO repositories (repo_name, owner, full_name, url, description, language, stars, forks, last_commit, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
            ON CONFLICT (full_name) DO NOTHING
        ''', (
            repo.get('name'), repo.get('owner', {}).get('login'), repo.get('full_name'), repo.get('html_url'),
            repo.get('description'), repo.get('language'), repo.get('stargazers_count'), repo.get('forks_count'),
            repo.get('pushed_at')
        ))
    conn.commit()
    cur.close()
    conn.close()
    return jsonify({"discovery": "initiated", "count": len(repos)})

@app.route("/api/repositories/validate", methods=["POST"])
def validate_repositories():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT id, url FROM repositories WHERE validation_status = 'pending' LIMIT 10")
    repos = cur.fetchall()
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    results = []
    for repo_id, url in repos:
        validation = loop.run_until_complete(discovery_engine.validate_repository(url))
        status = 'valid' if validation['level1'] and validation['level2'] and validation['level3'] else 'invalid'
        cur.execute('''
            UPDATE repositories SET validation_status = %s, validation_level = %s, http_status = %s WHERE id = %s
        ''', (status, sum([validation['level1'], validation['level2'], validation['level3']]), validation['http_status'], repo_id))
        cur.execute('''
            INSERT INTO validation_logs (repo_id, validation_type, status_code, result, details)
            VALUES (%s, %s, %s, %s, %s)
        ''', (repo_id, 'full', validation['http_status'], status == 'valid', json.dumps(validation)))
        results.append({"repo_id": repo_id, "status": status, "validation": validation})
    conn.commit()
    cur.close()
    conn.close()
    return jsonify(results)

if __name__ == "__main__":
    init_db()
    app.run(host="0.0.0.0", port=8000)
