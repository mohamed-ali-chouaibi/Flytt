import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_localizations.dart';
class SecurityScreen extends StatefulWidget {
  const SecurityScreen({Key? key}) : super(key: key);
  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}
class _SecurityScreenState extends State<SecurityScreen> {
  bool _isBiometricEnabled = false;
  bool _isTwoFactorEnabled = false;
  bool _isLocationTrackingEnabled = true;
  bool _isActivityLogEnabled = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.15),
        elevation: 0,
        title: Text(
          AppLocalizations.of(context).translate('security'),
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        foregroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF5F7FA), Color(0xFFE0E7EF)],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    _buildGlassHeader(),
                    const SizedBox(height: 28),
                    _buildGlassSection(
                      title: AppLocalizations.of(context).translate('account_security'),
                      items: [
                        _buildGlassItem(
                          icon: Icons.fingerprint_rounded,
                          title: 'Biometric Authentication',
                          subtitle: 'Use fingerprint or face ID to log in',
                          hasSwitch: true,
                          switchValue: _isBiometricEnabled,
                          onSwitchChanged: (value) {
                            setState(() => _isBiometricEnabled = value);
                          },
                          gradient: [Color(0xFF4A90E2), Color(0xFF357AE8)],
                        ),
                        _buildGlassItem(
                          icon: Icons.security_rounded,
                          title: 'Two-Factor Authentication',
                          subtitle: 'Add an extra layer of security',
                          hasSwitch: true,
                          switchValue: _isTwoFactorEnabled,
                          onSwitchChanged: (value) {
                            setState(() => _isTwoFactorEnabled = value);
                          },
                          gradient: [Color(0xFF8E54E9), Color(0xFF4776E6)],
                        ),
                        _buildGlassItem(
                          icon: Icons.lock_reset_rounded,
                          title: 'Change Password',
                          subtitle: 'Update your account password',
                          onTap: () {},
                          gradient: [Color(0xFFFFA726), Color(0xFFFF7043)],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildGlassSection(
                      title: 'Privacy Settings',
                      items: [
                        _buildGlassItem(
                          icon: Icons.location_on_rounded,
                          title: 'Location Tracking',
                          subtitle: 'Allow app to track your location',
                          hasSwitch: true,
                          switchValue: _isLocationTrackingEnabled,
                          onSwitchChanged: (value) {
                            setState(() => _isLocationTrackingEnabled = value);
                          },
                          gradient: [Color(0xFF43E97B), Color(0xFF38F9D7)],
                        ),
                        _buildGlassItem(
                          icon: Icons.history_rounded,
                          title: 'Activity Log',
                          subtitle: 'Keep track of your account activity',
                          hasSwitch: true,
                          switchValue: _isActivityLogEnabled,
                          onSwitchChanged: (value) {
                            setState(() => _isActivityLogEnabled = value);
                          },
                          gradient: [Color(0xFFFF5F6D), Color(0xFFFFC371)],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildGlassSection(
                      title: 'Account Recovery',
                      items: [
                        _buildGlassItem(
                          icon: Icons.email_rounded,
                          title: 'Recovery Email',
                          subtitle: 'Set up email for account recovery',
                          onTap: () {},
                          gradient: [Color(0xFF11998E), Color(0xFF38EF7D)],
                        ),
                        _buildGlassItem(
                          icon: Icons.phone_rounded,
                          title: 'Recovery Phone',
                          subtitle: 'Add phone number for account recovery',
                          onTap: () {},
                          gradient: [Color(0xFF396afc), Color(0xFF2948ff)],
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _buildGlassyDeleteButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildGlassHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 18),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4A90E2), Color(0xFF357AE8)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4A90E2).withOpacity(0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  AppLocalizations.of(context).translate('account_security'),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Manage your security settings and privacy preferences',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF7B8A9A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildGlassSection({
    required String title,
    required List<Widget> items,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.65),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
                ...items,
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildGlassItem({
    required IconData icon,
    required String title,
    required String subtitle,
    bool hasSwitch = false,
    bool? switchValue,
    Function(bool)? onSwitchChanged,
    VoidCallback? onTap,
    required List<Color> gradient,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasSwitch ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withOpacity(0.10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.first.withOpacity(0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7B8A9A),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasSwitch)
                _CustomSwitch(
                  value: switchValue ?? false,
                  onChanged: onSwitchChanged,
                  activeColor: gradient.last,
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFB0BEC5),
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildGlassyDeleteButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF5F6D), Color(0xFFFFC371)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF5F6D).withOpacity(0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.delete_forever, color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Delete Account',
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class _CustomSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color activeColor;
  const _CustomSwitch({
    Key? key,
    required this.value,
    required this.onChanged,
    required this.activeColor,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged?.call(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 44,
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: value ? activeColor.withOpacity(0.18) : Colors.grey[300],
        ),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? activeColor : Colors.white,
              boxShadow: [
                if (value)
                  BoxShadow(
                    color: activeColor.withOpacity(0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 
