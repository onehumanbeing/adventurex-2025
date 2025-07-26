import os
import time
import datetime
import subprocess

def screenshot_display(display_index: int, filename: str):
    """
    截取指定显示器的屏幕
    
    Args:
        display_index (int): 显示器索引（从1开始）
        filename (str): 保存的文件路径
    """
    try:
        # 使用macOS的screencapture命令截图
        # -x: 不播放快门声
        # -D: 指定显示器
        subprocess.run(["screencapture", "-x", "-D", str(display_index), filename], check=True)
        print(f"Display {display_index} 截图保存至: {os.path.abspath(filename)}")
    except subprocess.CalledProcessError as e:
        print(f"截图失败: {e}")

def get_display_count():
    """
    获取系统中显示器的数量
    
    Returns:
        int: 显示器数量（包括镜像显示器）
    """
    result = subprocess.run(["system_profiler", "SPDisplaysDataType"], stdout=subprocess.PIPE, text=True)
    return result.stdout.count("Resolution")

def continuous_screenshot(duration_sec=10, interval_sec=1):
    """
    连续截取所有显示器的屏幕
    
    Args:
        duration_sec (int): 截图持续时间（秒），目前未使用
        interval_sec (int): 截图间隔时间（秒）
    """
    from PIL import Image

    # 创建截图输出目录
    output_dir = os.path.abspath(os.path.join(".", "cache", "screenshot"))
    os.makedirs(output_dir, exist_ok=True)

    display_count = get_display_count()
    print(f"检测到 {display_count} 个显示器（包括镜像）")

    while True:
        # 生成时间戳用于文件名
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        
        # 为每个显示器截图
        for display_index in range(1, display_count + 1):
            filename = f"screenshot_d{display_index}_{timestamp}.png"
            filepath = os.path.join(output_dir, filename)
            screenshot_display(display_index, filepath)

            # 缩小图片尺寸为原来的1/4以节省存储空间
            try:
                with Image.open(filepath) as img:
                    new_size = (img.width // 4, img.height // 4)
                    img_resized = img.resize(new_size, Image.LANCZOS)
                    img_resized.save(filepath, optimize=True)
                    print(f"已缩放并保存: {filepath} ({new_size[0]}x{new_size[1]})")
            except Exception as e:
                print(f"缩放图片失败: {filepath}, 错误: {e}")

        time.sleep(interval_sec)

def camera_capture(filename: str):
    """
    使用摄像头拍照
    
    Args:
        filename (str): 保存的文件路径
    """
    try:
        # 使用imagesnap命令拍照（需要安装：brew install imagesnap）
        subprocess.run(["imagesnap", filename], check=True)
        print(f"摄像头拍照保存至: {os.path.abspath(filename)}")
    except subprocess.CalledProcessError as e:
        print(f"摄像头拍照失败: {e}")

def continuous_camera_capture(duration_sec=10, interval_sec=1):
    """
    连续使用摄像头拍照
    
    Args:
        duration_sec (int): 拍照持续时间（秒），目前未使用
        interval_sec (int): 拍照间隔时间（秒）
    """
    # 创建摄像头照片输出目录
    output_dir = os.path.abspath(os.path.join(".", "cache", "camera"))
    os.makedirs(output_dir, exist_ok=True)

    while True:
        # 生成时间戳用于文件名
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        filename = f"camera_{timestamp}.jpg"
        filepath = os.path.join(output_dir, filename)
        camera_capture(filepath)
        time.sleep(interval_sec)

if __name__ == "__main__":
    # 从环境变量读取配置参数
    SCREENSHOT_INTERVAL = int(os.environ.get("SCREENSHOT_INTERVAL", 1))  # 截图间隔时间
    USE_CAMERA = int(os.environ.get("USE_CAMERA", 0))  # 是否使用摄像头
    SCREENSHOT_DURATION = int(os.environ.get("SCREENSHOT_DURATION", 10))  # 截图持续时间
    
    # 等待5秒后开始，避免与其他进程冲突
    try:
        if USE_CAMERA == 1:
            continuous_camera_capture(duration_sec=SCREENSHOT_DURATION, interval_sec=SCREENSHOT_INTERVAL)
        else:
            continuous_screenshot(duration_sec=SCREENSHOT_DURATION, interval_sec=SCREENSHOT_INTERVAL)
    except KeyboardInterrupt:
        print("截图进程被中断")
    except Exception as e:
        print(f"截图进程出错: {e}")
