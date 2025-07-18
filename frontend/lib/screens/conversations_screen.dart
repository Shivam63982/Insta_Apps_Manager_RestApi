import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  final String accessToken;
  final String igUserId;

  const ConversationsScreen({
    super.key,
    required this.accessToken,
    required this.igUserId,
  });

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<dynamic> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    final uri = Uri.parse(
      'https://8000-shivam63982-instaappsma-ubki0pugw8g.ws-us120.gitpod.io/api/conversations/?access_token=${widget.accessToken}&ig_user_id=${widget.igUserId}',
    );

    try {
      final response = await http.get(uri);
      debugPrint('Fetching Conversations for App ID: ${widget.igUserId}');
      debugPrint('Access Token: ${widget.accessToken}');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Raw Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data.containsKey('data') && data['data'] is List) {
          setState(() {
            _conversations = data['data'];
            _loading = false;
          });
        } else {
          debugPrint('Unexpected response structure or missing "data" key.');
          setState(() {
            _conversations = [];
            _loading = false;
          });
        }
      } else {
        debugPrint('Error ${response.statusCode}: ${response.body}');
        setState(() {
          _conversations = [];
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Exception occurred while fetching conversations: $e');
      setState(() {
        _conversations = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    final contentWidth = isWideScreen ? 520.0 : double.infinity;

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
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                )
              ],
            ),
            child: AppBar(
              backgroundColor: Colors.deepPurple,
              centerTitle: true,
              title: const Text("Conversations"),
              actions: [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'switch_account') {
                      Navigator.pushReplacementNamed(context, '/dashboard');
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem<String>(
                      value: 'switch_account',
                      child: Text('Switch Account'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: contentWidth),
          margin: const EdgeInsets.only(top: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _loading
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        "Trying connecting to app...",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : _conversations.isEmpty
                  ? const Center(child: Text("No conversations found."))
                  : ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: _conversations.length,
                      separatorBuilder: (_, __) => const Divider(height: 8),
                      itemBuilder: (context, index) {
                        final user = _conversations[index];
                        final String userId = user['id']?.toString() ?? '';
                        final String username = user['username']?.toString() ?? '';
                        final String name = user['name']?.toString() ?? '';
                        final String profilePic = user['profile_pic']?.toString() ?? '';

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Text(name.isNotEmpty ? name : username),
                          subtitle: Text('@$username'),
                          leading: CircleAvatar(
                            backgroundImage: profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
                            child: profilePic.isEmpty ? const Icon(Icons.person) : null,
                          ),
                          onTap: () {
                              final String userId = user['id']?.toString() ?? '';
  debugPrint('➡️ Navigating to ChatScreen');
  debugPrint('🔸 userId: $userId');
  debugPrint('🔸 accessToken: ${widget.accessToken}');
  debugPrint('🔸 igUserId: ${widget.igUserId}');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  userId: userId,
                                  accessToken: widget.accessToken,
                                  igUserId: widget.igUserId,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
        ),
      ),
    );
  }
}
