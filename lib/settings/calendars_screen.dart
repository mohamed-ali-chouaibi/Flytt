import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
class CalendarsScreen extends StatefulWidget {
  const CalendarsScreen({Key? key}) : super(key: key);
  @override
  State<CalendarsScreen> createState() => _CalendarsScreenState();
}
class _CalendarsScreenState extends State<CalendarsScreen> {
  bool _googleCalendar = false;
  bool _appleCalendar = false;
  bool _outlookCalendar = false;
  bool _autoAddRides = true;
  bool _showRideDetails = true;
  bool _notifyBeforeRide = true;
  static const Color accent = Color(0xFF2C3E50); 
  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _googleCalendar = prefs.getBool('googleCalendar') ?? false;
      _appleCalendar = prefs.getBool('appleCalendar') ?? false;
      _outlookCalendar = prefs.getBool('outlookCalendar') ?? false;
      _autoAddRides = prefs.getBool('autoAddRides') ?? true;
      _showRideDetails = prefs.getBool('showRideDetails') ?? true;
      _notifyBeforeRide = prefs.getBool('notifyBeforeRide') ?? true;
    });
  }
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('googleCalendar', _googleCalendar);
    await prefs.setBool('appleCalendar', _appleCalendar);
    await prefs.setBool('outlookCalendar', _outlookCalendar);
    await prefs.setBool('autoAddRides', _autoAddRides);
    await prefs.setBool('showRideDetails', _showRideDetails);
    await prefs.setBool('notifyBeforeRide', _notifyBeforeRide);
  }
  Future<void> _savePreferencesToSupabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    await Supabase.instance.client
        .from('calendar_preferences')
        .upsert({
          'user_id': user.id,
          'google_calendar': _googleCalendar,
          'apple_calendar': _appleCalendar,
          'outlook_calendar': _outlookCalendar,
          'auto_add_rides': _autoAddRides,
          'show_ride_details': _showRideDetails,
          'notify_before_ride': _notifyBeforeRide,
        });
  }
  void _onSave() async {
    await _savePreferences();
    await _savePreferencesToSupabase();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences saved!')),
      );
      Navigator.pop(context);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Calendars', style: TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: -0.5)),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFF5F7FA),
                  const Color(0xFFE0E7EF),
                  const Color(0xFFF5F7FA),
                ],
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
              const SizedBox(height: 80),
              _buildSection(
                'Calendar Integration',
                [
                  _buildCalendarTile(
                    'Google Calendar',
                    'Connect your Google account',
                    Icons.calendar_today_rounded,
                    _googleCalendar,
                    (value) => setState(() => _googleCalendar = value),
                  ),
                  _buildCalendarTile(
                    'Apple Calendar',
                    'Connect your Apple account',
                    Icons.calendar_today_rounded,
                    _appleCalendar,
                    (value) => setState(() => _appleCalendar = value),
                  ),
                  _buildCalendarTile(
                    'Outlook Calendar',
                    'Connect your Microsoft account',
                    Icons.calendar_today_rounded,
                    _outlookCalendar,
                    (value) => setState(() => _outlookCalendar = value),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                'Calendar Settings',
                [
                  _buildSwitchTile(
                    'Auto-add rides to calendar',
                    'Automatically add your rides to your connected calendars',
                    _autoAddRides,
                    (value) => setState(() => _autoAddRides = value),
                  ),
                  _buildSwitchTile(
                    'Show ride details',
                    'Include pickup location and driver details in calendar events',
                    _showRideDetails,
                    (value) => setState(() => _showRideDetails = value),
                  ),
                  _buildSwitchTile(
                    'Notify before ride',
                    'Get calendar notifications before your scheduled rides',
                    _notifyBeforeRide,
                    (value) => setState(() => _notifyBeforeRide = value),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
                  onPressed: _onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF26A69A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
  Widget _buildCalendarTile(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFE9EDF2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: accent, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2C3E50),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF757575),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF26A69A),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }
  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2C3E50),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF757575),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF26A69A),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }
} 
