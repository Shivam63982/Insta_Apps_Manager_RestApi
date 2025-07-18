from channels.generic.websocket import AsyncWebsocketConsumer
import json

class ChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.user_id = self.scope['url_route']['kwargs']['user_id']
        self.room_group_name = f"chat_{self.user_id}"

        # Join the WebSocket group for this user
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )

        await self.accept()
        print(f"[WebSocket] Connected to room: {self.room_group_name}")

    async def disconnect(self, close_code):
        # Leave the WebSocket group
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )
        print(f"[WebSocket] Disconnected from room: {self.room_group_name}")

    # 📨 Message received from Flutter client via WebSocket
    async def receive(self, text_data):
        data = json.loads(text_data)
        message = data.get('message', '')

        print(f"[WebSocket] Received from client: {message}")

        # Forward the message to all group members (echoing to same client + others)
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'chat_message',
                'message': message,
                'sender': 'bot'  # This sender name helps frontend UI
            }
        )

    # 🟢 This is triggered when something (e.g., webhook) sends to the group
    async def chat_message(self, event):
        message = event['message']
        sender = event.get('sender', 'user')  # Default to 'user'

        print(f"[WebSocket] Broadcasting message: {message} from {sender}")

        await self.send(text_data=json.dumps({
            'message': message,
            'sender': sender
        }))
