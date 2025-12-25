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
