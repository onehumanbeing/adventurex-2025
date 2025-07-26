import os
import time
import sounddevice as sd
import numpy as np
import wave
import requests

# SiliconFlow API配置（用于音频转文字）
SILICONFLOW_URL = "https://api.siliconflow.cn/v1/audio/transcriptions"
MODEL = "FunAudioLLM/SenseVoiceSmall"
TOKEN = os.environ.get("SILICONFLOW_TOKEN")  # 从环境变量读取API令牌

# 音频输出目录和配置
AUDIO_OUTPUT_DIR = os.path.join(".", "cache", "audio")
os.makedirs(AUDIO_OUTPUT_DIR, exist_ok=True)
AUDIO_DURATION = int(os.environ.get("AUDIO_DURATION", 5))  # 录音时长（秒）

def record_audio(filename, duration=5, samplerate=16000, channels=1):
    """
    录制音频并保存为WAV文件
    
    Args:
        filename (str): 保存的文件路径
        duration (int): 录音时长（秒）
        samplerate (int): 采样率（Hz）
        channels (int): 声道数（1=单声道，2=立体声）
    """
    print(f"开始录音: {filename} ({duration}s)...")
    
    # 使用sounddevice录制音频
    recording = sd.rec(int(duration * samplerate), samplerate=samplerate, channels=channels, dtype='int16')
    sd.wait()  # 等待录音完成
    
    # 将录制的音频保存为WAV文件
    with wave.open(filename, 'wb') as wf:
        wf.setnchannels(channels)
        wf.setsampwidth(2)  # 16bit = 2 bytes
        wf.setframerate(samplerate)
        wf.writeframes(recording.tobytes())
    
    print(f"录音完成: {filename}")

def transcribe_audio(filename):
    """
    将音频文件转换为文字（使用SiliconFlow API）
    
    Args:
        filename (str): 音频文件路径
    
    Returns:
        str: 转写结果文字，失败时返回空字符串
    """
    with open(filename, 'rb') as f:
        files = {
            'file': (filename, f, 'audio/wav'),
        }
        data = {'model': MODEL}
        headers = {"Authorization": f"Bearer {TOKEN}"}
        try:
            # 发送POST请求到SiliconFlow API
            resp = requests.post(SILICONFLOW_URL, files=files, data=data, headers=headers, timeout=30)
            try:
                # 尝试解析JSON响应
                text = resp.json().get('text', '')
            except Exception:
                # 如果JSON解析失败，返回原始响应文本
                text = resp.text
            return text
        except requests.exceptions.Timeout:
            print(f"转写超时: {filename}")
            return ""
        except requests.exceptions.RequestException as e:
            print(f"转写请求失败: {filename}, {e}")
            return ""

def main():
    """
    执行一次录音操作
    """
    timestamp = int(time.time())
    filename = os.path.join(AUDIO_OUTPUT_DIR, f"audio_{timestamp}.wav")
    record_audio(filename, duration=AUDIO_DURATION)
    
    # 音频转文字功能（已注释，由transcribe.py模块处理）
    # text = transcribe_audio(filename)
    # print(f"识别结果: {text}")

def periodic_main_call():
    """
    周期性执行录音操作
    """
    while True:
        try:
            main()
        except KeyboardInterrupt:
            print("录音进程被中断")
            break
        except Exception as e:
            print(f"录音进程出错: {e}")
            time.sleep(1)  # 出错后等待1秒再继续

if __name__ == "__main__":
    periodic_main_call()
