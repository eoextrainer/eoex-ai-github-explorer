import psycopg2
import os

def init_db():
    conn = psycopg2.connect(
        dbname=os.getenv("POSTGRES_DB", "explorer_db"),
        user=os.getenv("POSTGRES_USER", "explorer"),
        password=os.getenv("POSTGRES_PASSWORD", "explorerpass"),
        host=os.getenv("POSTGRES_HOST", "db"),
        port=os.getenv("POSTGRES_PORT", "5432")
    )
    cur = conn.cursor()
    cur.execute('''
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
    conn.commit()
    cur.close()
    conn.close()

if __name__ == "__main__":
    init_db()
    print("Database initialized.")
