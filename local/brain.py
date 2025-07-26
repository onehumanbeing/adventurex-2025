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
        "html": """
<div
  style="
    height: 100%;
    width: 100%;
    background: #232323;
    display: flex;
    align-items: center;
    justify-content: center;
  "
>
  <div
    style="
      background: linear-gradient(90deg, #6ec1e4 0%, #a259c6 50%, #ff6a3d 100%);
      border-radius: 60px;
      padding: 6px;
      display: flex;
      align-items: center;
      justify-content: center;
      min-width: 480px;
      min-height: 480px;
      width: 540px;
      height: 540px;
      max-width: 90vw;
      max-height: 90vh;
      box-shadow: 0 4px 32px rgba(0, 0, 0, 0.4);
    "
  >
    <div
      style="
        background: #232323;
        border-radius: 54px;
        width: 100%;
        height: 100%;
        display: flex;
        flex-direction: column;
        overflow: hidden;
      "
    >
      <div style="padding: 40px 40px 0 40px">
        <div
          id="title"
          style="
            font-size: 56px;
            font-weight: 700;
            color: #98f7b3;
            font-family: sans-serif;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 70px;
          "
        ></div>
      </div>
      <div
        style="
          flex: 1;
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
        "
      >
        <div
          id="desc"
          style="
            font-size: 32px;
            font-weight: 700;
            color: #fff;
            font-family: sans-serif;
            text-shadow: 0 2px 8px #000;
            text-align: center;
            min-height: 80px;
            display: flex;
            align-items: center;
            justify-content: center;
          "
        ></div>
        <div
          id="sub-desc"
          style="
            font-size: 24px;
            font-weight: 600;
            color: #ccc;
            font-family: sans-serif;
            text-shadow: 0 2px 8px #000;
            text-align: center;
            min-height: 40px;
            display: flex;
            align-items: center;
            justify-content: center;
            margin-top: 8px;
          "
        ></div>
      </div>
      <div
        style="
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 0 32px 24px 32px;
        "
      >
        <div>
          <div style="color: #aaa; font-size: 15px; margin-bottom: 8px">
            Searched On
          </div>
          <div style="display: flex; gap: 10px">
            <a
              href="#"
              style="
                background: #232b3e;
                color: #fff;
                border-radius: 8px;
                padding: 6px 14px;
                display: inline-flex;
                align-items: center;
                font-size: 15px;
                text-decoration: none;
              "
              ><span style="margin-right: 6px">🅑</span>Behance</a
            >
            <a
              href="#"
              style="
                background: #1a2634;
                color: #fff;
                border-radius: 8px;
                padding: 6px 14px;
                display: inline-flex;
                align-items: center;
                font-size: 15px;
                text-decoration: none;
              "
              ><span style="margin-right: 6px">in</span>Linkedin</a
            >
            <a
              href="#"
              style="
                background: #ea4c89;
                color: #fff;
                border-radius: 8px;
                padding: 6px 14px;
                display: inline-flex;
                align-items: center;
                font-size: 15px;
                text-decoration: none;
              "
              ><span style="margin-right: 6px">🏀</span>Dribbble</a
            >
            <a
              href="#"
              style="
                background: #1da1f2;
                color: #fff;
                border-radius: 8px;
                padding: 6px 14px;
                display: inline-flex;
                align-items: center;
                font-size: 15px;
                text-decoration: none;
              "
              ><span style="margin-right: 6px">🐦</span>Twitter</a
            >
          </div>
        </div>
        <div style="align-self: flex-end">
          <div style="display: flex; flex-direction: column; align-items: center;">
            <div style="width: 48px; height: 48px; background: #fff; border-radius: 50%; display: flex; align-items: center; justify-content: center;">
              <span style="font-size: 32px;">🎧</span>
            </div>
            <div style="color: #fff; font-size: 18px; font-weight: 700; margin-top: 4px; font-family: sans-serif;">NoNomi AI Assistant</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>

<div style="text-align: center; margin-top: 20px;">
  <a href="https://www.xiaohongshu.com/user/profile/620103f00000000021029b87?xsec_token=YBwTrdN0RlEzIjqWDoW7NrR9KQeXLfFH4_64sZWEgYH1g=&xsec_source=app_share&xhsshare=CopyLink&appuid=620103f00000000021029b87&apptime=1753543002&share_id=4ed639c86e0a451dad4f0e5a53ea7688" target="_blank" style="background: linear-gradient(45deg, #69bff9, #b96af3, #e9685e, #f2ac3e); background-size: 400% 100%; color: white; border: none; border-radius: 8px; padding: 10px 28px; font-size: 16px; cursor: pointer; text-decoration: none; display: inline-block; animation: rainbow 4s ease-in-out infinite; transition: transform 0.25s cubic-bezier(0.4, 2, 0.6, 1), box-shadow 0.25s; box-shadow: 0 2px 8px 0 #b96af377;">Link主创</a>
</div>
      </div>
    </div>
  </div>
</div>

<script>
// 流式文字更新函数
function updateText(elementId, newText, animationType = 'fadeIn') {
  const element = document.getElementById(elementId);
  if (element) {
    // 移除之前的动画类
    element.classList.remove('typing-cursor', 'text-glow', 'text-bounce');
    
    // 根据动画类型应用不同的效果
    switch(animationType) {
      case 'typewriter':
        typewriterEffect(element, newText);
        break;
      case 'bounce':
        bounceEffect(element, newText);
        break;
      case 'glow':
        glowEffect(element, newText);
        break;
      case 'fadeIn':
      default:
        fadeInEffect(element, newText);
        break;
    }
  }
}

// 打字机效果
function typewriterEffect(element, text) {
  element.textContent = '';
  element.classList.add('typing-cursor');
  let index = 0;
  
  function type() {
    if (index < text.length) {
      element.textContent += text.charAt(index);
      index++;
      setTimeout(type, 100);
    } else {
      element.classList.remove('typing-cursor');
    }
  }
  type();
}

// 弹跳效果
function bounceEffect(element, text) {
  element.style.animation = 'none';
  element.offsetHeight; // 触发重排
  element.innerHTML = text;
  element.style.animation = 'textBounce 0.8s ease-out';
}

// 发光效果
function glowEffect(element, text) {
  element.innerHTML = text;
  element.classList.add('text-glow');
  setTimeout(() => {
    element.classList.remove('text-glow');
  }, 2000);
}

// 淡入效果
function fadeInEffect(element, text) {
  element.style.animation = 'none';
  element.offsetHeight; // 触发重排
  element.innerHTML = text;
  element.style.animation = 'textFadeIn 0.6s ease-out';
}

// 初始化文字
updateText('title', 'Hello!', 'bounce');
updateText('desc', '正在为您分析当前场景信息', 'fadeIn');
updateText('sub-desc', '构建AGI森林🌳', 'fadeIn');

// 模拟流式更新 - 使用不同动画效果
setTimeout(() => {
  updateText('desc', '创造力是智慧在玩耍', 'typewriter');
}, 3000);

setTimeout(() => {
  updateText('desc', '生活不是寻找自己，而是创造自己', 'bounce');
}, 8000);

setTimeout(() => {
  updateText('title', 'NoNomi', 'glow');
  updateText('desc', '激发创造 • 丰富生活', 'fadeIn');
  updateText('sub-desc', '构建AGI森林🌳', 'fadeIn');
}, 12000);
</script>
""",
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
