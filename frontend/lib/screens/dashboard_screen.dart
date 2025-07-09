import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'conversations_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> _apps = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchInstagramApps();
  }

  Future<void> _fetchInstagramApps() async {
    final apps = await ApiService.getInstagramApps();

    if (apps.length == 1) {
      final app = apps.first;
      final accessToken = app['access_token'];
      final igUserId = app['app_id'];

      if (accessToken != null && igUserId != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationsScreen(
              accessToken: accessToken,
              igUserId: igUserId,
            ),
          ),
        );
        return;
      }
    }

    setState(() {
      _apps = apps;
      _loading = false;
    });
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            child: const Text('Yes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  Widget _buildAppCard(Map<String, dynamic> app, int index) {
    return GestureDetector(
      onTap: () {
        final accessToken = app['access_token'];
        final igUserId = app['app_id'];

        if (accessToken == null || igUserId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Missing access token or app ID.")),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationsScreen(
              accessToken: accessToken,
              igUserId: igUserId,
            ),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${index + 1}.',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app['name'] ?? 'Unnamed App',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "App ID: ${app['app_id']}",
                      style: const TextStyle(color: Colors.grey),
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 600;
        final contentWidth = isWideScreen ? 520.0 : double.infinity;

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
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
        backgroundColor: Colors.deepPurple,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          "Connected Instagram Apps",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: _confirmLogout,
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
      color: const Color(0xFFF7F7F7), // subtle light grey background
      borderRadius: BorderRadius.circular(12),
    ),
    child: _loading
        ? const Center(child: CircularProgressIndicator())
        : _apps.isEmpty
            ? const Center(child: Text("No Instagram apps found."))
            : ListView.builder(
                itemCount: _apps.length,
                itemBuilder: (context, index) {
                  return _buildAppCard(_apps[index], index);
                },
              ),
  ),
),

        );
      },
    );
  }
}
