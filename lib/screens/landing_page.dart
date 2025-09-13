import 'package:flutter/material.dart';
import 'package:mil_hub/features/auth/screens/login_screen.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
            // Logo / Hero Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Icon(
                Icons.shield_outlined,
                size: 100,
                color: Colors.indigoAccent,
              ),
            ),

            const SizedBox(height: 30),

            // Headline
            const Text(
              "MIL Hub",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 10),

            // Subtitle
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Empowering youth to verify facts, fight misinformation, "
                "and build digital literacy skills.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ),

            const SizedBox(height: 30),

            // CTA Button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Get Started",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 60),

            // Small feature highlights row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _FeatureIcon(icon: Icons.search, label: "Check"),
                _FeatureIcon(icon: Icons.school, label: "Learn"),
                _FeatureIcon(icon: Icons.people, label: "Community"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 40, color: Colors.white),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}
