import 'package:english_voice_ai_clean/features/voice_chat/presentation/dashboard_routes.dart';
import 'package:english_voice_ai_clean/features/voice_chat/infrastructure/local/local_user_preferences_repository.dart';
import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final LocalUserPreferencesRepository _preferencesRepository =
      LocalUserPreferencesRepository();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      _navigateAfterSplash();
    });
  }

  Future<void> _navigateAfterSplash() async {
    final hasCompletedSelection =
        await _preferencesRepository.hasCompletedInitialLanguageSelection();
    if (!mounted) return;

    final targetRoute = hasCompletedSelection
        ? DashboardRoutes.dashboard
        : DashboardRoutes.initialLanguage;

    Navigator.of(context).pushReplacementNamed(targetRoute);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.cyan[700],
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/englishaichat_logo.png', width: 200),
              const SizedBox(height: 32),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
