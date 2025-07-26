import subprocess
import sys
import os
import time
import threading

# 定义不同脚本对应的颜色
SCRIPT_COLORS = {
    "brain.py": "\033[96m",      # 青色
    "listener.py": "\033[92m",   # 绿色
    "screenshot.py": "\033[93m", # 黄色
    "transcribe.py": "\033[95m", # 紫色
    "detector.py": "\033[94m",   # 蓝色
}
RESET_COLOR = "\033[0m"

# 注释掉log捕获的逻辑以提升性能
# def stream_subprocess_output(process, name):
#     # 选择颜色
#     color = SCRIPT_COLORS.get(name, "\033[97m")  # 默认白色
#     def stream(pipe, prefix):
#         for line in iter(pipe.readline, b''):
#             try:
#                 print(f"{color}[{name}] {line.decode(errors='replace')}{RESET_COLOR}", end='', flush=True)
#             except Exception as e:
#                 print(f"{color}[{name}] (decode error) {line!r}{RESET_COLOR}", flush=True)
#         pipe.close()
#     threading.Thread(target=stream, args=(process.stdout, "stdout"), daemon=True).start()
#     threading.Thread(target=stream, args=(process.stderr, "stderr"), daemon=True).start()

def run_script(script_name):
    # 直接继承父进程的输出，提升性能
    return subprocess.Popen(
        [sys.executable, script_name],
        # stdout=subprocess.PIPE,
        # stderr=subprocess.PIPE,
        # bufsize=1
    )

if __name__ == "__main__":
    base_dir = os.path.dirname(os.path.abspath(__file__))
    scripts = [
        "brain.py",
        "listener.py",
        "screenshot.py",
        "transcribe.py",
        "detector.py"
    ]
    processes = []
    for script in scripts:
        script_path = os.path.join(base_dir, script)
        if not os.path.exists(script_path):
            print(f"未找到脚本: {script_path}")
            continue
        print(f"{SCRIPT_COLORS.get(script, '')}启动: {script_path}{RESET_COLOR}")
        p = run_script(script_path)
        # stream_subprocess_output(p, script)  # 注释掉log捕获
        processes.append(p)
        time.sleep(0.5)  # 避免同时启动导致资源冲突

    try:
        # 等待所有子进程结束
        for p in processes:
            p.wait()
    except KeyboardInterrupt:
        print("\033[91m检测到中断，正在终止所有子进程...\033[0m")
        for p in processes:
            try:
                p.terminate()
                # 给进程5秒时间优雅退出
                p.wait(timeout=5)
            except subprocess.TimeoutExpired:
                print(f"\033[93m进程 {p.pid} 未响应，强制终止...\033[0m")
                p.kill()
                p.wait()
            except Exception as e:
                print(f"\033[93m终止进程时出错: {e}\033[0m")
        print("\033[91m所有子进程已终止。\033[0m")
