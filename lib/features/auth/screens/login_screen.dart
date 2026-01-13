import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isSigningIn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shield_outlined,
              size: 80,
              color: Colors.indigoAccent,
            ),
            const SizedBox(height: 20),
            const Text(
              "Welcome Back!",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),

            // Email
            _buildTextField("Email", false, _emailController),
            const SizedBox(height: 16),

            // Password
            _buildTextField("Password", true, _passwordController),
            const SizedBox(height: 24),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),

            // Login button
            ElevatedButton(
              onPressed: _isSigningIn
                  ? null
                  : () async {
                      setState(() => _isSigningIn = true);
                      final result = await AuthService().login(
                        _emailController.text.trim(),
                        _passwordController.text.trim(),
                      );
                      setState(() => _isSigningIn = false);
                      if (result.user != null) {
                        if (mounted) {
                          Navigator.pushReplacementNamed(context, "/home");
                        }
                      } else {
                        setState(() {
                          _errorMessage = result.error ?? "Login failed";
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 100,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSigningIn
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),

            const SizedBox(height: 24),

            // Divider
            _divider(),

            const SizedBox(height: 16),

            // Google Sign-In button
            _googleButton(() async {
              if (_isSigningIn) return;
              setState(() => _isSigningIn = true);
              final user = await AuthService().signInWithGoogle();
              setState(() => _isSigningIn = false);
              if (user != null) {
                if (mounted) {
                  Navigator.pushReplacementNamed(context, "/home");
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Google Sign-In failed")),
                  );
                }
              }
            }, isSigningIn: _isSigningIn),

            const SizedBox(height: 16),

            // Sign up redirect
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                );
              },
              child: const Text(
                "Don’t have an account? Sign up",
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildTextField(
    String hint,
    bool obscure,
    TextEditingController controller,
  ) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  static Widget _divider() {
    return Row(
      children: const [
        Expanded(child: Divider(color: Colors.white54)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            "OR",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
        Expanded(child: Divider(color: Colors.white54)),
      ],
    );
  }

  static Widget _googleButton(VoidCallback onTap, {required bool isSigningIn}) {
    return ElevatedButton.icon(
      onPressed: isSigningIn ? null : onTap,
      icon: isSigningIn
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 2,
              ),
            )
          : Image.network(
              "https://developers.google.com/identity/images/g-logo.png",
              height: 20,
            ),
      label: isSigningIn
          ? const Text(
              "Signing in...",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            )
          : const Text(
              "Continue with Google",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
