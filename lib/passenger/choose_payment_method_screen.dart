import 'package:flutter/material.dart';
import '../utils/app_localizations.dart';
import '../utils/theme_provider.dart';
import 'add_card_screen.dart';
class ChoosePaymentMethodScreen extends StatelessWidget {
  const ChoosePaymentMethodScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RydyColors.darkBg,
      appBar: AppBar(
        backgroundColor: RydyColors.darkBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: RydyColors.textColor, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppLocalizations.of(context).translate('add_payment'),
          style: TextStyle(
            color: RydyColors.textColor,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        centerTitle: true,
        toolbarHeight: 72,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PaymentOption(
              imageAsset: 'assets/cards/visa.png',
              label: AppLocalizations.of(context).translate('credit_card'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AddCardScreen()),
                );
              },
            ),
            const SizedBox(height: 8),
            Divider(color: RydyColors.cardBg, thickness: 1),
            const SizedBox(height: 8),
            _PaymentOption(
              imageAsset: 'assets/cards/paypal.png',
              label: 'PayPal',
              onTap: () {},
            ),
            const SizedBox(height: 8),
            Divider(color: RydyColors.cardBg, thickness: 1),
            const SizedBox(height: 8),
            _PaymentOption(
              imageAsset: 'assets/cards/weego.png',
              label: AppLocalizations.of(context).translate('gift_card'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
class _PaymentOption extends StatelessWidget {
  final IconData? icon;
  final String? imageAsset;
  final String label;
  final VoidCallback onTap;
  const _PaymentOption({
    Key? key,
    this.icon,
    this.imageAsset,
    required this.label,
    required this.onTap,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: icon != null
                    ? Icon(icon, color: RydyColors.textColor, size: 28)
                    : imageAsset != null
                        ? Image.asset(imageAsset!, width: 28, height: 28)
                        : null,
              ),
            ),
            const SizedBox(width: 18),
            Text(
              label,
              style: TextStyle(
                color: RydyColors.textColor,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
