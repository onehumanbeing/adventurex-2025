import os
import time
import sounddevice as sd
import numpy as np
import wave
import requests

SILICONFLOW_URL = "https://api.siliconflow.cn/v1/audio/transcriptions"
MODEL = "FunAudioLLM/SenseVoiceSmall"
TOKEN = os.environ.get("SILICONFLOW_TOKEN")  # 从环境变量读取

AUDIO_OUTPUT_DIR = os.path.join(".", "cache", "audio")
os.makedirs(AUDIO_OUTPUT_DIR, exist_ok=True)
AUDIO_DURATION = int(os.environ.get("AUDIO_DURATION", 5))

def record_audio(filename, duration=5, samplerate=16000, channels=1):
    print(f"开始录音: {filename} ({duration}s)...")
    recording = sd.rec(int(duration * samplerate), samplerate=samplerate, channels=channels, dtype='int16')
    sd.wait()
    with wave.open(filename, 'wb') as wf:
        wf.setnchannels(channels)
        wf.setsampwidth(2)  # 16bit = 2 bytes
        wf.setframerate(samplerate)
        wf.writeframes(recording.tobytes())
    print(f"录音完成: {filename}")

def transcribe_audio(filename):
    with open(filename, 'rb') as f:
        files = {
            'file': (filename, f, 'audio/wav'),
        }
        data = {'model': MODEL}
        headers = {"Authorization": f"Bearer {TOKEN}"}
        resp = requests.post(SILICONFLOW_URL, files=files, data=data, headers=headers)
        try:
            text = resp.json().get('text', '')
        except Exception:
            text = resp.text
        return text

def main():
    timestamp = int(time.time())
    filename = os.path.join(AUDIO_OUTPUT_DIR, f"audio_{timestamp}.wav")
    record_audio(filename, duration=AUDIO_DURATION)
    # text = transcribe_audio(filename)
    # print(f"识别结果: {text}")

def periodic_main_call():
    while True:
        main()

if __name__ == "__main__":
    periodic_main_call()
