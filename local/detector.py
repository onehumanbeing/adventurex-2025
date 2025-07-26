import cv2
import numpy as np
import os
import time
import datetime
import json
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import threading
from typing import List, Optional

def update_status_json(qr_content: str):
    """
    更新status.json文件，添加二维码相关信息
    
    Args:
        qr_content: 二维码内容（链接）
    """
    try:
        status_file = os.path.join(".", "cache", "status.json")
        
        # 读取现有的status.json
        if os.path.exists(status_file):
            with open(status_file, 'r', encoding='utf-8') as f:
                status_data = json.load(f)
        else:
            # 如果文件不存在，创建默认结构
            status_data = {
                "voice": "",
                "timestamp": 0,
                "html": "",
                "danmu_text": "",
                "height": 400,
                "width": 600
            }
        
        # 更新action和value字段，更新时间戳
        status_data["action"] = "qr"
        status_data["value"] = qr_content
        status_data["voice"] = 'https://helped-monthly-alpaca.ngrok-free.app/voice/qr.mp3'
        status_data["timestamp"] = int(time.time())
        if isinstance(qr_content, str) and qr_content.startswith("inj"):
            status_data["action"] = "inj"
            status_data["value"] = "https://testnet.explorer.injective.network/transaction/0x9de12fcb7b270a23074371150cf96bf5de3efda70f6077e7d71c2f7dce2b42ef/"
            status_data["voice"] = 'https://helped-monthly-alpaca.ngrok-free.app/voice/transfer.mp3'
            status_data["timestamp"] = int(time.time())
            status_data["danmu_text"] = "识别到钱包地址二维码，正在转账中"
        # 如果是 https 链接，获取网页内容并用 GPT 总结
        elif isinstance(qr_content, str) and qr_content.startswith("https://"):
            try:
                print(f"获取网页内容: {qr_content}")
                import requests
                from openai import OpenAI

                # 获取网页内容
                resp = requests.get(qr_content, timeout=5)
                html_text = resp.text

                # 只取前4096字符，避免太长
                # html_text = html_text[:4096]

                # 构造 prompt
                prompt = [
                    {
                        "role": "system",
                        "content": "你是一个网页摘要助手，请用中文50字以内总结用户提供的网页内容。你不可以使用专业的计算机网络术语，以对待用户方式回答。如果没有有意义的内容，你可以回复 无摘要 "
                    },
                    {
                        "role": "user",
                        "content": f"请总结以下网页内容：\n{html_text}"
                    }
                ]

                # 调用 OpenAI GPT-4o
                client = OpenAI(timeout=20.0)
                completion = client.chat.completions.create(
                    model="gpt-4o",
                    messages=prompt,
                    max_tokens=10000,
                )
                summary = completion.choices[0].message.content.strip()
                if summary:
                    status_data["danmu_text"] = summary
                    print(f"GPT总结: {summary}")
            except Exception as e:
                print(f"获取网页内容或GPT总结失败: {e}")
        # 保存更新后的文件
        with open(status_file, 'w', encoding='utf-8') as f:
            json.dump(status_data, f, ensure_ascii=False, indent=4)
        
        print(f"已更新status.json，添加二维码链接: {qr_content}")
        
    except Exception as e:
        print(f"更新status.json时出错: {e}")

def detect_qr_codes(image_path: str) -> List[str]:
    """
    检测图片中的二维码并返回识别到的内容列表
    
    Args:
        image_path: 图片文件路径
        
    Returns:
        包含所有识别到的二维码内容的列表
    """
    try:
        # 读取图片
        image = cv2.imread(image_path)
        if image is None:
            print(f"无法读取图片: {image_path}")
            return []
        
        # 创建QR码检测器
        qr_detector = cv2.QRCodeDetector()
        
        # 检测QR码
        data, bbox, straight_qrcode = qr_detector.detectAndDecode(image)
        
        qr_contents = []
        if data:
            qr_contents.append(data)
            print(f"检测到 QR码: {data}")
            # 更新status.json
            update_status_json(data)
        
        # 如果第一次检测失败，尝试对图像进行预处理
        if not qr_contents:
            # 转换为灰度图
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
            
            # 尝试检测
            data, bbox, straight_qrcode = qr_detector.detectAndDecode(gray)
            if data:
                qr_contents.append(data)
                print(f"检测到 QR码 (灰度图): {data}")
                # 更新status.json
                update_status_json(data)
        
        # 如果还是失败，尝试调整图像大小
        if not qr_contents:
            # 放大图像
            height, width = image.shape[:2]
            scale = 2.0
            new_width = int(width * scale)
            new_height = int(height * scale)
            resized = cv2.resize(image, (new_width, new_height), interpolation=cv2.INTER_CUBIC)
            
            data, bbox, straight_qrcode = qr_detector.detectAndDecode(resized)
            if data:
                qr_contents.append(data)
                print(f"检测到 QR码 (放大图): {data}")
                # 更新status.json
                update_status_json(data)
        
        return qr_contents
        
    except Exception as e:
        print(f"检测二维码时出错: {e}")
        return []

def analyze_image(image_path: str) -> bool:
    """
    分析图片中的二维码
    
    Args:
        image_path: 图片文件路径
        
    Returns:
        是否检测到二维码
    """
    qr_contents = detect_qr_codes(image_path)
    if qr_contents:
        print(f"在图片 {os.path.basename(image_path)} 中检测到 {len(qr_contents)} 个二维码:")
        for i, content in enumerate(qr_contents, 1):
            print(f"  二维码 {i}: {content}")
            
        return True
    else:
        print(f"图片 {os.path.basename(image_path)} 中未检测到二维码")
        return False

class ScreenshotHandler(FileSystemEventHandler):
    """监控screenshot目录的文件变化"""
    
    def __init__(self, screenshot_dir: str):
        self.screenshot_dir = screenshot_dir
        # processed_files: 记录已处理文件的 (文件路径, 最后修改时间戳)
        self.processed_files = dict()  # file_path -> mtime
        self.lock = threading.Lock()
        
    def on_created(self, event):
        """当新文件创建时触发"""
        if not event.is_directory:
            file_path = event.src_path
            if file_path.lower().endswith(('.png', '.jpg', '.jpeg')):
                # 延迟一点时间确保文件写入完成
                threading.Timer(1.0, self.process_new_image, args=[file_path]).start()
    
    def process_new_image(self, file_path: str):
        """处理新创建的图片文件"""
        with self.lock:
            try:
                if not os.path.exists(file_path):
                    return
                mtime = os.path.getmtime(file_path)
                # 如果已经处理过该文件的该mtime，则跳过
                if file_path in self.processed_files and self.processed_files[file_path] == mtime:
                    return

                file_size = os.path.getsize(file_path)
                time.sleep(0.5)  # 等待文件写入完成
                new_size = os.path.getsize(file_path)
                
                if file_size == new_size and file_size > 0:
                    self.processed_files[file_path] = mtime
                    print(f"\n{'='*50}")
                    print(f"检测到新图片: {os.path.basename(file_path)}")
                    print(f"时间: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
                    print(f"文件大小: {file_size} bytes")
                    print(f"{'='*50}")
                    
                    # 分析图片中的二维码
                    analyze_image(file_path)
                    print(f"{'='*50}\n")
                else:
                    # 文件还在写入中，稍后重试
                    threading.Timer(2.0, self.process_new_image, args=[file_path]).start()
                    
            except Exception as e:
                print(f"处理图片文件时出错: {e}")

def monitor_screenshots(screenshot_dir: str, check_interval: int = 1):
    """
    监控screenshot目录的新图片
    
    Args:
        screenshot_dir: screenshot目录路径
        check_interval: 检查间隔（秒）
    """
    print(f"开始监控screenshot目录: {screenshot_dir}")
    print(f"检查间隔: {check_interval} 秒")
    print("按 Ctrl+C 停止监控\n")
    
    # 确保目录存在
    os.makedirs(screenshot_dir, exist_ok=True)
    
    # 创建事件处理器
    event_handler = ScreenshotHandler(screenshot_dir)
    
    # 创建观察者
    observer = Observer()
    observer.schedule(event_handler, screenshot_dir, recursive=False)
    observer.start()
    
    try:
        while True:
            time.sleep(check_interval)
    except KeyboardInterrupt:
        print("\n停止监控...")
        observer.stop()
    
    observer.join()

def process_existing_images(screenshot_dir: str, processed_files: Optional[dict] = None):
    """处理目录中已存在的图片文件（只处理未处理过的）"""
    print(f"处理已存在的图片文件...")
    
    if not os.path.exists(screenshot_dir):
        print(f"目录不存在: {screenshot_dir}")
        return
    
    image_extensions = ('.png', '.jpg', '.jpeg')
    processed_count = 0
    if processed_files is None:
        processed_files = dict()
    
    for filename in os.listdir(screenshot_dir):
        if filename.lower().endswith(image_extensions):
            file_path = os.path.join(screenshot_dir, filename)
            try:
                mtime = os.path.getmtime(file_path)
                # 跳过已处理过的文件（通过mtime判断）
                if file_path in processed_files and processed_files[file_path] == mtime:
                    continue
                print(f"\n处理已存在的图片: {filename}")
                analyze_image(file_path)
                processed_files[file_path] = mtime
                processed_count += 1
            except Exception as e:
                print(f"处理图片 {filename} 时出错: {e}")
    
    if processed_count > 0:
        print(f"\n处理了 {processed_count} 个已存在的图片文件")
    else:
        print("没有找到未处理的已存在图片文件")

if __name__ == "__main__":
    # 从环境变量读取配置
    USE_CAMERA = int(os.environ.get("USE_CAMERA", 0))
    SCREENSHOT_INTERVAL = int(os.environ.get("SCREENSHOT_INTERVAL", 1))
    
    # 根据USE_CAMERA决定监控目录
    if USE_CAMERA == 1:
        IMAGE_DIR = os.path.join(".", "cache", "camera")
    else:
        IMAGE_DIR = os.path.join(".", "cache", "screenshot")
    
    print(f"USE_CAMERA: {USE_CAMERA}")
    print(f"SCREENSHOT_INTERVAL: {SCREENSHOT_INTERVAL}")
    print(f"监控目录: {IMAGE_DIR}")
    
    # 开始监控
    monitor_screenshots(IMAGE_DIR, SCREENSHOT_INTERVAL)
