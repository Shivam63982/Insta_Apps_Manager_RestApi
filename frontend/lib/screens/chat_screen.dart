import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  final String userId;
  final String accessToken;
  final String igUserId;

  const ChatScreen({
    super.key,
    required this.userId,
    required this.accessToken,
    required this.igUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late WebSocketChannel _channel;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    debugPrint("🚀 Initializing chat for user: ${widget.userId}");
    _loadChatHistory().then((_) => _connectWebSocket());
  }

  Future<void> _loadChatHistory() async {
    final url = Uri.parse(
      'https://8000-shivam63982-instaappsma-ubki0pugw8g.ws-us120.gitpod.io/api/fetch_messages/${widget.userId}/?access_token=${widget.accessToken}&ig_user_id=${widget.igUserId}',
    );

    try {
      final response = await http.get(url);
      debugPrint("📦 Fetching chat history: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> history = jsonDecode(response.body);
        debugPrint("📚 Loaded ${history.length} previous messages");

        setState(() {
          _messages.addAll(history.cast<Map<String, dynamic>>().map(_normalizeMessage));
        });

        _scrollToBottom();
      } else {
        debugPrint("❌ Error fetching messages: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Exception loading history: $e");
    }
  }

  void _connectWebSocket() {
    final uri = 'wss://8000-shivam63982-instaappsma-ubki0pugw8g.ws-us120.gitpod.io/ws/chat/${widget.userId}/';
    debugPrint("🔌 Connecting WebSocket to $uri");

    _channel = WebSocketChannel.connect(Uri.parse(uri));

    _channel.stream.listen(
      (data) {
        debugPrint("📨 WebSocket received: $data");

        try {
          final decoded = jsonDecode(data);
          final message = _normalizeMessage(decoded);

          if ((message['text'] as String).trim().isEmpty) {
            debugPrint("⚠️ Skipping empty message bubble");
            return;
          }

          setState(() {
            _messages.add(message);
          });

          _scrollToBottom();
        } catch (e) {
          debugPrint("❌ Error decoding WebSocket message: $e");
        }
      },
      onError: (err) => debugPrint("❌ WebSocket error: $err"),
      onDone: () => debugPrint("🛑 WebSocket connection closed."),
    );
  }

  Map<String, dynamic> _normalizeMessage(dynamic raw) {
    try {
      final sender = raw['sender'] ?? 'user';
      final text = (raw['text'] ?? raw['message'] ?? '').toString();
      return {'sender': sender, 'text': text};
    } catch (_) {
      return {'sender': 'unknown', 'text': ''};
    }
  }

  void _sendMessage() async {
    final rawMessage = _messageController.text.trim();
    if (rawMessage.isEmpty) return;

    final sendUrl = Uri.parse(
      'https://8000-shivam63982-instaappsma-ubki0pugw8g.ws-us120.gitpod.io/api/send_message/',
    );

    final body = {
      "access_token": widget.accessToken,
      "recipient_id": widget.userId,
      "message": rawMessage,
    };

    try {
      final response = await http.post(
        sendUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        debugPrint("✅ Message sent to backend: $rawMessage");
        // Do NOT add message here to avoid duplication — WebSocket will handle it
      } else {
        debugPrint("❌ Backend send failed: ${response.statusCode}, ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Exception sending message: $e");
    }

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final bool isBot = message['sender'] == 'bot';
    final alignment = isBot ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isBot ? Colors.deepPurple : Colors.grey.shade300;
    final textColor = isBot ? Colors.white : Colors.black87;

    final rawText = message['text'];
    if (rawText == null || rawText.toString().trim().isEmpty) {
      debugPrint("⚠️ Skipping render of blank message: $message");
      return const SizedBox.shrink();
    }

    String decodedText = rawText.toString();
    try {
      final bytes = latin1.encode(decodedText);
      decodedText = utf8.decode(bytes, allowMalformed: true);
    } catch (e) {
      debugPrint("⚠️ Failed to decode message text: $e");
    }

    return Align(
      alignment: alignment,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          decodedText,
          style: TextStyle(color: textColor),
        ),
      ),
    );
  }

  @override
  void dispose() {
    debugPrint("🧹 Disposing ChatScreen resources...");
    _channel.sink.close();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    final double contentWidth = isWideScreen ? 520.0 : double.infinity;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: contentWidth),
            decoration: const BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: AppBar(
              backgroundColor: Colors.deepPurple,
              automaticallyImplyLeading: true,
              centerTitle: true,
              title: const Text("Chat"),
            ),
          ),
        ),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: contentWidth),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(_messages[index]);
                  },
                ),
              ),
              const Divider(height: 1),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: "Type a message...",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.deepPurple),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
