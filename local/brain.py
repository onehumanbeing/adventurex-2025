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

# 添加LocalTracer导入
from local_tracer import get_tracer

# 获取全局追踪器实例
tracer = get_tracer("./cache/logs")

# 服务器主机URL，用于构建音频文件的完整路径
HOST_URL = "https://helped-monthly-alpaca.ngrok-free.app"

class HtmlView(BaseModel):
    """
    HTML视图数据模型
    用于定义AI返回的界面结构
    """
    height: int      # 界面高度
    width: int       # 界面宽度
    html: str        # HTML内容
    danmu_text: str  # 弹幕文本

def call_openai_api(messages, thread_id=None):
    """
    调用OpenAI API进行图像和语音分析
    
    Args:
        messages: 包含系统提示、用户语音和图像的消息列表
        thread_id: 线程ID，用于追踪对话
    
    Returns:
        HtmlView: 包含HTML界面和弹幕文本的响应对象
    """
    # 如果没有提供thread_id，生成一个基于时间的唯一ID
    if thread_id is None:
        thread_id = f"local_thread_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{uuid.uuid4().hex[:8]}"
    
    client = OpenAI(timeout=30.0)  # 设置30秒超时
    try:
        # 使用OpenAI的解析功能，直接返回HtmlView对象
        completion = client.beta.chat.completions.parse(
            model="gpt-4o-mini",
            messages=messages,
            response_format=HtmlView,
            max_tokens=10000
        )
        response = completion.choices[0].message.parsed
        
        # 记录对话到本地日志
        tracer.log_brain_conversation(
            thread_id=thread_id,
            messages=messages,
            result=response
        )
        
        return response
    except Exception as e:
        print(f"OpenAI API调用失败: {e}")
        # 返回默认响应，当API调用失败时显示错误提示
        return HtmlView(
            height=400,
            width=600,
            html="<div style='padding: 16px; background-color: white; border-radius: 16px; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1); color: #007aff;'><h2 style='font-size: 20px; font-weight: bold; margin-bottom: 8px;'>系统提示</h2><p style='margin-bottom: 16px;'>网络连接超时，请稍后重试。</p></div>",
            danmu_text="网络连接超时"
        )

def reset_status():
    """
    重置状态文件，设置默认的初始状态
    包含默认的音频、HTML界面和弹幕文本
    """
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
    """
    主要的AI任务循环函数
    负责持续监控图像和音频输入，调用AI进行分析，并更新状态
    """
    # 初始化状态
    reset_status()
    time.sleep(2)
    print("开始AI任务")
    
    # 从环境变量读取配置参数
    AI_TIME_INTERVAL = int(os.environ.get("AI_TIME_INTERVAL", 5))  # AI调用间隔时间
    SCREENSHOT_UPLOAD_AMOUNT = int(os.environ.get("SCREENSHOT_UPLOAD_AMOUNT", 1))  # 每次处理的图片数量
    USE_CAMERA = int(os.environ.get("USE_CAMERA", 0))  # 是否使用摄像头
    
    # 根据配置选择图片源目录
    if USE_CAMERA == 1:
        IMAGE_DIR = os.path.join(".", "cache", "camera")
    else:
        IMAGE_DIR = os.path.join(".", "cache", "screenshot")
    
    # 定义文件路径
    AUDIO_TXT_PATH = os.path.join(".", "cache", "audio", "audio.txt")  # 音频转文字结果文件
    PROMPT_PATH = os.path.join(".", "prompt.txt")  # 系统提示词文件

    while True:
        # 步骤1: 获取最新的图片文件
        image_files = glob.glob(os.path.join(IMAGE_DIR, "*"))
        image_files = [f for f in image_files if os.path.isfile(f)]  # 过滤掉目录
        image_files.sort(key=lambda x: os.path.getmtime(x), reverse=True)  # 按修改时间排序
        latest_images = image_files[:SCREENSHOT_UPLOAD_AMOUNT]  # 取最新的N张图片
        current_timestamp = int(time.time())
        
        # 如果没有图片，等待5秒后重试
        if len(image_files) == 0:
            print("未检测到图片，5秒后重试。", IMAGE_DIR)
            time.sleep(5)
            continue

        # 将图片转换为base64格式，准备发送给OpenAI
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

        # 步骤2: 读取音频转文字的结果
        audio_content = None
        if os.path.exists(AUDIO_TXT_PATH):
            try:
                with open(AUDIO_TXT_PATH, "r", encoding="utf-8") as f:
                    audio_content = "audio:" + f.read().strip()
            except Exception as e:
                print(f"读取audio.txt失败: {e}")

        # 步骤3: 读取系统提示词
        try:
            with open(PROMPT_PATH, "r", encoding="utf-8") as f:
                system_prompt = f.read().strip()
        except Exception as e:
            print(f"读取prompt.txt失败: {e}")
            system_prompt = ""

        # 步骤4: 组装发送给OpenAI的消息
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
        
        # 如果没有可用输入，跳过本次调用
        if not messages:
            print("没有可用的输入，跳过本次调用。")
            time.sleep(AI_TIME_INTERVAL)
            continue
        
        print("本次处理的图片路径:", latest_images)
        
        # 步骤5: 调用OpenAI API进行分析
        try:
            # 生成基于当前时间的thread_id
            current_thread_id = f"local_brain_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{uuid.uuid4().hex[:8]}"
            result = call_openai_api(messages, current_thread_id)
            print("AI HTML结果:", result)
            print(f"Thread ID: {current_thread_id}")
            
            # 记录更详细的对话信息
            tracer.log_brain_conversation(
                thread_id=current_thread_id,
                messages=messages,
                result=result,
                image_paths=latest_images,
                audio_content=audio_content
            )
            
            # 步骤6: 调用语音合成API生成音频
            if result.danmu_text != "":
                audio = t2a_minimax(result.danmu_text)
                # 保存音频文件
                with open(f"cache/voice/{current_timestamp}.mp3", "wb") as f:
                    f.write(audio)
                route = f"/voice/{current_timestamp}.mp3"
                print("minimax结果:", route)
            else:
                route = ""
            
            # 更新状态数据
            data = {
                "voice": "" if route == "" else f"{HOST_URL}{route}",
                "timestamp": current_timestamp,
                "html": result.html,
                "danmu_text": result.danmu_text,
                "height": result.height,
                "width": result.width
            }
            print("data:", data)
            
            # 保存状态到文件
            with open("cache/status.json", "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=4)
            # 保存HTML文件到缓存目录
            html_dir = os.path.join(".", "cache", "html")
            os.makedirs(html_dir, exist_ok=True)
            timestamp = int(time.time())
            html_path = os.path.join(html_dir, f"{timestamp}.html")
            
            # 提取HTML内容（处理不同的返回格式）
            html_content = ""
            if isinstance(result, list) and result:
                html_content = result[0].get("html", "")
            elif isinstance(result, dict) and "html" in result:
                html_content = result["html"]
            else:
                html_content = result.html  # 直接访问HtmlView对象的属性
            
            with open(html_path, "w", encoding="utf-8") as f:
                f.write(html_content)
            print(f"HTML已保存到: {html_path}")
            
            # 处理完成后清理文件
            # 根据配置决定是否删除处理过的图片
            if int(os.environ.get("DELETE_IMAGE_AFTER_PROCESS", 0)) == 1:
                for img_path in image_files:
                    try:
                        os.remove(img_path)
                    except Exception as e:
                        print(f"删除图片失败: {img_path}, {e}")
            
            # 清空音频转文字文件
            if os.path.exists(AUDIO_TXT_PATH):
                try:
                    with open(AUDIO_TXT_PATH, "w", encoding="utf-8") as f:
                        f.write("")
                except Exception as e:
                    print(f"删除audio.txt失败: {AUDIO_TXT_PATH}, {e}")
        except Exception as e:
            print("调用OpenAI失败:", e)
            traceback.print_exc()
        
        # 根据配置决定是否继续循环
        brain_loop = int(os.environ.get("BRAIN_LOOP", 0))
        if brain_loop == 1:
            time.sleep(AI_TIME_INTERVAL)
            continue
        else:
            break

if __name__ == "__main__":
    # 启动AI任务
    periodic_ai_task()
    
    # 测试代码（已注释）
    # print(call_openai_api([
    #     {
    #         "role": "user",
    #         "content": "Hello, how are you?"
    #     }
    # ]))
