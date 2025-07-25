from flask import Flask, request, jsonify
from agent import gpt_4o_mini
import os
import tempfile

app = Flask(__name__)

@app.route('/agent', methods=['POST'])
def agent():
    # Header auth: compare fixed key-value, value from ENV
    AUTH_HEADER_KEY = 'X-API-KEY'
    AUTH_HEADER_VALUE = os.environ.get('AGENT_API_KEY')
    req_header_value = request.headers.get(AUTH_HEADER_KEY)
    if AUTH_HEADER_VALUE is not None and req_header_value != AUTH_HEADER_VALUE:
        return jsonify({"error": "Unauthorized"}), 401
    messages = request.json.get('messages')
    if not messages:
        return jsonify({"error": "No messages provided"}), 400
    return jsonify(gpt_4o_mini(messages))

if __name__ == '__main__':
    app.run(debug=True)