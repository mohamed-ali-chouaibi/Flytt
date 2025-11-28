import 'package:flutter/material.dart';
import '../utils/theme_provider.dart';
import '../utils/app_localizations.dart';
class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RydyColors.darkBg,
      appBar: AppBar(
        backgroundColor: RydyColors.darkBg,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: RydyColors.darkBg,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: RydyColors.textColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          AppLocalizations.of(context).translate('about'),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: RydyColors.cardBg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: RydyColors.textColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/icon/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.directions_car_rounded,
                          size: 60,
                          color: RydyColors.textColor,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context).translate('flytt'),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: RydyColors.textColor,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context).translate('version'),
                  style: TextStyle(
                    fontSize: 16,
                    color: RydyColors.subText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).translate('smart_mobility_partner'),
                  style: TextStyle(
                    fontSize: 14,
                    color: RydyColors.subText,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildSection(
            AppLocalizations.of(context).translate('legal_information'),
            [
              _buildInfoItem(
                AppLocalizations.of(context).translate('terms_of_use'),
                AppLocalizations.of(context).translate('terms_of_use_desc'),
                Icons.description_outlined,
                RydyColors.textColor,
              ),
              _buildInfoItem(
                AppLocalizations.of(context).translate('privacy_policy'),
                AppLocalizations.of(context).translate('privacy_policy_desc'),
                Icons.privacy_tip_outlined,
                RydyColors.textColor,
              ),
              _buildInfoItem(
                AppLocalizations.of(context).translate('licenses'),
                AppLocalizations.of(context).translate('licenses_desc'),
                Icons.file_copy_outlined,
                RydyColors.textColor,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            AppLocalizations.of(context).translate('application'),
            [
              _buildInfoItem(
                AppLocalizations.of(context).translate('developer'),
                AppLocalizations.of(context).translate('developer_desc'),
                Icons.code_rounded,
                RydyColors.textColor,
              ),
              _buildInfoItem(
                AppLocalizations.of(context).translate('creation_year'),
                AppLocalizations.of(context).translate('creation_year_desc'),
                Icons.calendar_today_outlined,
                RydyColors.textColor,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            AppLocalizations.of(context).translate('social_networks'),
            [
              _buildSocialItem(
                AppLocalizations.of(context).translate('facebook'),
                '@flytt.Inc',
                Icons.facebook_rounded,
                RydyColors.textColor,
              ),
              _buildSocialItem(
                AppLocalizations.of(context).translate('instagram'),
                '@flytt.Inc',
                Icons.camera_alt_rounded,
                RydyColors.textColor,
              ),
              _buildSocialItem(
                AppLocalizations.of(context).translate('twitter'),
                '@flytt.Inc',
                Icons.flutter_dash_rounded,
                RydyColors.textColor,
              ),
              _buildSocialItem(
                AppLocalizations.of(context).translate('linkedin'),
                '@flytt.Inc',
                Icons.work_outline,
                RydyColors.textColor,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: RydyColors.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: RydyColors.subText.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '© 2025 Flytt Inc',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: RydyColors.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context).translate('all_rights_reserved'),
                  style: TextStyle(
                    fontSize: 14,
                    color: RydyColors.subText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: RydyColors.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: RydyColors.textColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: RydyColors.cardBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }
  Widget _buildInfoItem(String title, String subtitle, IconData icon, Color color, {VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: RydyColors.subText.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: RydyColors.textColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: RydyColors.subText,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: RydyColors.darkBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.arrow_forward_ios_rounded,
            color: RydyColors.subText,
            size: 16,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
  Widget _buildSocialItem(
    String platform,
    String handle,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: RydyColors.subText.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
        title: Text(
          platform,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: RydyColors.textColor,
          ),
        ),
        subtitle: Text(
          handle,
          style: TextStyle(
            color: RydyColors.subText,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.arrow_forward_ios_rounded,
            color: color,
            size: 16,
          ),
        ),
      ),
    );
  }
} 
