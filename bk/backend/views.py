from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.contrib.auth import authenticate
from rest_framework.permissions import IsAuthenticated
from rest_framework.authentication import TokenAuthentication
from rest_framework.authtoken.models import Token
import json
from .models import Employee, InstagramApp
from .serializers import EmployeeLoginSerializer, InstagramAppSerializer
import requests


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
