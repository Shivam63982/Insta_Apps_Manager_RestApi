import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _conversations = data.values.toList();
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
      });
      debugPrint('Error: ${response.statusCode} - ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
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
              automaticallyImplyLeading: true,
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
          constraints: const BoxConstraints(maxWidth: 520),
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
                  : ListView.builder(
                      itemCount: _conversations.length,
                      itemBuilder: (context, index) {
                        final user = _conversations[index];
                        return ListTile(
                          title: Text(user['name'] ?? user['username']),
                          subtitle: Text('@${user['username']}'),
                          leading: CircleAvatar(
                            backgroundImage: user['profile_pic'] != null
                                ? NetworkImage(user['profile_pic'])
                                : null,
                            child: user['profile_pic'] == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          onTap: () {
                            debugPrint("Tapped on ${user['username']}");
                          },
                        );
                      },
                    ),
        ),
      ),
    );
  }
}
