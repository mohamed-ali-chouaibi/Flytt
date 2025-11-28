import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'auth/splash_screen.dart';
import 'auth/onboarding_screen.dart';
import 'auth/signup_screen.dart';
import 'auth/language_screen.dart';
import 'auth/personal_info_screen.dart';
import 'utils/app_localizations.dart';
import 'package:provider/provider.dart';
import 'utils/theme_provider.dart';
import 'utils/shared_preferences_util.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'utils/language_utils.dart';
Future<String> detectAndSetLanguage() async {
  await SharedPreferencesUtil.init();
  String? savedLang = await SharedPreferencesUtil.getString('languageCode');
  if (savedLang != null) return savedLang;
  LocationPermission permission = await Geolocator.requestPermission();
  if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
    await SharedPreferencesUtil.setString('languageCode', 'en');
    return 'en'; 
  }
  Position position = await Geolocator.getCurrentPosition();
  final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=AIzaSyDaIk1468iXr5IaRhHvYe32tnWgLqyyTg4';
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final results = data['results'] as List;
    for (var result in results) {
      final components = result['address_components'] as List;
      for (var component in components) {
        if (component['types'].contains('country')) {
          String countryCode = component['short_name'];
          String lang = getLanguageForCountry(countryCode);
          await SharedPreferencesUtil.setString('languageCode', lang);
          return lang;
        }
      }
    }
  }
  await SharedPreferencesUtil.setString('languageCode', 'en');
  return 'en';
}
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferencesUtil.init();
  String? languageCode = await SharedPreferencesUtil.getString('languageCode');
  if (languageCode == null) {
    languageCode = await detectAndSetLanguage();
  }
  const supabaseUrl = 'https://vnuspcabxppxprjbydbu.supabase.co';
  const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZudXNwY2FieHBweHByamJ5ZGJ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDEwNDE4OTMsImV4cCI6MjA1NjYxNzg5M30.fZvSxtr1iQAydH36jgxCBEK27BCZhYLwvJTEBdIjNaQ';
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: anonKey,
  );
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: RydyColors.darkBg,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: RydyColors.darkBg,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: WayfaroApp(initialLocale: languageCode ?? 'en'),
    ),
  );
}
class WayfaroApp extends StatefulWidget {
  final String initialLocale;
  const WayfaroApp({
    Key? key,
    required this.initialLocale,
  }) : super(key: key);
  static _WayfaroAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_WayfaroAppState>();
  @override
  State<WayfaroApp> createState() => _WayfaroAppState();
}
class _WayfaroAppState extends State<WayfaroApp> {
  late Locale locale;
  void setLocale(Locale newLocale) {
    setState(() {
      locale = newLocale;
    });
  }
  @override
  void initState() {
    super.initState();
    locale = Locale(widget.initialLocale);
  }
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Flytt',
          theme: themeProvider.theme.copyWith(
            primaryColor: RydyColors.darkBg,
            appBarTheme: const AppBarTheme(
              backgroundColor: RydyColors.darkBg,
              elevation: 0,
              iconTheme: IconThemeData(color: RydyColors.textColor),
              titleTextStyle: TextStyle(
                color: RydyColors.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
              centerTitle: true,
            ),
            colorScheme: themeProvider.theme.colorScheme.copyWith(
              primary: RydyColors.darkBg,
              secondary: RydyColors.cardBg,
              surface: RydyColors.cardBg,
              background: RydyColors.darkBg,
              onPrimary: RydyColors.textColor,
              onSecondary: RydyColors.textColor,
              onSurface: RydyColors.textColor,
              onBackground: RydyColors.textColor,
              brightness: Brightness.dark,
            ),
            snackBarTheme: const SnackBarThemeData(
              backgroundColor: RydyColors.cardBg,
              contentTextStyle: TextStyle(color: RydyColors.textColor),
              behavior: SnackBarBehavior.floating,
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: RydyColors.cardBg,
              foregroundColor: RydyColors.textColor,
              elevation: 0,
            ),
            textButtonTheme: TextButtonThemeData(
              style: ButtonStyle(
                backgroundColor: MaterialStatePropertyAll(RydyColors.cardBg),
                foregroundColor: MaterialStatePropertyAll(RydyColors.textColor),
                overlayColor: MaterialStatePropertyAll(Colors.transparent),
                shape: MaterialStatePropertyAll(
                  RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(32))),
                ),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ButtonStyle(
                backgroundColor: MaterialStatePropertyAll(RydyColors.cardBg),
                foregroundColor: MaterialStatePropertyAll(RydyColors.textColor),
                overlayColor: MaterialStatePropertyAll(Colors.transparent),
                shape: MaterialStatePropertyAll(
                  RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(32))),
                ),
                elevation: MaterialStatePropertyAll(0),
              ),
            ),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
          ),
          locale: locale,
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('fr'),
            Locale('ar'),
          ],
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/language':
                return PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      LanguageScreen(
                    onLanguageSelected: (String languageCode) {
                      setLocale(Locale(languageCode));
                    },
                  ),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;
                    var tween = Tween(begin: begin, end: end)
                        .chain(CurveTween(curve: curve));
                    var offsetAnimation = animation.drive(tween);
                    return SlideTransition(
                        position: offsetAnimation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 500),
                );
              case '/onboarding':
                return PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const OnboardingScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;
                    var tween = Tween(begin: begin, end: end)
                        .chain(CurveTween(curve: curve));
                    var offsetAnimation = animation.drive(tween);
                    return SlideTransition(
                        position: offsetAnimation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 500),
                );
              case '/signup':
                return PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const SignupScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 400),
                );
              case '/personal_info':
                return PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const PersonalInfoScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;
                    var tween = Tween(begin: begin, end: end)
                        .chain(CurveTween(curve: curve));
                    var offsetAnimation = animation.drive(tween);
                    return SlideTransition(
                        position: offsetAnimation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 500),
                );
              default:
                return MaterialPageRoute(builder: (_) => const SplashScreen());
            }
          },
        );
      },
    );
  }
}
