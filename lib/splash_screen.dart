import 'dart:async';
import 'package:flutter/material.dart';
import 'main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1117), Color(0xFF161B22), Color(0xFF1F2937)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              AnimatedBuilder(
                animation: controller,

                builder: (context, child) {
                  return Transform.scale(
                    scale: 1 + (controller.value * 0.1),

                    child: Container(
                      padding: const EdgeInsets.all(30),

                      decoration: BoxDecoration(
                        shape: BoxShape.circle,

                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.6),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),

                      child: const Icon(
                        Icons.lightbulb,
                        color: Color(0xFFff4ecd),
                        size: 100,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              const Text(
                "Grameen-Light",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                "Smart Village Energy Monitoring",
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),

              const SizedBox(height: 50),

              const CircularProgressIndicator(color: Color(0xFFff4ecd)),
            ],
          ),
        ),
      ),
    );
  }
}
