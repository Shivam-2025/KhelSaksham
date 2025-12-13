//testing github upload
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'components/private_navbar.dart';
import 'components/public_navbar.dart';
import 'screens/achievements_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/hero_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/recording_screen.dart';
import 'services/api_singleton.dart'; 

void main() {
  runApp(const KhelSakshamApp());
}

class KhelSakshamApp extends StatelessWidget {
  const KhelSakshamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KhelSaksham',
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// -------------------------------
/// Splash Screen (checks token)
/// -------------------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access_token");

    if (token != null && token.isNotEmpty) {
      // set token in ApiService
      api.setToken(token);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen(startView: 'dashboard')),
        );
      }
    } else {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen(startView: 'home')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

/// -------------------------------
/// MainScreen (navigation manager)
/// -------------------------------
class MainScreen extends StatefulWidget {
  final String startView;

  const MainScreen({super.key, required this.startView});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late String currentView;

  @override
  void initState() {
    super.initState();
    currentView = widget.startView;
  }

  @override
  Widget build(BuildContext context) {
    // PUBLIC HOME SCREEN
    if (currentView == 'home') {
      return Stack(
        children: [
          HeroScreen(
            onExplore: () => setState(() => currentView = 'auth'),
            onAuth: () => setState(() => currentView = 'auth'),
          ),
          PublicNavbar(
            onLoginClick: () => setState(() => currentView = 'auth'),
            onSignupClick: () => setState(() => currentView = 'auth'),
            onNavigate: (String route) {
              if (route == 'home') setState(() => currentView = 'home');
            },
          ),
        ],
      );
    }

    // AUTH SCREEN
    if (currentView == 'auth') {
      return AuthScreen(
        onBack: () => setState(() => currentView = 'home'),
        onAuthSuccess: () => setState(() => currentView = 'dashboard'),
      );
    }

    // PRIVATE/LOGGED-IN SCREENS WRAPPED IN PrivateNavbar
    return PrivateNavbar(
      currentView: currentView,
      onNavigate: (String route) => setState(() => currentView = route),
      onLogout: () async {
        // clear token on logout
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove("access_token");
        setState(() => currentView = 'home');
      },
      child: _buildCurrentScreen(),
    );
  }

  Widget _buildCurrentScreen() {
    switch (currentView) {
      case 'dashboard':
        return const DashboardScreen();
      case 'profile':
        return const ProfileScreen();
      case 'leaderboard':
        return const LeaderboardScreen();
      case 'achievements':
        return const AchievementsScreen();
      case 'recording':
        // ✅ FIXED: must provide required exercise
        return const RecordingScreen(exercise: "pushups"); 
      default:
        return const DashboardScreen();
    }
  }
}
