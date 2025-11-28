import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_localizations.dart';
class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({Key? key}) : super(key: key);
  Future<void> _changeLanguage(BuildContext context, String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
    if (context.mounted) {
      AppLocalizations.load(Locale(languageCode));
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Text(
                'Choose Your Language',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _LanguageOption(
                title: 'English',
                nativeTitle: 'English',
                onTap: () => _changeLanguage(context, 'en'),
              ),
              const SizedBox(height: 16),
              _LanguageOption(
                title: 'Français',
                nativeTitle: 'Français',
                onTap: () => _changeLanguage(context, 'fr'),
              ),
              const SizedBox(height: 16),
              _LanguageOption(
                title: 'العربية',
                nativeTitle: 'العربية',
                onTap: () => _changeLanguage(context, 'ar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _LanguageOption extends StatelessWidget {
  final String title;
  final String nativeTitle;
  final VoidCallback onTap;
  const _LanguageOption({
    required this.title,
    required this.nativeTitle,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(
                nativeTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
} 
