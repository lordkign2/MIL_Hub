import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _errorMessage;
  bool _isSigningUp = false; // Add this flag

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF16213E), Color(0xFF1A1A2E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_add, size: 80, color: Colors.indigoAccent),
            const SizedBox(height: 20),
            const Text(
              "Create Account",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),

            _buildTextField("Full Name", false, _nameController),
            const SizedBox(height: 16),

            _buildTextField("Email", false, _emailController),
            const SizedBox(height: 16),

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

            ElevatedButton(
              onPressed: _isSigningUp
                  ? null
                  : () async {
                      setState(() => _isSigningUp = true);
                      final result = await AuthService().signUp(
                        _emailController.text.trim(),
                        _passwordController.text.trim(),
                      );
                      setState(() => _isSigningUp = false);
                      if (result.user != null) {
                        Navigator.pushReplacementNamed(context, "/home");
                      } else {
                        setState(() {
                          _errorMessage = result.error ?? "Signup failed";
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 80,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSigningUp
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "Sign Up",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),

            const SizedBox(height: 24),

            _divider(),

            const SizedBox(height: 16),

            _googleButton(() async {
              if (_isSigningUp) return;
              setState(() => _isSigningUp = true);
              final user = await AuthService().signInWithGoogle();
              setState(() => _isSigningUp = false);
              if (user != null) {
                Navigator.pushReplacementNamed(context, "/home");
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Google Sign-In failed")),
                );
              }
            }, isSigningUp: _isSigningUp),

            const SizedBox(height: 16),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Already have an account? Login",
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
        fillColor: Colors.white.withOpacity(0.1),
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

  static Widget _googleButton(VoidCallback onTap, {required bool isSigningUp}) {
    return ElevatedButton.icon(
      onPressed: isSigningUp ? null : onTap,
      icon: isSigningUp
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
      label: isSigningUp
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
