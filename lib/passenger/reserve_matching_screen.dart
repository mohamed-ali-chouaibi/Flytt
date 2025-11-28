import 'package:flutter/material.dart';
import '../utils/app_localizations.dart';
import '../utils/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
class ReserveMatchingScreen extends StatefulWidget {
  const ReserveMatchingScreen({Key? key}) : super(key: key);
  @override
  State<ReserveMatchingScreen> createState() => _ReserveMatchingScreenState();
}
class _ReserveMatchingScreenState extends State<ReserveMatchingScreen> {
  bool _autoRematch = false;
  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }
  Future<void> _loadUserPreferences() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final response = await Supabase.instance.client
          .from('passenger')
          .select('auto_rematch')
          .eq('uid', user.id)
          .single();
      if (response != null && response['auto_rematch'] != null) {
        setState(() {
          _autoRematch = response['auto_rematch'] as bool;
        });
      }
    } catch (e) {
      print('Error loading user preferences: $e');
    }
  }
  Future<void> _updateAutoRematch(bool value) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client
          .from('passenger')
          .update({'auto_rematch': value})
          .eq('uid', user.id);
      setState(() {
        _autoRematch = value;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? AppLocalizations.of(context).translate('auto_rematch_enabled') : AppLocalizations.of(context).translate('auto_rematch_disabled')),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('error_updating_preference').replaceAll('{error}', e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          AppLocalizations.of(context).translate('reserve_matching'),
          style: TextStyle(
            color: RydyColors.textColor,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        centerTitle: true,
        toolbarHeight: 60,
      ),
      body: Container(
        color: RydyColors.darkBg,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).translate('reserve_matching_description'),
              style: TextStyle(
                fontSize: 16,
                color: RydyColors.subText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: RydyColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: RydyColors.subText.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context).translate('auto_rematch'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: RydyColors.textColor,
                        ),
                      ),
                      Switch(
                        value: _autoRematch,
                        onChanged: _updateAutoRematch,
                        activeColor: RydyColors.textColor,
                        activeTrackColor: RydyColors.textColor.withOpacity(0.3),
                        inactiveThumbColor: RydyColors.subText,
                        inactiveTrackColor: RydyColors.subText.withOpacity(0.2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context).translate('auto_rematch_description'),
                    style: TextStyle(
                      fontSize: 14,
                      color: RydyColors.subText,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
