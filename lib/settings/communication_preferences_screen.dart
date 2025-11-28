import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
class CommunicationPreferencesScreen extends StatefulWidget {
  const CommunicationPreferencesScreen({Key? key}) : super(key: key);
  @override
  State<CommunicationPreferencesScreen> createState() => _CommunicationPreferencesScreenState();
}
class _CommunicationPreferencesScreenState extends State<CommunicationPreferencesScreen> {
  bool _rideUpdates = true;
  bool _promotions = true;
  bool _newsletter = false;
  bool _marketingEmails = false;
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  static const Color accent = Color(0xFF2C3E50); 
  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('pushNotifications') ?? true;
      _emailNotifications = prefs.getBool('emailNotifications') ?? true;
      _smsNotifications = prefs.getBool('smsNotifications') ?? false;
      _promotions = prefs.getBool('promotions') ?? true;
      _newsletter = prefs.getBool('newsletter') ?? false;
      _marketingEmails = prefs.getBool('marketingEmails') ?? false;
    });
  }
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pushNotifications', _pushNotifications);
    await prefs.setBool('emailNotifications', _emailNotifications);
    await prefs.setBool('smsNotifications', _smsNotifications);
    await prefs.setBool('promotions', _promotions);
    await prefs.setBool('newsletter', _newsletter);
    await prefs.setBool('marketingEmails', _marketingEmails);
  }
  Future<void> _savePreferencesToSupabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    await Supabase.instance.client
        .from('user_preferences')
        .upsert({
          'user_id': user.id,
          'push_notifications': _pushNotifications,
          'email_notifications': _emailNotifications,
          'sms_notifications': _smsNotifications,
          'promotions': _promotions,
          'newsletter': _newsletter,
          'marketing_emails': _marketingEmails,
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
        title: const Text('Communication', style: TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: -0.5)),
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
                'Ride Updates',
                [
                  _buildSwitchTile(
                    'Push Notifications',
                    'Get real-time updates about your ride',
                    _pushNotifications,
                    (value) => setState(() => _pushNotifications = value),
                  ),
                  _buildSwitchTile(
                    'Email Notifications',
                    'Receive ride updates via email',
                    _emailNotifications,
                    (value) => setState(() => _emailNotifications = value),
                  ),
                  _buildSwitchTile(
                    'SMS Notifications',
                    'Get text messages about your ride',
                    _smsNotifications,
                    (value) => setState(() => _smsNotifications = value),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                'Promotions & Marketing',
                [
                  _buildSwitchTile(
                    'Promotions',
                    'Get notified about special offers and discounts',
                    _promotions,
                    (value) => setState(() => _promotions = value),
                  ),
                  _buildSwitchTile(
                    'Newsletter',
                    'Receive our monthly newsletter',
                    _newsletter,
                    (value) => setState(() => _newsletter = value),
                  ),
                  _buildSwitchTile(
                    'Marketing Emails',
                    'Get updates about new features and services',
                    _marketingEmails,
                    (value) => setState(() => _marketingEmails = value),
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
