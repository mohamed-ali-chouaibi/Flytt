import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'passenger_history_screen.dart';
import 'passenger_messages_screen.dart';
import 'passenger_reservation_screen.dart';
import '../settings/support_screen.dart';
import '../settings/about_screen.dart';
import '../settings/personal_info_screen.dart';
import '../settings/communication_preferences_screen.dart';
import '../settings/calendars_screen.dart';
import 'passenger_home_screen.dart';
import '../auth/language_screen.dart';
import '../utils/theme_provider.dart';
import '../settings/security_screen.dart';
import 'saved_location_screen.dart';
import '../utils/app_localizations.dart';
import '../settings/safety_screen.dart';
import '../settings/privacy_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/signup_screen.dart';
import '../settings/pricing_comparison_screen.dart';
import 'reserve_matching_screen.dart';
import 'driver_nearby_alert_screen.dart';
import '../settings/trusted_contacts_screen.dart';
Route createFadeRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 400),
  );
}
class PassengerProfileScreen extends StatefulWidget {
  const PassengerProfileScreen({Key? key}) : super(key: key);
  @override
  State<PassengerProfileScreen> createState() => _PassengerProfileScreenState();
}
class _PassengerProfileScreenState extends State<PassengerProfileScreen> {
  int _selectedIndex = 2;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _savedLocations;
  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchSavedLocations();
  }
  Future<void> _fetchUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    dynamic response;
    if (user.id.isNotEmpty) {
      response = await Supabase.instance.client
          .from('passenger')
          .select()
          .eq('uid', user.id)
          .single();
    } else if (user.phone != null && user.phone!.isNotEmpty) {
      response = await Supabase.instance.client
          .from('passenger')
          .select()
          .eq('phone', user.phone!)
          .single();
    } else {
      return;
    }
    setState(() {
      _userData = response;
    });
  }
  Future<void> _fetchSavedLocations() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final locations = await Supabase.instance.client
        .from('saved_locations')
        .select()
        .eq('passenger_uid', user.id);
    print('DEBUG: fetched saved_locations: ' + locations.toString());
    final Map<String, dynamic> locs = {};
    for (final loc in locations) {
      if (loc['label'] == 'custom' && locs.containsKey('custom')) continue;
      locs[loc['label']] = loc;
    }
    setState(() {
      _savedLocations = locs;
    });
  }
  Widget _buildHeader() {
    final double rating = _userData != null && _userData!['rating'] != null
        ? (_userData!['rating'] as num).toDouble()
        : 5.0;
    final int rides = _userData != null && _userData!['number_of_rides'] != null
        ? (_userData!['number_of_rides'] as int)
        : 0;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    String? profileImageUrl = _userData != null ? _userData!['profile_image_url'] as String? : null;
    return Container(
      margin: const EdgeInsets.only(top: 32, left: 24, right: 24, bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode ? [RydyColors.darkBg, RydyColors.cardBg] : [RydyColors.textColor, RydyColors.subText],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? RydyColors.subText.withOpacity(0.10) : RydyColors.subText.withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: RydyColors.textColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 44,
              backgroundColor: isDarkMode ? RydyColors.darkBg : RydyColors.textColor,
              backgroundImage: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                  ? NetworkImage(profileImageUrl)
                  : null,
              child: (profileImageUrl == null || profileImageUrl.isEmpty)
                  ? Icon(
                Icons.person_outline,
                color: isDarkMode ? RydyColors.subText : RydyColors.subText,
                size: 44,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _userData != null ? (_userData!['name'] ?? AppLocalizations.of(context).translate('unknown')) : AppLocalizations.of(context).translate('loading'),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? RydyColors.textColor : RydyColors.textColor,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star_rounded, color: RydyColors.textColor, size: 20),
              const SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? RydyColors.textColor : RydyColors.textColor,
                ),
              ),
              const SizedBox(width: 18),
              Icon(Icons.directions_car_filled_rounded, color: isDarkMode ? RydyColors.textColor : RydyColors.textColor, size: 18),
              const SizedBox(width: 4),
              Text(
                '$rides ${AppLocalizations.of(context).translate('rides')}',
                style: TextStyle(
                  fontSize: 15,
                  color: isDarkMode ? RydyColors.subText : RydyColors.subText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildSettingsSection(String title, List<Widget> children) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 4),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? RydyColors.textColor : RydyColors.textColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isDarkMode ? RydyColors.darkBg : RydyColors.textColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDarkMode ? RydyColors.subText : RydyColors.subText),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode ? RydyColors.subText.withOpacity(0.04) : RydyColors.subText.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
  Widget _buildListItem(IconData icon, String title, {String? subtitle, VoidCallback? onTap}) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 28, color: isDarkMode ? RydyColors.textColor : RydyColors.textColor),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? RydyColors.textColor : RydyColors.textColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: isDarkMode ? RydyColors.subText : RydyColors.subText,
              ),
            )
          : null,
      trailing: const Icon(Icons.chevron_right, color: RydyColors.subText),
      minLeadingWidth: 32,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      dense: false,
      shape: Border(bottom: BorderSide(color: isDarkMode ? RydyColors.subText : RydyColors.subText, width: 1)),
    );
  }
  Widget _buildNavBarItem(int index, IconData icon, String label, VoidCallback onTap) {
    final bool isSelected = _selectedIndex == index;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? (isDarkMode ? RydyColors.darkBg : RydyColors.subText) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? (isDarkMode ? RydyColors.textColor : RydyColors.textColor) : (isDarkMode ? RydyColors.subText : RydyColors.subText),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? (isDarkMode ? RydyColors.textColor : RydyColors.textColor) : (isDarkMode ? RydyColors.subText : RydyColors.subText),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  String _getLanguageLabel(BuildContext context) {
    final code = AppLocalizations.of(context).locale.languageCode;
    switch (code) {
      case 'en':
        return 'English - US';
      case 'fr':
        return 'Français';
      case 'ar':
        return 'العربية';
      default:
        return 'English - US';
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RydyColors.darkBg,
      appBar: AppBar(
        backgroundColor: RydyColors.darkBg,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: CircleAvatar(
            backgroundColor: RydyColors.darkBg,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: RydyColors.textColor),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: Text(
          AppLocalizations.of(context).translate('settings'),
          style: TextStyle(
            color: RydyColors.textColor,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        centerTitle: true,
        toolbarHeight: 60,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(20, 28, 20, 18),
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 32),
            decoration: BoxDecoration(
              color: RydyColors.cardBg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListTile(
              leading: CircleAvatar(
                radius: 38,
                backgroundColor: RydyColors.subText,
                child: const Icon(Icons.person, color: RydyColors.darkBg, size: 44),
              ),
              title: Text(
                _userData != null ? (_userData!['name'] ?? AppLocalizations.of(context).translate('unknown')) : AppLocalizations.of(context).translate('loading'),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: RydyColors.textColor),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(_userData?['phone'] ?? '', style: const TextStyle(color: RydyColors.subText, fontSize: 15)),
                  Text(_userData?['email'] ?? '', style: const TextStyle(color: RydyColors.subText, fontSize: 15)),
                ],
              ),
              trailing: const Icon(Icons.chevron_right, color: RydyColors.subText),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PersonalInfoScreen())),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
            ),
          ),
          const SizedBox(height: 10),
          _buildSectionTitle(AppLocalizations.of(context).translate('app_settings')),
          _buildSettingsList([
            _buildListItem(Icons.home_outlined, AppLocalizations.of(context).translate('add_home'), onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SavedLocationScreen(title: 'Add Home', locationType: 'Home'),
                ),
              );
            }),
            _buildListItem(Icons.work_outline, AppLocalizations.of(context).translate('add_work'), onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SavedLocationScreen(title: 'Add Work', locationType: 'Work'),
                ),
              );
            }),
            _buildListItem(Icons.shortcut, AppLocalizations.of(context).translate('shortcuts'), onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SavedLocationScreen(title: 'Shortcuts', locationType: 'Other'),
                ),
              );
            }),
          ]),
          const SizedBox(height: 18),
          _buildSectionTitle(AppLocalizations.of(context).translate('safety')),
          _buildSettingsList([
                          _buildListItem(Icons.shield_outlined, AppLocalizations.of(context).translate('safety_preferences'), subtitle: AppLocalizations.of(context).translate('choose_safety_tools'), onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SafetyScreen(),
                ),
              );
            }),
            _buildListItem(Icons.people_outline, AppLocalizations.of(context).translate('manage_trusted_contacts'), subtitle: AppLocalizations.of(context).translate('share_trip_status'), onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TrustedContactsScreen(),
                ),
              );
            }),
            _buildListItem(Icons.verified_user_outlined, AppLocalizations.of(context).translate('verify_your_ride'), subtitle: AppLocalizations.of(context).translate('use_pin_right_car'), onTap: () {}),
            _buildListItem(Icons.car_repair_outlined, AppLocalizations.of(context).translate('ridecheck'), subtitle: AppLocalizations.of(context).translate('manage_ridecheck'), onTap: () {}),
          ]),
          const SizedBox(height: 18),
          _buildSectionTitle(AppLocalizations.of(context).translate('ride_preferences')),
          _buildSettingsList([
                          _buildListItem(Icons.calendar_today_outlined, AppLocalizations.of(context).translate('reserve'), subtitle: AppLocalizations.of(context).translate('choose_matching'), onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReserveMatchingScreen(),
                ),
              );
            }),
            _buildListItem(Icons.notifications_active_outlined, AppLocalizations.of(context).translate('driver_nearby_alert'), subtitle: AppLocalizations.of(context).translate('manage_notifications_pickups'), onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DriverNearbyAlertScreen(),
                ),
              );
            }),
            _buildListItem(Icons.notifications_none_rounded, AppLocalizations.of(context).translate('commute_alerts'), subtitle: AppLocalizations.of(context).translate('plan_commute'), onTap: () {}),
          ]),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(AppLocalizations.of(context).translate('switch_account'), style: TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    await Supabase.instance.client.auth.signOut();
                    if (mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const SignupScreen()),
                        (route) => false,
                      );
                    }
                  },
                  child: Text(AppLocalizations.of(context).translate('sign_out'), style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 0, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: RydyColors.subText,
          fontWeight: FontWeight.w700,
          fontSize: 14,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
  Widget _buildSettingsList(List<Widget> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: RydyColors.darkBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: List.generate(items.length * 2 - 1, (i) {
          if (i.isEven) {
            return items[i ~/ 2];
          } else {
            return Divider(height: 1, color: RydyColors.cardBg, thickness: 1);
          }
        }),
      ),
    );
  }
} 
