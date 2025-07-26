import os
from flask import Flask, request, jsonify
from agent import gpt_4o_mini, call_openai_api

app = Flask(__name__)

@app.route('/render', methods=['POST'])
def render():
    AUTH_HEADER_KEY = 'X-API-KEY'
    AUTH_HEADER_VALUE = os.environ.get('AGENT_API_KEY')
    req_header_value = request.headers.get(AUTH_HEADER_KEY)
    if AUTH_HEADER_VALUE is not None and req_header_value != AUTH_HEADER_VALUE:
        return jsonify({"error": "Unauthorized"}), 401
    messages = request.json.get('messages')
    if not messages:
        return jsonify({"error": "No messages provided"}), 400
    
    # 从请求中获取thread_id，如果没有则使用None（会自动生成）
    thread_id = request.json.get('thread_id')
    return jsonify(call_openai_api(messages, thread_id))

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
    
    # 从请求中获取thread_id，如果没有则使用None（会自动生成）
    thread_id = request.json.get('thread_id')
    return jsonify(gpt_4o_mini(messages, thread_id))

@app.route('/', methods=['GET'])
def index():
    import time
    return jsonify({
        "timestamp": int(time.time()),
        "version": "0.0.1"
    })

if __name__ == '__main__':
    app.run(debug=True)