from pydantic import BaseModel
from openai import OpenAI
import traceback
import os
import time
import base64
import json
import glob
from generate_audio import t2a_minimax

HOST_URL = "https://helped-monthly-alpaca.ngrok-free.app"

class HtmlView(BaseModel):
    height: int
    width: int
    html: str
    danmu_text: str

def call_openai_api(messages):
    client = OpenAI(timeout=30.0)  # 设置30秒超时
    try:
        completion = client.beta.chat.completions.parse(
            model="gpt-4o-mini",
            messages=messages,
            response_format=HtmlView,
            max_tokens=10000,
        )
        response = completion.choices[0].message.parsed
        return response
    except Exception as e:
        print(f"OpenAI API调用失败: {e}")
        # 返回默认响应
        return HtmlView(
            height=400,
            width=600,
            html="<div style='padding: 16px; background-color: white; border-radius: 16px; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1); color: #007aff;'><h2 style='font-size: 20px; font-weight: bold; margin-bottom: 8px;'>系统提示</h2><p style='margin-bottom: 16px;'>网络连接超时，请稍后重试。</p></div>",
            danmu_text="网络连接超时"
        )

def reset_status():
    data = {
        "action": "nonomi",
        "value": "",
        "voice": "https://helped-monthly-alpaca.ngrok-free.app/voice/hello.mp3",
        "timestamp": int(time.time()),
        "html": "<div style='height: 100%; width: 100%; padding: 16px; background-color: white; border-radius: 16px; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1); color: #007aff;'><h2 style='font-size: 20px; font-weight: bold; margin-bottom: 8px;'>时尚提示</h2><p style='margin-bottom: 16px;'>您对这件衣服感兴趣，请确认价格以便购买！</p><div style='margin-top: 16px;'><button style='background-color: #007aff; color: white; padding: 10px 20px; border-radius: 12px; border: none; cursor: pointer;'>查询价格</button></div></div>",
        "danmu_text": "QAQ",
        "height": 400,
        "width": 600
    }
    with open("cache/status.json", "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=4)

def periodic_ai_task():
    reset_status()
    time.sleep(2)
    print("开始AI任务")
    AI_TIME_INTERVAL = int(os.environ.get("AI_TIME_INTERVAL", 5))
    SCREENSHOT_UPLOAD_AMOUNT = int(os.environ.get("SCREENSHOT_UPLOAD_AMOUNT", 1))
    USE_CAMERA = int(os.environ.get("USE_CAMERA", 0))
    if USE_CAMERA == 1:
        IMAGE_DIR = os.path.join(".", "cache", "camera")
    else:
        IMAGE_DIR = os.path.join(".", "cache", "screenshot")
    AUDIO_TXT_PATH = os.path.join(".", "cache", "audio", "audio.txt")
    PROMPT_PATH = os.path.join(".", "prompt.txt")

    while True:
        # 1. 获取最新的图片
        image_files = glob.glob(os.path.join(IMAGE_DIR, "*"))
        image_files = [f for f in image_files if os.path.isfile(f)]
        image_files.sort(key=lambda x: os.path.getmtime(x), reverse=True)
        latest_images = image_files[:SCREENSHOT_UPLOAD_AMOUNT]
        current_timestamp = int(time.time())
        # 如果图片数量为0，则等待5s再看
        if len(image_files) == 0:
            print("未检测到图片，5秒后重试。", IMAGE_DIR)
            time.sleep(5)
            continue

        image_messages = []
        for img_path in latest_images:
            try:
                with open(img_path, "rb") as f:
                    b64_img = base64.b64encode(f.read()).decode("utf-8")
                image_messages.append({
                    "type": "image_url",
                    "image_url": {"url": f"data:image/jpeg;base64,{b64_img}"}
                })
            except Exception as e:
                print(f"读取图片失败: {img_path}, {e}")

        # 2. 读取audio.txt
        audio_content = None
        if os.path.exists(AUDIO_TXT_PATH):
            try:
                with open(AUDIO_TXT_PATH, "r", encoding="utf-8") as f:
                    audio_content = "audio:" + f.read().strip()
            except Exception as e:
                print(f"读取audio.txt失败: {e}")

        # 3. 读取prompt.txt
        try:
            with open(PROMPT_PATH, "r", encoding="utf-8") as f:
                system_prompt = f.read().strip()
        except Exception as e:
            print(f"读取prompt.txt失败: {e}")
            system_prompt = ""

        # 4. 组装messages
        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        if audio_content:
            messages.append({"role": "user", "content": audio_content})
        if image_messages:
            messages.append({
                "role": "user",
                "content": image_messages
            })
        if not messages:
            print("没有可用的输入，跳过本次调用。")
            time.sleep(AI_TIME_INTERVAL)
            continue
        # INSERT_YOUR_CODE
        print("本次处理的图片路径:", latest_images)
        # 5. 调用OpenAI
        try:
            result = call_openai_api(messages)
            print("AI HTML结果:", result)
            # 6. 调用minimax
            if result.danmu_text != "":
                audio = t2a_minimax(result.danmu_text)
                with open(f"cache/voice/{current_timestamp}.mp3", "wb") as f:
                    f.write(audio)
                route = f"/voice/{current_timestamp}.mp3"
                print("minimax结果:", route)
            else:
                route = ""
            data = {
                "voice": "" if route == "" else f"{HOST_URL}{route}",
                "timestamp": current_timestamp,
                "html": result.html,
                "danmu_text": result.danmu_text,
                "height": result.height,
                "width": result.width
            }
            print("data:", data)
            with open("cache/status.json", "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=4)
            # INSERT_YOUR_CODE
            # 在 ./cache/html 里保存 .html，用timestamp命名
            html_dir = os.path.join(".", "cache", "html")
            os.makedirs(html_dir, exist_ok=True)
            timestamp = int(time.time())
            html_path = os.path.join(html_dir, f"{timestamp}.html")
            # result 可能是一个列表，每个元素是一个 dict，包含 html 字段
            # 只保存第一个 html 字段内容
            html_content = ""
            if isinstance(result, list) and result:
                html_content = result[0].get("html", "")
            elif isinstance(result, dict) and "html" in result:
                html_content = result["html"]
            with open(html_path, "w", encoding="utf-8") as f:
                f.write(html_content)
            print(f"HTML已保存到: {html_path}")
            # 识别完成后需要删除所有的图片
            if int(os.environ.get("DELETE_IMAGE_AFTER_PROCESS", 0)) == 1:
                for img_path in image_files:
                    try:
                        os.remove(img_path)
                    except Exception as e:
                        print(f"删除图片失败: {img_path}, {e}")
            # 清空audio.txt
            if os.path.exists(AUDIO_TXT_PATH):
                try:
                    with open(AUDIO_TXT_PATH, "w", encoding="utf-8") as f:
                        f.write("")
                except Exception as e:
                    print(f"删除audio.txt失败: {AUDIO_TXT_PATH}, {e}")
        except Exception as e:
            print("调用OpenAI失败:", e)
            traceback.print_exc()
        brain_loop = int(os.environ.get("BRAIN_LOOP", 0))
        if brain_loop == 1:
            time.sleep(AI_TIME_INTERVAL)
            continue
        else:
            break

if __name__ == "__main__":
    periodic_ai_task()
    # print(call_openai_api([
    #     {
    #         "role": "user",
    #         "content": "Hello, how are you?"
    #     }
    # ]))
