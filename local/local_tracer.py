import json
import os
import time
from datetime import datetime
from uuid import uuid4


class LocalTracer:
    """
    简单的本地对话追踪器
    专门为 NoNoMi 项目设计，不使用 LangChain
    """
    
    def __init__(self, storage_path: str = "./cache/logs"):
        """
        初始化追踪器
        
        Args:
            storage_path: 日志存储路径
        """
        self.storage_path = os.path.abspath(storage_path)
        self._ensure_storage_dir()
        print(f"LocalTracer 初始化完成，日志目录: {self.storage_path}")
    
    def _ensure_storage_dir(self):
        """确保存储目录存在"""
        os.makedirs(self.storage_path, exist_ok=True)
    
    def log_conversation(self, thread_id: str, messages: list, response: dict, metadata: dict = None):
        """
        记录完整的对话
        
        Args:
            thread_id: 线程ID
            messages: 发送给OpenAI的消息列表
            response: OpenAI的响应
            metadata: 额外的元数据
        """
        try:
            # 生成日志文件名
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            log_id = f"{timestamp}_{uuid4().hex[:8]}"
            
            # 创建线程目录
            thread_dir = os.path.join(self.storage_path, thread_id)
            os.makedirs(thread_dir, exist_ok=True)
            
            # 日志文件路径
            log_file = os.path.join(thread_dir, f"{log_id}.json")
            
            # 构建日志数据
            log_data = {
                "thread_id": thread_id,
                "timestamp": timestamp,
                "log_id": log_id,
                "request": {
                    "messages": messages,
                    "model": "gpt-4o-mini"
                },
                "response": {
                    "content": response.get("content", ""),
                    "role": response.get("role", "assistant"),
                    "model": "gpt-4o-mini"
                },
                "metadata": metadata or {}
            }
            
            # 保存日志
            with open(log_file, 'w', encoding='utf-8') as f:
                json.dump(log_data, f, indent=2, ensure_ascii=False)
            
            print(f"✅ 对话已记录: {log_file}")
            return log_file
            
        except Exception as e:
            print(f"❌ 记录对话失败: {e}")
            return None
    
    def log_brain_conversation(self, thread_id: str, messages: list, result: object, image_paths: list = None, audio_content: str = None):
        """
        专门为 brain.py 设计的对话记录方法
        
        Args:
            thread_id: 线程ID
            messages: 发送给OpenAI的消息列表
            result: brain.py 的返回结果（HtmlView对象）
            image_paths: 处理的图片路径列表
            audio_content: 音频转文字内容
        """
        try:
            # 生成日志文件名
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            log_id = f"{timestamp}_{uuid4().hex[:8]}"
            
            # 创建线程目录
            thread_dir = os.path.join(self.storage_path, thread_id)
            os.makedirs(thread_dir, exist_ok=True)
            
            # 日志文件路径
            log_file = os.path.join(thread_dir, f"{log_id}.json")
            
            # 构建日志数据
            log_data = {
                "thread_id": thread_id,
                "timestamp": timestamp,
                "log_id": log_id,
                "request": {
                    "messages": messages,
                    "model": "gpt-4o-mini",
                    "image_paths": image_paths or [],
                    "audio_content": audio_content
                },
                "response": {
                    "html": getattr(result, 'html', ''),
                    "danmu_text": getattr(result, 'danmu_text', ''),
                    "height": getattr(result, 'height', 0),
                    "width": getattr(result, 'width', 0),
                    "model": "gpt-4o-mini"
                },
                "metadata": {
                    "source": "brain.py",
                    "processing_time": timestamp
                }
            }
            
            # 保存日志
            with open(log_file, 'w', encoding='utf-8') as f:
                json.dump(log_data, f, indent=2, ensure_ascii=False)
            
            print(f"✅ Brain对话已记录: {log_file}")
            return log_file
            
        except Exception as e:
            print(f"❌ 记录Brain对话失败: {e}")
            return None
    
    def get_thread_logs(self, thread_id: str):
        """
        获取指定线程的所有日志
        
        Args:
            thread_id: 线程ID
            
        Returns:
            list: 日志文件路径列表
        """
        thread_dir = os.path.join(self.storage_path, thread_id)
        if not os.path.exists(thread_dir):
            return []
        
        log_files = []
        for file in os.listdir(thread_dir):
            if file.endswith('.json'):
                log_files.append(os.path.join(thread_dir, file))
        
        return sorted(log_files)
    
    def read_log(self, log_file: str):
        """
        读取指定的日志文件
        
        Args:
            log_file: 日志文件路径
            
        Returns:
            dict: 日志数据
        """
        try:
            with open(log_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            print(f"❌ 读取日志失败: {e}")
            return None
    
    def list_threads(self):
        """
        列出所有线程ID
        
        Returns:
            list: 线程ID列表
        """
        if not os.path.exists(self.storage_path):
            return []
        
        threads = []
        for item in os.listdir(self.storage_path):
            item_path = os.path.join(self.storage_path, item)
            if os.path.isdir(item_path):
                threads.append(item)
        
        return sorted(threads)
    
    def get_stats(self):
        """
        获取统计信息
        
        Returns:
            dict: 统计信息
        """
        threads = self.list_threads()
        total_logs = 0
        
        for thread_id in threads:
            log_files = self.get_thread_logs(thread_id)
            total_logs += len(log_files)
        
        return {
            "total_threads": len(threads),
            "total_logs": total_logs,
            "storage_path": self.storage_path
        }


# 全局实例
_tracer_instance = None

def get_tracer(storage_path: str = "./cache/logs"):
    """
    获取全局追踪器实例
    
    Args:
        storage_path: 日志存储路径
        
    Returns:
        LocalTracer: 追踪器实例
    """
    global _tracer_instance
    if _tracer_instance is None:
        _tracer_instance = LocalTracer(storage_path)
    return _tracer_instance
