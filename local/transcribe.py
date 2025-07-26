"""
音频转写模块 - 负责将音频文件转换为文字

主要功能：
1. 监控音频目录中的新文件
2. 调用SiliconFlow API进行语音转文字
3. 将转写结果保存到audio.txt文件
4. 自动清理已处理的音频文件
"""

import os
import time
import requests

# 音频文件输出目录
AUDIO_OUTPUT_DIR = os.path.join(".", "cache", "audio")
# SiliconFlow API配置
SILICONFLOW_URL = "https://api.siliconflow.cn/v1/audio/transcriptions"
MODEL = "FunAudioLLM/SenseVoiceSmall"
TOKEN = os.environ.get("SILICONFLOW_TOKEN")  # 从环境变量读取API令牌
# 转写结果保存路径
AUDIO_TXT_PATH = os.path.join(AUDIO_OUTPUT_DIR, "audio.txt")

def transcribe_audio(filename):
    """
    将音频文件转换为文字
    
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

def poll_and_transcribe_audio_dir(poll_interval=2):
    """
    持续监控音频目录，自动转写新的音频文件
    
    Args:
        poll_interval (int): 轮询间隔时间（秒）
    """
    processed_files = set()  # 记录已处理的文件，避免重复处理
    while True:
        # 获取所有wav文件，按修改时间排序
        files = [f for f in os.listdir(AUDIO_OUTPUT_DIR) if f.endswith('.wav')]
        files_with_time = [
            (f, os.path.getmtime(os.path.join(AUDIO_OUTPUT_DIR, f)))
            for f in files
        ]
        files_with_time.sort(key=lambda x: x[1])  # 按时间排序，先处理旧文件

        for fname, _ in files_with_time:
            full_path = os.path.join(AUDIO_OUTPUT_DIR, fname)
            if fname not in processed_files:
                print(f"检测到新音频文件: {fname}，开始转写...")
                result = transcribe_audio(full_path)
                print(f"{fname} 识别结果: {result}")
                
                # 删除已处理的音频文件
                try:
                    os.remove(full_path)
                except Exception as e:
                    print(f"删除文件 {fname} 时出错: {e}")
                
                # 将转写结果追加到audio.txt文件
                try:
                    with open(AUDIO_TXT_PATH, "a+", encoding="utf-8") as f:
                        f.write(f"{fname}: {result}\n")
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
