import requests
from django.shortcuts import render
from django.http import JsonResponse
import json
from django.views.decorators.csrf import csrf_exempt

OLLAMA_URL = "http://localhost:11434/api/generate"

from django.shortcuts import render

@csrf_exempt
def reset_chat(request):
    if request.method == 'POST':
        request.session['chat_history'] = []
        print("🧹 Chat history cleared.")
        return JsonResponse({"status": "ok"})
    return JsonResponse({"status": "invalid"}, status=405)

def index(request):
    # Load previous session history to render chat visually
    history = request.session.get('chat_history', [])
    return render(request, 'chat/index.html', {'chat_history': history})

def chat(request):
    if request.method == 'POST':
        data = json.loads(request.body)
        user_input = data.get('message', '')
        print(f"🟡 Received input: {user_input}")

        history = request.session.get('chat_history', [])
        history.append({"role": "user", "content": user_input})

        # Construct the full prompt
        prompt = ""
        for turn in history:
            prefix = "User" if turn["role"] == "user" else "AI"
            prompt += f"{prefix}: {turn['content']}\n"

        payload = {
            "model": "llama3.1",
            "prompt": prompt + "AI:",
            "stream": False
        }

        try:
            res = requests.post(OLLAMA_URL, json=payload)
            reply = res.json().get('response', '⚠️ AI didn’t respond.')
            print(f"🤖 AI: {reply}")
            history.append({"role": "ai", "content": reply})
            request.session['chat_history'] = history

        except Exception as e:
            reply = f"❌ Error: {str(e)}"
            print("🚨 Ollama API error:", e)

        return JsonResponse({'reply': reply})
