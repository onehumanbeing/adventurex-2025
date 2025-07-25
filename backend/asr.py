from flask import Flask, request, Response, stream_with_context
import requests
import os

app = Flask(__name__)

SILICONFLOW_URL = "https://api.siliconflow.cn/v1/audio/transcriptions"
MODEL = "FunAudioLLM/SenseVoiceSmall"
TOKEN = "sk-xdewqafvtfsqxhvovpidjvygplxwsfqrntovkvejdgtjzmgj"  # 你的API密钥

@app.route('/api/asr/stream', methods=['POST'])
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

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001, debug=True) 