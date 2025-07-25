import os
from openai import OpenAI
import traceback

def gpt_4o_mini(messages):
    # 参考 https://openai.com/api/pricing/
    """
    messages=[
        {
            "role": "user",
            "content": [
                {"type": "text", "text": "Your text / prompt here"},
                {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{base64_image}"}}
            ],
        }
    ]
    """
    client = OpenAI()
    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=messages,
            # max_tokens=10
        )
        # gpt-4o-mini
        # $0.150 / 1M input tokens
        # $0.600 / 1M output tokens
        reply = response.choices[0].message.content.strip()
        estimated_cost = (response.usage.prompt_tokens / 1000000) * 0.150 + (response.usage.completion_tokens / 1000000) * 0.600
        return {
            "status": 0,
            "result": reply,
            "estimated_cost": estimated_cost
        }
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            "status": -1,
            "result": traceback.format_exc(),
            "estimated_cost": 0
        }
    
if __name__ == "__main__":
    print(gpt_4o_mini([
        {
            "role": "user",
            "content": "Hello, how are you?"
        }
    ]))
