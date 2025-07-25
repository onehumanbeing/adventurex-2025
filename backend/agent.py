from pydantic import BaseModel
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

# Call Schema 

class HtmlView(BaseModel):
    x: int
    y: int
    height: int
    width: int
    html: str

class ViewRender(BaseModel): 
    views: list[HtmlView]

def call_openai_api(messages):
    client = OpenAI()
    completion = client.beta.chat.completions.parse(
        model="gpt-4o-mini",
        messages=messages,
        response_format=ViewRender,
    )
    response = completion.choices[0].message.parsed
    return [{"x": view.x, "y": view.y, "height": view.height, "width": view.width, "html": view.html} for view in response.views]
    
if __name__ == "__main__":
    print(gpt_4o_mini([
        {
            "role": "user",
            "content": "Hello, how are you?"
        }
    ]))
