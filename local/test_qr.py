#!/usr/bin/env python3
"""
测试二维码检测功能
"""

import os
import json
import time
from detector import analyze_image

def main():
    print("🧪 测试二维码检测功能")
    print("=" * 50)
    
    # 测试图片路径
    test_image = "./cache/screenshot/wechat_2025-07-26_123030_818.png"
    
    if not os.path.exists(test_image):
        print(f"❌ 测试图片不存在: {test_image}")
        return
    
    print(f"📸 检测图片: {os.path.basename(test_image)}")
    
    # 读取测试前的status.json
    status_file = "./cache/status.json"
    old_timestamp = None
    if os.path.exists(status_file):
        with open(status_file, 'r', encoding='utf-8') as f:
            old_data = json.load(f)
            old_timestamp = old_data.get('timestamp')
        print(f"📊 测试前timestamp: {old_timestamp}")
    
    # 执行二维码检测
    print("\n🔍 开始检测二维码...")
    result = analyze_image(test_image)
    
    # 等待文件写入
    time.sleep(1)
    
    # 检查更新后的status.json
    if os.path.exists(status_file):
        with open(status_file, 'r', encoding='utf-8') as f:
            new_data = json.load(f)
        
        new_timestamp = new_data.get('timestamp')
        action = new_data.get('action')
        value = new_data.get('value')
        
        print(f"\n📊 测试后status.json:")
        print(f"  timestamp: {new_timestamp}")
        print(f"  action: {action}")
        print(f"  value: {value}")
        
        # 验证结果
        if action == 'qr' and value and new_timestamp != old_timestamp:
            print("\n✅ 测试成功！")
            print(f"   - 检测到二维码链接: {value}")
            print(f"   - status.json已更新")
            print(f"   - timestamp已更新: {old_timestamp} -> {new_timestamp}")
        else:
            print("\n❌ 测试失败！")
            if action != 'qr':
                print("   - action字段不正确")
            if not value:
                print("   - value字段为空")
            if new_timestamp == old_timestamp:
                print("   - timestamp未更新")
    else:
        print("\n❌ status.json文件不存在")

if __name__ == "__main__":
    main() 