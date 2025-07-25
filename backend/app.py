from flask import Flask, request, jsonify, Response, stream_with_context
from agent import gpt_4o_mini, call_openai_api
import os
import requests

app = Flask(__name__)

SILICONFLOW_URL = "https://api.siliconflow.cn/v1/audio/transcriptions"
MODEL = "FunAudioLLM/SenseVoiceSmall"
TOKEN = "sk-xdewqafvtfsqxhvovpidjvygplxwsfqrntovkvejdgtjzmgj"  # 硅流API-Key密钥


@app.route('/asr/stream', methods=['POST'])
def asr_stream():
    def generate():
        # 前端应以 multipart/form-data 方式上传多个 audio 字段，每个字段为一段音频
        for audio_chunk in request.files.getlist('audio'):
            files = {
                'file': (audio_chunk.filename, audio_chunk, audio_chunk.mimetype),
            }
            data = {'model': MODEL}
            headers = {"Authorization": f"Bearer {TOKEN}"}
            resp = requests.post(SILICONFLOW_URL, files=files, data=data, headers=headers)
            try:
                text = resp.json().get('text', '')
            except Exception:
                text = resp.text
            # SSE格式返回
            yield f"data: {text}\n\n"
    return Response(stream_with_context(generate()), mimetype='text/event-stream')

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
    return jsonify(call_openai_api(messages))

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

@app.route('/', methods=['GET'])
def index():
    import time
    return jsonify({
        "timestamp": int(time.time()),
        "version": "0.0.1"
    })

if __name__ == '__main__':
    app.run(debug=True)