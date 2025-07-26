from pydantic import BaseModel
from openai import OpenAI
import traceback
import os
import time
import base64
import json
import glob
import uuid
from datetime import datetime
from generate_audio import t2a_minimax

from local_tracer import get_tracer

tracer = get_tracer("./cache/logs")

HOST_URL = "https://helped-monthly-alpaca.ngrok-free.app"

class HtmlView(BaseModel):
    height: int
    width: int
    html: str
    danmu_text: str

class isFinished(BaseModel):
    result: bool

def call_openai_api(messages, thread_id=None, response_format=HtmlView, model="gpt-4o-mini", max_tokens=2000):
    """
    调用OpenAI API进行图像和语音分析
    Args:
        messages: 消息列表
        thread_id: 线程ID
        response_format: 返回格式
        model: 使用的模型
        max_tokens: 最大token数，默认2000
    Returns:
        (response, err): 响应对象和错误（如有）
    """
    if thread_id is None:
        thread_id = f"local_thread_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{uuid.uuid4().hex[:8]}"
    
    client = OpenAI(timeout=30.0)
    try:
        if response_format == "text":
            completion = client.chat.completions.create(
                model=model,
                messages=messages,
                max_tokens=max_tokens
            )
            response = completion.choices[0].message.content
        else:
            completion = client.beta.chat.completions.parse(
                model=model,
                messages=messages,
                response_format=response_format,
                max_tokens=max_tokens
            )
            response = completion.choices[0].message.parsed
        tracer.log_brain_conversation(
            thread_id=thread_id,
            messages=messages,
            result=response
        )
        return response, None
    except Exception as e:
        print(f"OpenAI API调用失败: {e}")
        if response_format == "text":
            return "", e
        return HtmlView(
            height=400,
            width=600,
            html="<div style='padding: 16px; background-color: white; border-radius: 16px; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1); color: #007aff;'><h2 style='font-size: 20px; font-weight: bold; margin-bottom: 8px;'>系统提示</h2><p style='margin-bottom: 16px;'>网络连接超时，请稍后重试。</p></div>",
            danmu_text="网络连接超时"
        ), e

def update_status_json(fields: dict):
    status_path = "cache/status.json"
    if os.path.exists(status_path):
        try:
            with open(status_path, "r", encoding="utf-8") as f:
                data = json.load(f)
        except Exception as e:
            print(f"读取status.json失败: {e}")
            data = {}
    else:
        data = {}
    data.update(fields)
    print("update_status_json:", data)
    with open(status_path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=4)

def reset_status():
    data = {
        "action": "render",
        "value": "",
        "voice": "https://helped-monthly-alpaca.ngrok-free.app/voice/hello.mp3",
        "timestamp": int(time.time()),
        "html": "<div style='height: 100%; width: 100%; padding: 16px; background-color: white; border-radius: 16px; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1); color: #007aff;'><h2 style='font-size: 20px; font-weight: bold; margin-bottom: 8px;'>时尚提示</h2><p style='margin-bottom: 16px;'>您对这件衣服感兴趣，请确认价格以便购买！</p><div style='margin-top: 16px;'><button style='background-color: #007aff; color: white; padding: 10px 20px; border-radius: 12px; border: none; cursor: pointer;'>查询价格</button></div></div>",
        "danmu_text": "QAQ",
        "height": 400,
        "width": 600
    }
    update_status_json(data)

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
    PROMPT_IMAGE_PATH = os.path.join(".", "prompt_image.txt")
    PROMPT_FINISHED_PATH = os.path.join(".", "prompt_finished.txt")

    while True:
        current_timestamp = int(time.time())

        # 步骤1: 检查音频内容并判断是否需要触发AI回复
        audio_content = None
        if os.path.exists(AUDIO_TXT_PATH):
            try:
                with open(AUDIO_TXT_PATH, "r", encoding="utf-8") as f:
                    audio_content = f.read().strip()
            except Exception as e:
                print(f"读取audio.txt失败: {e}")

        if not audio_content:
            print("未检测到音频内容，5秒后重试。")
            time.sleep(5)
            continue

        # 使用isFinished模型判断是否需要触发AI回复
        try:
            with open(PROMPT_FINISHED_PATH, "r", encoding="utf-8") as f:
                finished_prompt = f.read().strip()
        except Exception as e:
            print(f"读取prompt_finished.txt失败: {e}")
            finished_prompt = ""

        if finished_prompt:
            finished_messages = [
                {"role": "system", "content": finished_prompt},
                {"role": "user", "content": audio_content}
            ]
            print("开始判断是否需要触发AI回复", audio_content)
            try:
                finished_result, finished_err = call_openai_api(
                    finished_messages,
                    response_format=isFinished,
                    model="gpt-4o-mini",
                    max_tokens=50  # isFinished只需要返回布尔值，50个token足够
                )
                if finished_err is not None:
                    print("判断请求异常:", finished_err)
                    time.sleep(AI_TIME_INTERVAL)
                    continue
                
                if not finished_result.result:
                    print("❌音频内容不需要触发AI回复，跳过本次处理")
                    # 检查如果audio.txt的行数大于10行，则清空
                    if os.path.exists(AUDIO_TXT_PATH):
                        with open(AUDIO_TXT_PATH, "r", encoding="utf-8") as f:
                            lines = f.readlines()
                            if len(lines) > 10:
                                with open(AUDIO_TXT_PATH, "w", encoding="utf-8") as f:
                                    f.write("")
                    time.sleep(3)
                    continue
                print("✅音频内容需要触发AI回复，继续处理")
                # 清空音频文件
                try:
                    with open(AUDIO_TXT_PATH, "w", encoding="utf-8") as f:
                        f.write("")
                except Exception as e:
                    print(f"清空audio.txt失败: {e}")
                time.sleep(AI_TIME_INTERVAL)
                update_status_json({
                    "action": "pending",
                    "voice": "https://helped-monthly-alpaca.ngrok-free.app/voice/pending.mp3",
                    "timestamp": int(time.time()),
                })
            except Exception as e:
                print(f"判断请求异常: {e}")
                time.sleep(AI_TIME_INTERVAL)
                continue
        else:
            print("缺少finished prompt，跳过判断步骤")

        # 步骤2: 如果有图片，则获取图片数量并且解析
        image_files = glob.glob(os.path.join(IMAGE_DIR, "*"))
        image_files = [f for f in image_files if os.path.isfile(f)]
        image_files.sort(key=lambda x: os.path.getmtime(x), reverse=True)
        latest_images = image_files[:SCREENSHOT_UPLOAD_AMOUNT]

        image_messages = []
        if len(image_files) > 0:
            print(f"检测到 {len(image_files)} 张图片，开始处理")
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
        else:
            print("未检测到图片，跳过图片处理步骤")

        try:
            with open(PROMPT_PATH, "r", encoding="utf-8") as f:
                system_prompt = f.read().strip()
        except Exception as e:
            print(f"读取prompt.txt失败: {e}")
            system_prompt = ""

        try:
            with open(PROMPT_IMAGE_PATH, "r", encoding="utf-8") as f:
                prompt_image = f.read().strip()
        except Exception as e:
            print(f"读取prompt_image.txt失败: {e}")
            prompt_image = ""

        screen_description = None
        image_analysis_error = False
        t1 = time.time()
        if prompt_image and image_messages:
            image_analysis_messages = [
                {"role": "system", "content": prompt_image},
                {"role": "user", "content": image_messages},
                {"role": "user", "content": f"audio: {audio_content}"}
            ]
            print("开始图片细节分析请求", latest_images, audio_content)
            try:
                response, err = call_openai_api(
                    image_analysis_messages,
                    response_format="text",
                    max_tokens=500  # 图片分析文本，通常500个token足够描述图片
                )
                t2 = time.time()
                print("✅ 图片细节分析结果:", response)
                print(f"图片细节分析耗时: {t2-t1:.2f}秒")
                if err is not None:
                    print("图片细节分析请求异常:", err)
                    image_analysis_error = True
                elif isinstance(response, str):
                    screen_description = response
                elif hasattr(response, "content"):
                    screen_description = getattr(response, "content", None)
                else:
                    screen_description = str(response)
            except Exception as e:
                t2 = time.time()
                print(f"图片细节分析请求异常: {e}")
                print(f"图片细节分析耗时: {t2-t1:.2f}秒")
                image_analysis_error = True
        else:
            t2 = time.time()
            print("未能进行图片细节分析（缺少prompt_image或图片）")
            image_analysis_error = True

        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        
        # 添加音频内容（格式化为audio:前缀）
        if audio_content:
            messages.append({"role": "user", "content": f"audio: {audio_content}"})
        
        # 如果有图片分析结果，添加到消息中
        if not image_analysis_error and screen_description:
            messages.append({"role": "user", "content": f"screen_description: {screen_description}"})
        else:
            print("图片分析失败，不传递图片信息给主请求。")
        
        if not messages:
            print("没有可用的输入，跳过本次调用。")
            time.sleep(AI_TIME_INTERVAL)
            continue
        print("本次处理的图片路径:", latest_images)
        t3 = time.time()
        try:
            # 生成基于当前时间的thread_id
            current_thread_id = f"local_brain_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{uuid.uuid4().hex[:8]}"
            result, err = call_openai_api(messages, thread_id=current_thread_id, max_tokens=2000)  # HtmlRender主请求，需要更多token来生成HTML和弹幕
            t4 = time.time()
            print(f"✅ 主请求耗时: {t4-t3:.2f}秒")
            print("✅ AI HTML结果:", result)
            print(f"Thread ID: {current_thread_id}")
            # tracer.log_brain_conversation(
            #     thread_id=current_thread_id,
            #     messages=messages,
            #     result=result,
            #     image_paths=latest_images,
            #     audio_content=f"audio: {audio_content}" if audio_content else None
            # )
            if hasattr(result, "danmu_text") and result.danmu_text != "":
                audio = t2a_minimax(result.danmu_text)
                with open(f"cache/voice/{current_timestamp}.mp3", "wb") as f:
                    f.write(audio)
                route = f"/voice/{current_timestamp}.mp3"
                print("minimax结果:", route)
            else:
                route = ""

            data = {
                "voice": "" if route == "" else f"{HOST_URL}{route}",
                "timestamp": int(time.time()),
                "html": getattr(result, "html", ""),
                "danmu_text": getattr(result, "danmu_text", ""),
                "height": getattr(result, "height", 400),
                "width": getattr(result, "width", 600),
                "action": "render",
                "value": ""
            }
            print("data:", data)
            update_status_json(data)

            html_dir = os.path.join(".", "cache", "html")
            os.makedirs(html_dir, exist_ok=True)
            timestamp = int(time.time())
            html_path = os.path.join(html_dir, f"{timestamp}.html")
            html_content = ""
            if isinstance(result, list) and result:
                html_content = result[0].get("html", "")
            elif isinstance(result, dict) and "html" in result:
                html_content = result["html"]
            elif hasattr(result, "html"):
                html_content = result.html
            with open(html_path, "w", encoding="utf-8") as f:
                f.write(html_content)
            print(f"HTML已保存到: {html_path}")

            if int(os.environ.get("DELETE_IMAGE_AFTER_PROCESS", 0)) == 1:
                for img_path in image_files:
                    try:
                        os.remove(img_path)
                    except Exception as e:
                        print(f"删除图片失败: {img_path}, {e}")

            if os.path.exists(AUDIO_TXT_PATH):
                try:
                    with open(AUDIO_TXT_PATH, "w", encoding="utf-8") as f:
                        f.write("")
                except Exception as e:
                    print(f"删除audio.txt失败: {AUDIO_TXT_PATH}, {e}")
        except Exception as e:
            t4 = time.time()
            print(f"主请求异常: {e}")
            print(f"主请求耗时: {t4-t3:.2f}秒")
            traceback.print_exc()

        brain_loop = int(os.environ.get("BRAIN_LOOP", 0))
        if brain_loop == 1:
            time.sleep(AI_TIME_INTERVAL)
            continue
        else:
            break

if __name__ == "__main__":
    periodic_ai_task()
