import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../passenger/passenger_home_screen.dart';
import 'signup_screen.dart';
import 'onboarding_screen.dart';
import '../utils/theme_provider.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _loveController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _loveAnimation;
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _loveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _loveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loveController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _scaleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      _loveController.forward();
    });
    Future.delayed(const Duration(seconds: 3), _checkAuthAndAccount);
  }
  Future<void> _checkAuthAndAccount() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final userRow = await Supabase.instance.client
          .from('passenger')
          .select()
          .eq('uid', user.id)
          .maybeSingle();
      if (mounted) {
        if (userRow != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PassengerHomeScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        }
      }
    } else {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    }
  }
  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _loveController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RydyColors.darkBg, 
      body: Stack(
        children: [
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Image.asset(
                'assets/icon/logo.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Text(
                    'Flytt',
                    style: TextStyle(
                      color: RydyColors.textColor,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            bottom: 50, 
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _loveAnimation,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Made with L',
                    style: TextStyle(
                      color: RydyColors.textColor, 
                      fontSize: 22, 
                      fontWeight: FontWeight.bold, 
                      fontFamily: 'montserrat',
                    ),
                  ),
                  Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 24, 
                  ),
                  Text(
                    'VE',
                    style: TextStyle(
                      color: RydyColors.textColor, 
                      fontSize: 22, 
                      fontWeight: FontWeight.bold, 
                      fontFamily: 'montserrat',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 
