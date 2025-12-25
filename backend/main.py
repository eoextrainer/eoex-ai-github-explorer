from flask import Flask
from flask_cors import CORS
from flask_socketio import SocketIO
import os

app = Flask(__name__)
CORS(app)
socketio = SocketIO(app, cors_allowed_origins="*")

@app.route("/")
def index():
    return {"status": "akibai explorer backend running"}

if __name__ == "__main__":
    socketio.run(app, host="0.0.0.0", port=8000)
