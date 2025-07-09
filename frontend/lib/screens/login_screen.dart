import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _employeeIdController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  String _error = '';

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    final employeeId = int.tryParse(_employeeIdController.text.trim());
    final password = _passwordController.text.trim();

    if (employeeId == null || password.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Please enter valid credentials.';
      });
      return;
    }

    final token = await ApiService.login(employeeId, password);

    setState(() => _loading = false);

    if (token != null) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      setState(() => _error = 'Login failed. Check credentials.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 600;
          final contentWidth = isWideScreen ? 400.0 : double.infinity;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/insta_logo.png',
                      height: 100,
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _employeeIdController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Employee ID',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_error.isNotEmpty)
                      Text(
                        _error,
                        style: const TextStyle(color: Colors.red),
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '© ${DateTime.now().year} Insta App Manager',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
