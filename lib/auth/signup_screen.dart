import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_localizations.dart';
import '../utils/theme_provider.dart';
import '../passenger/passenger_home_screen.dart';
import 'personal_info_screen.dart';
class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);
  @override
  _SignupScreenState createState() => _SignupScreenState();
}
class SignupData {
  final String email;
  final String password;
  SignupData({required this.email, required this.password});
}
class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');
    return emailRegex.hasMatch(email.trim());
  }
  bool get isFormValid {
    return _emailController.text.isNotEmpty &&
           _isValidEmail(_emailController.text) &&
           _passwordController.text.length >= 6;
  }
  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      try {
        final signInResponse = await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (signInResponse.user != null) {
          final profileResponse = await Supabase.instance.client
              .from('passenger')
              .select()
              .eq('email', email)
              .maybeSingle();
          if (mounted) {
            if (profileResponse != null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const PassengerHomeScreen()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const PersonalInfoScreen()),
              );
            }
          }
        }
      } on AuthException catch (authError) {
        if (authError.message.contains('Invalid login credentials')) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => PersonalInfoScreen(
                  signupData: SignupData(email: email, password: password),
                ),
              ),
            );
          }
        } else {
          throw authError;
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isRtl = localizations.locale.languageCode == 'ar';
    return Scaffold(
      backgroundColor: RydyColors.darkBg,
      appBar: AppBar(
        backgroundColor: RydyColors.darkBg,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: RydyColors.darkBg,
            child: IconButton(
              icon: Icon(isRtl ? Icons.arrow_forward_ios : Icons.arrow_back, color: RydyColors.textColor),
              onPressed: () => Navigator.pop(context),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
            ),
          ),
        ),
        title: Text(
          localizations.translate('sign_in'),
          style: const TextStyle(
            color: RydyColors.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        toolbarHeight: 56,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      Text(
                        'Sign in or create account',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: RydyColors.textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        decoration: BoxDecoration(
                          color: RydyColors.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: RydyColors.cardBg, width: 1.5),
                        ),
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (value) => setState(() {}),
                          style: const TextStyle(
                            fontSize: 18,
                            color: RydyColors.textColor,
                          ),
                          decoration: InputDecoration(
                            hintText: localizations.translate('email'),
                            hintStyle: const TextStyle(color: RydyColors.subText, fontSize: 18),
                            border: InputBorder.none,
                            prefixIcon: const Icon(Icons.email_outlined, color: RydyColors.subText),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!_isValidEmail(value)) {
                              return localizations.translate('please_enter_valid_email');
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: RydyColors.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: RydyColors.cardBg, width: 1.5),
                        ),
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          onChanged: (value) => setState(() {}),
                          style: const TextStyle(
                            fontSize: 18,
                            color: RydyColors.textColor,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: const TextStyle(color: RydyColors.subText, fontSize: 18),
                            border: InputBorder.none,
                            prefixIcon: const Icon(Icons.lock_outline, color: RydyColors.subText),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: RydyColors.subText,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        localizations.translate('by_proceeding'),
                        style: const TextStyle(color: RydyColors.subText, fontSize: 14, height: 1.5),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: isFormValid ? RydyColors.cardBg : RydyColors.cardBg.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: ElevatedButton(
                    onPressed: (isFormValid && !_isLoading) ? _handleSignUp : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      disabledBackgroundColor: Colors.transparent,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                localizations.translate('continue'),
                                style: TextStyle(
                                  color: isFormValid ? RydyColors.textColor : RydyColors.textColor.withOpacity(0.4),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.arrow_forward, color: isFormValid ? RydyColors.textColor : RydyColors.textColor.withOpacity(0.4), size: 22),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }
} 
