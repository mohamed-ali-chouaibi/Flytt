import 'package:flutter/material.dart';
import '../utils/theme_provider.dart';
import '../utils/app_localizations.dart';
class SupportScreen extends StatelessWidget {
  const SupportScreen({Key? key}) : super(key: key);
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
          AppLocalizations.of(context).translate('help_support'),
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
          _buildSection(
            title: AppLocalizations.of(context).translate('faq'),
            items: [
              _buildFaqItem(
                AppLocalizations.of(context).translate('how_book_ride'),
                AppLocalizations.of(context).translate('how_book_ride_answer'),
              ),
              _buildFaqItem(
                AppLocalizations.of(context).translate('how_cancel_reservation'),
                AppLocalizations.of(context).translate('how_cancel_reservation_answer'),
              ),
              _buildFaqItem(
                AppLocalizations.of(context).translate('how_contact_driver'),
                AppLocalizations.of(context).translate('how_contact_driver_answer'),
              ),
              _buildFaqItem(
                AppLocalizations.of(context).translate('how_modify_info'),
                AppLocalizations.of(context).translate('how_modify_info_answer'),
              ),
              _buildFaqItem(
                AppLocalizations.of(context).translate('how_report_problem'),
                AppLocalizations.of(context).translate('how_report_problem_answer'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSection(
            title: AppLocalizations.of(context).translate('contact_us'),
            items: [
              _buildContactItem(
                Icons.phone_outlined,
                AppLocalizations.of(context).translate('customer_service'),
                AppLocalizations.of(context).translate('phone_number'),
                RydyColors.textColor,
              ),
              _buildContactItem(
                Icons.email_outlined,
                AppLocalizations.of(context).translate('email_support'),
                AppLocalizations.of(context).translate('support_email'),
                RydyColors.textColor,
              ),
              _buildContactItem(
                Icons.message_outlined,
                AppLocalizations.of(context).translate('live_chat'),
                AppLocalizations.of(context).translate('available_24_7'),
                RydyColors.textColor,
              ),
              _buildContactItem(
                Icons.location_on_outlined,
                AppLocalizations.of(context).translate('main_office'),
                AppLocalizations.of(context).translate('tunis_tunisia'),
                RydyColors.textColor,
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSection(
            title: AppLocalizations.of(context).translate('quick_actions'),
            items: [
              _buildQuickActionItem(
                Icons.bug_report_outlined,
                AppLocalizations.of(context).translate('report_bug'),
                AppLocalizations.of(context).translate('report_technical_problem'),
                RydyColors.textColor,
              ),
              _buildQuickActionItem(
                Icons.feedback_outlined,
                AppLocalizations.of(context).translate('give_feedback'),
                AppLocalizations.of(context).translate('share_experience'),
                RydyColors.textColor,
              ),
              _buildQuickActionItem(
                Icons.help_outline,
                AppLocalizations.of(context).translate('user_guide'),
                AppLocalizations.of(context).translate('tutorials_tips'),
                RydyColors.textColor,
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  Widget _buildSection({
    required String title,
    required List<Widget> items,
  }) {
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
        ...items,
      ],
    );
  }
  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Theme(
        data: ThemeData(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          title: Text(
            question,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: RydyColors.textColor,
            ),
          ),
          iconColor: RydyColors.textColor,
          collapsedIconColor: RydyColors.subText,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text(
                answer,
                style: TextStyle(
                  color: RydyColors.subText,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildContactItem(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      ),
    );
  }
  Widget _buildQuickActionItem(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
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
