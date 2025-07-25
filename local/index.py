import subprocess
import sys
import os
import time
import threading

def stream_subprocess_output(process, name):
    # 实时读取子进程的stdout和stderr并打印
    def stream(pipe, prefix):
        for line in iter(pipe.readline, b''):
            try:
                print(f"[{name}] {line.decode(errors='replace')}", end='', flush=True)
            except Exception as e:
                print(f"[{name}] (decode error) {line!r}", flush=True)
        pipe.close()
    threading.Thread(target=stream, args=(process.stdout, "stdout"), daemon=True).start()
    threading.Thread(target=stream, args=(process.stderr, "stderr"), daemon=True).start()

def run_script(script_name):
    # 确保使用与当前解释器相同的python，并捕获输出
    return subprocess.Popen(
        [sys.executable, script_name],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        bufsize=1
    )

if __name__ == "__main__":
    base_dir = os.path.dirname(os.path.abspath(__file__))
    scripts = [
        "brain.py",
        "listener.py",
        "screenshot.py",
        "transcribe.py"
    ]
    processes = []
    for script in scripts:
        script_path = os.path.join(base_dir, script)
        if not os.path.exists(script_path):
            print(f"未找到脚本: {script_path}")
            continue
        print(f"启动: {script_path}")
        p = run_script(script_path)
        stream_subprocess_output(p, script)
        processes.append(p)
        time.sleep(0.5)  # 避免同时启动导致资源冲突

    try:
        # 等待所有子进程结束
        for p in processes:
            p.wait()
    except KeyboardInterrupt:
        print("检测到中断，正在终止所有子进程...")
        for p in processes:
            p.terminate()
        for p in processes:
            p.wait()
        print("所有子进程已终止。")
