import os
import requests
import base64

def t2a_minimax(
    text: str,
    model: str = "speech-02-hd",
    voice_id: str = "Chinese (Mandarin)_Warm_Girl",
    speed: float = 1.0,
    vol: float = 1.0,
    pitch: float = 0,
    emotion: str = "happy",
    sample_rate: int = 32000,
    bitrate: int = 128000,
    audio_format: str = "mp3",
    output_format: str = "hex",
    language_boost: str = "auto"
) -> bytes:
    """
    调用 minimax T2A（文本转音频）API，返回音频二进制内容（mp3）。
    """
    api_key = os.environ.get("MINIMAX_API_KEY")
    group_id = os.environ.get("MINIMAX_GROUP_ID")
    assert api_key, "MINIMAX_API_KEY 未设置"
    assert group_id, "MINIMAX_GROUP_ID 未设置"

    url = f"https://api.minimaxi.com/v1/t2a_v2?GroupId={group_id}"
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    payload = {
        "model": model,
        "text": text,
        "stream": False,
        "language_boost": language_boost,
        "output_format": output_format,
        "voice_setting": {
            "voice_id": voice_id,
            "speed": speed,
            "vol": vol,
            "pitch": pitch,
            "emotion": emotion
        },
        "audio_setting": {
            "sample_rate": sample_rate,
            "bitrate": bitrate,
            "format": audio_format
        }
    }
    resp = requests.post(url, headers=headers, json=payload)
    resp.raise_for_status()
    data = resp.json()
    if "data" in data and "audio" in data["data"]:
        audio_hex = data["data"]["audio"]
        audio_bytes = bytes.fromhex(audio_hex)
        return audio_bytes
    else:
        raise Exception(f"T2A API 返回异常: {data}")

if __name__ == "__main__":
    import sys
    text = sys.argv[1] if len(sys.argv) > 1 else "Henry你好，诺诺米为您服务"
    audio = t2a_minimax(text)
    with open("hello.mp3", "wb") as f:
        f.write(audio)
    print("音频已保存为 hello.mp3")
