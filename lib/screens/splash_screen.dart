import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {

  @override
  void initState() {
    super.initState();
    _startSequence();
  }

  Future<void> _startSequence() async {
   
    await Future.delayed(const Duration(milliseconds: 300));

    await _loadResources();

    final prefsFuture = SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await prefsFuture;
    final showIntro = prefs.getBool('show_intro') ?? true;

    await Future.delayed(const Duration(milliseconds: 1200));

    if (showIntro) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/intro');
    } else {
      if (user == null) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/home');
      }
    }

  }

  Future<void> _loadResources() async {
    await Future.delayed(const Duration(seconds: 2));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Center(
          child: Lottie.asset(
            'assets/lottie/shield_sword.json',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
