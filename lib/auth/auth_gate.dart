import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:iumrah_project/home/home_page.dart';
import 'package:iumrah_project/splash/welcome_page.dart';
import 'package:iumrah_project/core/navigation/premium_route.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _goNext();
    });
  }

  void _goNext() {
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      Navigator.of(context).pushReplacement(
        PremiumRoute.push(const HomePage()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PremiumRoute.push(const WelcomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFE6E6EF),
      body: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF610084),
          ),
        ),
      ),
    );
  }
}
