import 'dart:ui';
import 'package:flutter/material.dart';
import 'add_card_screen.dart';
import '../passenger/passenger_home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/theme_provider.dart';
import '../utils/app_localizations.dart';
import '../passenger/choose_payment_method_screen.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
const Map<String, String> countryToCurrency = {
  'TN': 'TND',
  'FR': 'EUR',
  'CH': 'CHF',
  'DE': 'EUR',
  'US': 'USD',
};
String getCountryCodeFromPhone(String phoneNumber) {
  try {
    final phone = PhoneNumber.parse(phoneNumber);
    return phone.isoCode?.toString() ?? 'TN';
  } catch (_) {
    return 'TN';
  }
}
String getCurrencyFromPhone(String phoneNumber) {
  final countryCode = getCountryCodeFromPhone(phoneNumber);
  return countryToCurrency[countryCode] ?? 'TND';
}
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({Key? key}) : super(key: key);
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}
class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'cash';
  String? _selectedCardId;
  bool _isProcessing = false;
  List<Map<String, dynamic>> _savedCards = [];
  bool _isLoadingCards = true;
  Map<String, dynamic>? _wallet;
  bool _isLoadingWallet = true;
  @override
  void initState() {
    super.initState();
    _loadSavedCards();
    _loadWalletData();
  }
  Future<void> _loadSavedCards() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('payment_cards')
            .select('*')
            .eq('passenger_uid', user.id)
            .order('is_default', ascending: false);
        setState(() {
          _savedCards = List<Map<String, dynamic>>.from(response);
          _isLoadingCards = false;
        });
        if (_savedCards.isNotEmpty) {
          final defaultCard = _savedCards.firstWhere(
            (card) => card['is_default'] == true,
            orElse: () => _savedCards.first,
          );
          setState(() {
            _selectedCardId = defaultCard['id'];
            _selectedMethod = 'card';
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingCards = false;
      });
    }
  }
  Future<void> _loadWalletData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final walletResponse = await Supabase.instance.client
            .from('passenger_wallets')
            .select('*')
            .eq('passenger_uid', user.id)
            .maybeSingle();
        if (walletResponse != null) {
          setState(() {
            _wallet = walletResponse;
            _isLoadingWallet = false;
          });
        } else {
          final currency = getCurrencyFromPhone(user.phone ?? '');
          final newWallet = await Supabase.instance.client
              .from('passenger_wallets')
              .insert({
                'passenger_uid': user.id,
                'balance': 0.0,
                'currency': currency,
              })
              .select()
              .single();
          setState(() {
            _wallet = newWallet;
            _isLoadingWallet = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingWallet = false;
      });
    }
  }
  String _getCardTypeIcon(String? cardType) {
    switch (cardType?.toLowerCase()) {
      case 'visa':
        return 'assets/cards/visa.png';
      case 'mastercard':
        return 'assets/cards/mastercard.png';
      case 'amex':
        return 'assets/cards/amex.png';
      case 'discover':
        return 'assets/cards/discover.png';
      case 'paypal':
        return 'assets/cards/paypal.png';
      default:
        return 'assets/cards/visa.png';
    }
  }
  String? _getCardIcon(String? cardType) {
    switch (cardType?.toLowerCase()) {
      case 'visa':
        return 'assets/cards/visa.png';
      case 'mastercard':
        return 'assets/cards/mastercard.png';
      case 'amex':
        return 'assets/cards/amex.png';
      case 'discover':
        return 'assets/cards/discover.png';
      case 'paypal':
        return 'assets/cards/paypal.png';
      default:
        return null; 
    }
  }
  String _getCardDisplayNumber(String cardNumber) {
    if (cardNumber.length >= 4) {
      return '**** ${cardNumber.substring(cardNumber.length - 4)}';
    }
    return cardNumber;
  }
  @override
  Widget build(BuildContext context) {
    final darkBg = RydyColors.darkBg;
    final cardBg = RydyColors.cardBg;
    final textColor = RydyColors.textColor;
    final subText = RydyColors.subText;
    final walletBalance = _wallet?['balance'] ?? 0.0;
    final currency = _wallet?['currency'] ?? 'TND';
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(AppLocalizations.of(context).translate('wallet'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: darkBg,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: textColor),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 28),
            decoration: BoxDecoration(
              color: cardBg.withOpacity(0.85),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: RydyColors.cardBg.withOpacity(0.18), width: 1.5),
              boxShadow: [
                BoxShadow(color: RydyColors.cardBg.withOpacity(0.10), blurRadius: 32, offset: const Offset(0, 12)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                color: darkBg.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(AppLocalizations.of(context).translate('balance'), style: TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '$currency ${walletBalance.toStringAsFixed(2)}', 
                              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: textColor, letterSpacing: 1.8)
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedMethod == 'cash' 
                                ? AppLocalizations.of(context).translate('not_available_cash')
                                : AppLocalizations.of(context).translate('available_for_payments'),
                              style: TextStyle(color: subText, fontSize: 13, fontStyle: FontStyle.italic)
                            ),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        backgroundColor: darkBg.withOpacity(0.18),
                        child: Icon(Icons.account_balance_wallet, color: textColor, size: 34),
                        radius: 32,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(backgroundColor: cardBg, child: Icon(Icons.help_outline, color: textColor, size: 28)),
                  title: Text(AppLocalizations.of(context).translate('what_is_balance'), style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                  subtitle: Text(AppLocalizations.of(context).translate('learn_more_balance'), style: TextStyle(color: subText, fontSize: 13, fontStyle: FontStyle.italic)),
                  onTap: () {},
                ),
                Divider(color: cardBg.withOpacity(0.5)),
                ListTile(
                  leading: CircleAvatar(backgroundColor: cardBg, child: Icon(Icons.access_time, color: textColor, size: 28)),
                  title: Text(AppLocalizations.of(context).translate('view_transactions'), style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                  subtitle: Text(AppLocalizations.of(context).translate('balance_history'), style: TextStyle(color: subText, fontSize: 13, fontStyle: FontStyle.italic)),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(AppLocalizations.of(context).translate('payment_methods'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: ListTile(
                    leading: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      child: CircleAvatar(
                        backgroundColor: _selectedMethod == 'cash' ? darkBg : cardBg,
                        child: Image.asset('assets/cards/cash.png', width: 24, height: 24),
                        radius: 24,
                      ),
                    ),
                    title: Text(AppLocalizations.of(context).translate('cash'), style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                    subtitle: Text(AppLocalizations.of(context).translate('cash_payment'), style: TextStyle(color: subText, fontSize: 13)),
                    trailing: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _selectedMethod == 'cash' ? darkBg : subText, width: 2),
                        color: _selectedMethod == 'cash' ? darkBg : Colors.transparent,
                        boxShadow: _selectedMethod == 'cash'
                          ? [BoxShadow(color: darkBg.withOpacity(0.25), blurRadius: 8, offset: Offset(0, 2))]
                          : [],
                      ),
                      child: _selectedMethod == 'cash'
                        ? Icon(Icons.check, color: textColor, size: 18)
                        : null,
                    ),
                    onTap: () {
                      setState(() {
                        _selectedMethod = 'cash';
                        _selectedCardId = null;
                      });
                    },
                  ),
                ),
                if (_savedCards.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ..._savedCards.map((card) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    child: ListTile(
                      leading: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        child: CircleAvatar(
                          backgroundColor: _selectedMethod == 'card' && _selectedCardId == card['id'] ? darkBg : cardBg,
                          child: _getCardIcon(card['card_type']) != null
                              ? Image.asset(
                                  _getCardIcon(card['card_type'])!,
                                  width: 24,
                                  height: 24,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.credit_card, color: RydyColors.textColor, size: 24);
                                  },
                                )
                              : Icon(Icons.credit_card, color: RydyColors.textColor, size: 24),
                          radius: 24,
                        ),
                      ),
                      title: Text(
                        '${card['card_type'] ?? AppLocalizations.of(context).translate('card')} ${_getCardDisplayNumber(card['card_number'])}', 
                        style: TextStyle(color: textColor, fontWeight: FontWeight.w600)
                      ),
                      subtitle: Text(
                        '${AppLocalizations.of(context).translate('expires')} ${card['expiry_month']}/${card['expiry_year']}', 
                        style: TextStyle(color: subText, fontSize: 13)
                      ),
                      trailing: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedMethod == 'card' && _selectedCardId == card['id'] ? darkBg : subText, 
                            width: 2
                          ),
                          color: _selectedMethod == 'card' && _selectedCardId == card['id'] ? darkBg : Colors.transparent,
                          boxShadow: _selectedMethod == 'card' && _selectedCardId == card['id']
                            ? [BoxShadow(color: darkBg.withOpacity(0.25), blurRadius: 8, offset: Offset(0, 2))]
                            : [],
                        ),
                        child: _selectedMethod == 'card' && _selectedCardId == card['id']
                          ? Icon(Icons.check, color: textColor, size: 18)
                          : null,
                      ),
                      onTap: () {
                        setState(() {
                          _selectedMethod = 'card';
                          _selectedCardId = card['id'];
                        });
                      },
                    ),
                  )).toList(),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.center,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: darkBg.withOpacity(0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ChoosePaymentMethodScreen()),
                        );
                      },
                      icon: Icon(Icons.add, color: textColor, size: 24),
                      label: Text(AppLocalizations.of(context).translate('add_card'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 17)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkBg,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
} 
