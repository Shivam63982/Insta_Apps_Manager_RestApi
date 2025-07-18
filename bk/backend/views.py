from django.http import HttpResponse, JsonResponse
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.contrib.auth import authenticate
from rest_framework.permissions import IsAuthenticated
from rest_framework.authentication import TokenAuthentication
from rest_framework.authtoken.models import Token
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
from .models import Employee, InstagramApp
from .serializers import EmployeeLoginSerializer, InstagramAppSerializer
import requests
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync
import os
import json
from datetime import datetime


# Webhook
VERIFY_TOKEN = "123"  # Use the same token in Meta Developer settings

@method_decorator(csrf_exempt, name='dispatch')
class WebhookView(APIView):
    def get(self, request):
        # Webhook verification
        mode = request.GET.get("hub.mode")
        token = request.GET.get("hub.verify_token")
        challenge = request.GET.get("hub.challenge")

        if mode == "subscribe" and token == VERIFY_TOKEN:
            print("✅ Webhook verified successfully")
            return HttpResponse(challenge)
        else:
            print("❌ Webhook verification failed")
            return HttpResponse("Invalid verification", status=403)

    def post(self, request):
        try:
            data = json.loads(request.body)
            print("📦 Webhook received:\n", json.dumps(data, indent=2))

            entries = data.get("entry", [])
            for entry in entries:
                changes = entry.get("changes", [])
                for change in changes:
                    value = change.get("value", {})
                    messaging = value.get("messaging", [])

                    for msg_event in messaging:
                        sender_id = msg_event.get("sender", {}).get("id")
                        message = msg_event.get("message", {})
                        message_text = message.get("text")
                        timestamp_unix = msg_event.get("timestamp")

                        if sender_id and message_text:
                            print(f"📨 WebSocket → {sender_id}: {message_text}")

                            # Convert UNIX timestamp to readable string
                            if timestamp_unix:
                                try:
                                    timestamp = datetime.utcfromtimestamp(int(timestamp_unix)).strftime('%Y-%m-%d %H:%M:%S')
                                except:
                                    timestamp = ""
                            else:
                                timestamp = ""

                            # Send to WebSocket group
                            channel_layer = get_channel_layer()
                            async_to_sync(channel_layer.group_send)(
                                f"chat_{sender_id}",
                                {
                                    "type": "chat_message",
                                    "message": message_text,
                                    "sender": "user"
                                }
                            )

                            # Save to JSON file
                            messages_dir = os.path.join(os.getcwd(), 'messages')
                            os.makedirs(messages_dir, exist_ok=True)
                            filename = os.path.join(messages_dir, f"messages_{sender_id}.json")

                            if os.path.exists(filename):
                                with open(filename, 'r') as f:
                                    messages = json.load(f)
                            else:
                                messages = []

                            messages.append({
                                "timestamp": timestamp,
                                "sender": "user",
                                "text": message_text.strip()
                            })

                            # Sort messages by timestamp if present
                            messages.sort(key=lambda x: x.get("timestamp", ""))

                            with open(filename, 'w') as f:
                                json.dump(messages, f, indent=4)

                            print(f"✅ Message saved to file: messages_{sender_id}.json")

            return HttpResponse(status=200)

        except Exception as e:
            print("❌ Webhook processing error:", str(e))
            return JsonResponse({"error": str(e)}, status=400)


# -------------------------------
# Login View
# -------------------------------
class LoginView(APIView):
    def post(self, request):
        serializer = EmployeeLoginSerializer(data=request.data)
        if serializer.is_valid():
            user = authenticate(
                employee_id=serializer.validated_data['employee_id'],
                password=serializer.validated_data['password']
            )
            if user:
                token, _ = Token.objects.get_or_create(user=user)
                return Response({'token': token.key}, status=200)
            return Response({'error': 'Invalid credentials'}, status=401)
        return Response(serializer.errors, status=400)


# -------------------------------
# Assigned Instagram Apps View
# -------------------------------
class AssignedAppsView(APIView):
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request):
        employee = request.user
        apps = employee.instagram_apps.all()  # only assigned apps
        serializer = InstagramAppSerializer(apps, many=True)
        return Response(serializer.data, status=200)

# ConversationApi View

class ConversationsView(APIView):
    def get(self, request):
        access_token = request.query_params.get("access_token")
        ig_user_id = request.query_params.get("ig_user_id")
        print(access_token)
        print(ig_user_id)
        if not access_token or not ig_user_id:
            return Response({"error": "Missing access_token or ig_user_id"}, status=400)

        url = f"https://graph.instagram.com/v23.0/me/conversations"
        params = {
            "platform": "instagram",
            "access_token": access_token,
            "fields": "id,participants,updated_time"
        }

        try:
            convo_response = requests.get(url, params=params)
            convo_data = convo_response.json()
            users = {}
            print(convo_response)
            print(convo_data)
            for convo in convo_data.get("data", []):
                participants = convo.get("participants", {}).get("data", [])

                for person in participants:
                    user_id = person.get("id")

                    if not user_id or user_id in users:
                        continue

                    try:
                        profile_url = f"https://graph.instagram.com/v23.0/{user_id}"
                        profile_payload = {
                            "fields": "username,name,profile_pic",
                            "access_token": access_token
                        }

                        profile_res = requests.get(profile_url, params=profile_payload)
                        profile_data = profile_res.json()

                        users[user_id] = {
                            "id": user_id,
                            "username": profile_data.get("username", f"user_{user_id[-4:]}").strip(),
                            "name": profile_data.get("name", "").strip(),
                            "profile_pic": profile_data.get("profile_picture_url") or profile_data.get("profile_pic", "")
                        }

                    except Exception as e:
                        print(f"⚠️ Failed to fetch profile for {user_id}:", e)
                        users[user_id] = {
                            "id": user_id,
                            "username": f"user_{user_id[-4:]}",
                            "name": "",
                            "profile_pic": ""
                        }

            return Response({"data": list(users.values())}, status=200)

        except Exception as e:
            print("⚠️ Failed to fetch conversations:", str(e))
            return Response({"error": str(e)}, status=500)






class FetchMessagesView(APIView):
    def get(self, request, user_id):
        access_token = request.query_params.get("access_token")
        ig_user_id = request.query_params.get("ig_user_id")

        if not access_token or not ig_user_id:
            return Response({"error": "Missing access_token or ig_user_id"}, status=400)

        try:
            print(f"▶️ Fetching messages for user: {user_id}")

            # Step 1: Fetch all conversation IDs
            url = "https://graph.instagram.com/v23.0/me/conversations"
            payload = {
                "access_token": access_token,
                "fields": "participants"
            }

            convo_response = requests.get(url, params=payload)
            data = convo_response.json()

            # Step 2: Find correct conversation ID
            convo_id = None
            for convo in data.get("data", []):
                participants = convo.get("participants", {}).get("data", [])
                for person in participants:
                    if person.get("id") == user_id:
                        convo_id = convo.get("id")
                        break
                if convo_id:
                    break

            if not convo_id:
                return Response({"error": "No conversation found for user"}, status=404)

            # Step 3: Fetch Messages
            msg_url = f"https://graph.instagram.com/v23.0/{convo_id}"
            msg_params = {
                "fields": "messages{id,created_time,from,to,message,is_unsupported}",
                "access_token": access_token
            }

            msg_response = requests.get(msg_url, params=msg_params)
            messages_data = msg_response.json()

            all_messages = []

            for msg in messages_data.get("messages", {}).get("data", []):
                from_id = msg.get("from", {}).get("id")
                to_data = msg.get("to", {}).get("data", [])
                to_ids = [t.get("id") for t in to_data]

                sender_type = "user" if from_id == user_id else "bot"

                all_messages.append({
                    "timestamp": msg.get("created_time"),
                    "sender": sender_type,
                    "text": msg.get("message", "").strip()
                })

            all_messages.sort(key=lambda x: x["timestamp"])

            # Save to JSON file
            messages_dir = os.path.join(os.getcwd(), 'messages')
            os.makedirs(messages_dir, exist_ok=True)
            filename = os.path.join(messages_dir, f"messages_{user_id}.json")
            try:
                with open(filename, "w") as f:
                    json.dump(all_messages, f, indent=4)
                print(f"✅ Saved messages to {filename}")
            except Exception as e:
                print(f"⚠️ Failed to save messages: {e}")

            return Response(all_messages, status=200)

        except Exception as e:
            print("❌ Exception while fetching messages:", e)
            return Response({"error": str(e)}, status=500)

class ChatHistoryView(APIView):
    def get(self, request, user_id):
        try:
            messages_dir = os.path.join(os.getcwd(), 'messages')
            filename = os.path.join(messages_dir, f"messages_{user_id}.json")

            if os.path.exists(filename):
                with open(filename, 'r') as f:
                    messages = json.load(f)
                return Response(messages, status=200)
            else:
                return Response([], status=200)

        except Exception as e:
            print("❌ Error reading saved messages:", e)
            return Response({"error": str(e)}, status=500)



# send message

class SendMessageView(APIView):
    def post(self, request):
        try:
            access_token = request.data.get("access_token")
            recipient_id = request.data.get("recipient_id")      # IG user ID (recipient)
            message_text = request.data.get("message")           # The message content

            print("🔐 access_token:", access_token)
            print("👤 recipient_id:", recipient_id)
            print("✉️ message_text:", message_text)

            if not all([access_token, recipient_id, message_text]):
                return Response({"error": "Missing required fields."}, status=400)

            # 🔁 Step 1: Send message to Instagram Graph API
            url = "https://graph.instagram.com/v23.0/me/messages"   # ✅ Correct Graph API endpoint for messaging
            headers = {
                "Authorization": f"Bearer {access_token}",
                "Content-Type": "application/json"
            }

            json_body = {
                "recipient": {
                    "id": recipient_id
                },
                "message": {
                    "text": message_text
                }
            }

            graph_response = requests.post(url, headers=headers, json=json_body)
            graph_result = graph_response.json()

            if graph_response.status_code != 200:
                print("❌ Graph API Error:", json.dumps(graph_result, indent=2))
                return Response({"error": graph_result}, status=500)

            # 📡 Step 2: Broadcast to WebSocket group for live update
            channel_layer = get_channel_layer()
            async_to_sync(channel_layer.group_send)(
                f"chat_{recipient_id}",
                {
                    "type": "chat_message",
                    "message": message_text,
                    "sender": "bot"
                }
            )

            return Response({
                "message": "Message sent successfully.",
                "graph_response": graph_result
            }, status=200)

        except Exception as e:
            print("❌ Exception in SendMessageView:", str(e))
            return Response({"error": str(e)}, status=500)

