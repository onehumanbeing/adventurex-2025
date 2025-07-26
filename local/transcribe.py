import os
import time
import requests

AUDIO_OUTPUT_DIR = os.path.join(".", "cache", "audio")
SILICONFLOW_URL = "https://api.siliconflow.cn/v1/audio/transcriptions"
MODEL = "FunAudioLLM/SenseVoiceSmall"
TOKEN = os.environ.get("SILICONFLOW_TOKEN")  # 从环境变量读取
AUDIO_TXT_PATH = os.path.join(AUDIO_OUTPUT_DIR, "audio.txt")

def transcribe_audio(filename):
    with open(filename, 'rb') as f:
        files = {
            'file': (filename, f, 'audio/wav'),
        }
        data = {'model': MODEL}
        headers = {"Authorization": f"Bearer {TOKEN}"}
        try:
            resp = requests.post(SILICONFLOW_URL, files=files, data=data, headers=headers, timeout=30)
            try:
                text = resp.json().get('text', '')
            except Exception:
                text = resp.text
            return text
        except requests.exceptions.Timeout:
            print(f"转写超时: {filename}")
            return ""
        except requests.exceptions.RequestException as e:
            print(f"转写请求失败: {filename}, {e}")
            return ""

def poll_and_transcribe_audio_dir(poll_interval=2):
    processed_files = set()
    while True:
        # 获取所有wav文件，按修改时间排序
        files = [f for f in os.listdir(AUDIO_OUTPUT_DIR) if f.endswith('.wav')]
        files_with_time = [
            (f, os.path.getmtime(os.path.join(AUDIO_OUTPUT_DIR, f)))
            for f in files
        ]
        files_with_time.sort(key=lambda x: x[1])  # 按时间排序

        for fname, _ in files_with_time:
            full_path = os.path.join(AUDIO_OUTPUT_DIR, fname)
            if fname not in processed_files:
                print(f"检测到新音频文件: {fname}，开始转写...")
                result = transcribe_audio(full_path)
                print(f"{fname} 识别结果: {result}")
                # 删除音频文件
                try:
                    os.remove(full_path)
                except Exception as e:
                    print(f"删除文件 {fname} 时出错: {e}")
                # 追加写入识别结果到audio.txt
                try:
                    with open(AUDIO_TXT_PATH, "a+", encoding="utf-8") as f:
                        f.write(f"{result}\n")
                except Exception as e:
                    print(f"写入audio.txt时出错: {e}")
                processed_files.add(fname)
        time.sleep(poll_interval)

if __name__ == "__main__":
    try:
        poll_and_transcribe_audio_dir()
    except KeyboardInterrupt:
        print("转写进程被中断")
    except Exception as e:
        print(f"转写进程出错: {e}")
