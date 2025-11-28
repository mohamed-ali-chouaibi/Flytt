import 'package:flutter/material.dart';
import '../utils/app_localizations.dart';
import '../utils/theme_provider.dart';
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}
class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<OnboardingPage> _getPages(BuildContext context) {
    return [
      OnboardingPage(image: 'assets/onboarding/onboarding1.png'),
      OnboardingPage(image: 'assets/onboarding/onboarding2.png'),
      OnboardingPage(image: 'assets/onboarding/onboarding3.png'),
    ];
  }
  void _navigateToSignup() {
    Navigator.pushNamed(context, '/signup');
  }
  void _onContinue() {
    if (_currentPage < _getPages(context).length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
    } else {
      _navigateToSignup();
    }
  }
  @override
  Widget build(BuildContext context) {
    final pages = _getPages(context);
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: RydyColors.darkBg,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: PageView.builder(
              controller: _pageController,
              itemCount: pages.length,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemBuilder: (context, index) {
                final page = pages[index];
                return Container(
                  width: double.infinity,
                  height: size.height,
                  child: Stack(
                    children: [
                      Positioned(
                        top: size.height * 0,
                        left: 0,
                        right: 0,
                        child: SizedBox(
                          height: size.height * 0.73,
                          child: Image.asset(
                            page.image,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          height: size.height * 0.30,
                          decoration: const BoxDecoration(
                            color: RydyColors.darkBg,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(32),
                              topRight: Radius.circular(32),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Text(
                                  _currentPage == 0
                                      ? 'Choose Your Ride'
                                      : (_currentPage == 1
                                          ? 'Book Instantly'
                                          : (_currentPage == 2 ? 'Move Freely' : 'Welcome to Weego')),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: RydyColors.textColor,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (_currentPage == 0)
                                  const Text(
                                    'Cars, scooters, bikes - all in one app',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: RydyColors.subText,
                                      height: 1.4,
                                    ),
                                  )
                                else if (_currentPage == 1)
                                  const Text(
                                    'Get your ride in minutes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: RydyColors.subText,
                                      height: 1.4,
                                    ),
                                  )
                                else if (_currentPage == 2)
                                  const Text(
                                    'Your city, your way to travel',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: RydyColors.subText,
                                      height: 1.4,
                                    ),
                                  ),
                                const Spacer(),
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeInOut,
                                    decoration: BoxDecoration(
                                      color: RydyColors.cardBg,
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _onContinue,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(28),
                                        ),
                                        disabledBackgroundColor: Colors.transparent,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            _currentPage == 0
                                                ? 'Explore'
                                                : (_currentPage == 1 ? 'Continue' : 'Get Started'),
                                            style: const TextStyle(
                                              color: RydyColors.textColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          const Icon(Icons.arrow_forward, color: RydyColors.textColor, size: 22),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 24,
            child: IgnorePointer(
              child: SizedBox(
                height: 32,
                child: Image.asset(
                  'assets/icon/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Text(
                      'Flytt',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class OnboardingPage {
  final String image;
  OnboardingPage({required this.image});
} 
