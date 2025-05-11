import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'signup_page.dart';
import 'crud_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _loginError = '';
  bool _isLoading = false;

  void _login() async {
    setState(() {
      _isLoading = true;
      _loginError = '';
    });
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _isLoading = false;
        _loginError = 'Please enter both username/email and password.';
      });
      return;
    }

    try {
      final user = ParseUser(username, password, null); // Email is username here
      final ParseResponse response = await user.login();
      if (response.success && response.result != null) {
        setState(() {
          _isLoading = false;
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CrudPage()),
        );
      } else {
        setState(() {
          _isLoading = false;
          _loginError = 'Login failed. Invalid username/email or password: ${response.error?.message ?? 'Unknown error'}';
        });
      }
    } on ParseError catch (error) {
      setState(() {
        _isLoading = false;
        _loginError = 'Login failed: ${error.message}';
      });
    }
  }

  void _navigateToSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignupPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: _usernameController,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: 'Username/Email',
                ),
              ),
              const SizedBox(height: 20.0),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                ),
              ),
              const SizedBox(height: 30.0),
              if (_loginError.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Text(
                    _loginError,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: Text(_isLoading ? 'Logging in...' : 'Login'),
              ),
              const SizedBox(height: 10.0),
              TextButton(
                onPressed: _navigateToSignup,
                child: const Text('Don\'t have an account? Sign up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}