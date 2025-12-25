from fastapi import FastAPI
from pydantic import BaseModel
import os
import sqlalchemy
app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "Akibai Explorer API is running!"}
