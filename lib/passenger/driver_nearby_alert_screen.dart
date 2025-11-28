import 'package:flutter/material.dart';
import '../utils/theme_provider.dart';
import '../utils/app_localizations.dart';
import 'package:provider/provider.dart';
class DriverNearbyAlertScreen extends StatefulWidget {
  const DriverNearbyAlertScreen({Key? key}) : super(key: key);
  @override
  State<DriverNearbyAlertScreen> createState() => _DriverNearbyAlertScreenState();
}
class _DriverNearbyAlertScreenState extends State<DriverNearbyAlertScreen> {
  bool _buzzWhenDriverNear = true;
  void _updateBuzzWhenDriverNear(bool value) {
    setState(() {
      _buzzWhenDriverNear = value;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? AppLocalizations.of(context).translate('phone_buzzing_enabled') : AppLocalizations.of(context).translate('phone_buzzing_disabled')),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
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
          AppLocalizations.of(context).translate('driver_nearby_alert'),
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
              AppLocalizations.of(context).translate('manage_notifications'),
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
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).translate('buzz_when_driver_near'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: RydyColors.textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context).translate('buzz_description'),
                          style: TextStyle(
                            fontSize: 14,
                            color: RydyColors.subText,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Switch(
                    value: _buzzWhenDriverNear,
                    onChanged: _updateBuzzWhenDriverNear,
                    activeColor: RydyColors.textColor,
                    activeTrackColor: RydyColors.textColor.withOpacity(0.3),
                    inactiveThumbColor: RydyColors.subText,
                    inactiveTrackColor: RydyColors.subText.withOpacity(0.2),
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
