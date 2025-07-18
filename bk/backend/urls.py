"""
URL configuration for backend project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path
from .views import LoginView, AssignedAppsView , ConversationsView , FetchMessagesView , ChatHistoryView, WebhookView, SendMessageView

urlpatterns = [
    path('webhook/', WebhookView.as_view(), name='webhook'),
    path('admin/', admin.site.urls),
    path('api/login/', LoginView.as_view(), name='login'),
    path('api/assigned-apps/', AssignedAppsView.as_view(), name='assigned-apps'),
    path('api/conversations/', ConversationsView.as_view(), name='conversations'),
    path('api/fetch_messages/<str:user_id>/', FetchMessagesView.as_view(), name='fetch_messages'),
    path('api/chat-history/<str:user_id>/', ChatHistoryView.as_view(), name='chat-history'),
        path('api/send_message/', SendMessageView.as_view(), name='send_message'), 

]
