import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/theme_provider.dart';
import '../utils/app_localizations.dart';
import 'passenger_home_screen.dart';
class AddCardScreen extends StatefulWidget {
  final bool redirectToHome;
  const AddCardScreen({Key? key, this.redirectToHome = false}) : super(key: key);
  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}
class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();
  bool _isLoading = false;
  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    super.dispose();
  }
  String _formatCardNumber(String input) {
    if (input.isEmpty) return input;
    input = input.replaceAll(RegExp(r'\D'), '');
    final chunks = <String>[];
    for (var i = 0; i < input.length; i += 4) {
      chunks.add(input.substring(i, i + 4 > input.length ? input.length : i + 4));
    }
    return chunks.join(' ');
  }
  String _formatExpiry(String input) {
    if (input.isEmpty) return input;
    input = input.replaceAll(RegExp(r'\D'), '');
    if (input.length >= 2) {
      return '${input.substring(0, 2)}/${input.substring(2)}';
    }
    return input;
  }
  bool _isValidCardNumber(String number) {
    number = number.replaceAll(RegExp(r'\D'), '');
    if (number.length != 16) return false;
    int sum = 0;
    bool alternate = false;
    for (int i = number.length - 1; i >= 0; i--) {
      int n = int.parse(number[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) {
          n = (n % 10) + 1;
        }
      }
      sum += n;
      alternate = !alternate;
    }
    return (sum % 10 == 0);
  }
  bool _isValidExpiry(String expiry) {
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(expiry)) return false;
    final parts = expiry.split('/');
    final month = int.parse(parts[0]);
    final year = int.parse(parts[1]);
    if (month < 1 || month > 12) return false;
    final now = DateTime.now();
    final currentYear = now.year % 100; 
    final currentMonth = now.month;
    if (year < currentYear || (year == currentYear && month < currentMonth)) {
      return false;
    }
    return true;
  }
  String _detectCardType(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (cleanNumber.startsWith('4')) {
      return 'visa';
    }
    else if (RegExp(r'^5[1-5]').hasMatch(cleanNumber) || 
             RegExp(r'^2[2-7][2-9][0-9]').hasMatch(cleanNumber)) {
      return 'mastercard';
    }
    else if (RegExp(r'^3[47]').hasMatch(cleanNumber)) {
      return 'amex';
    }
    else if (cleanNumber.startsWith('6011') || 
             RegExp(r'^622[1-9][2-6][0-9]').hasMatch(cleanNumber) ||
             RegExp(r'^64[4-9]').hasMatch(cleanNumber) ||
             cleanNumber.startsWith('65')) {
      return 'discover';
    }
    return 'unknown';
  }
  String _getCardTypeDisplayName(String cardType) {
    switch (cardType) {
      case 'visa':
        return 'Visa';
      case 'mastercard':
        return 'Mastercard';
      case 'amex':
        return 'American Express';
      case 'discover':
        return 'Discover';
      default:
        return AppLocalizations.of(context).translate('unknown_card');
    }
  }
  String? _getCardIcon(String cardType) {
    switch (cardType) {
      case 'visa':
        return 'assets/cards/visa.png';
      case 'mastercard':
        return 'assets/cards/mastercard.png';
      case 'amex':
        return 'assets/cards/amex.png';
      case 'discover':
        return 'assets/cards/discover.png';
      default:
        return null; 
    }
  }
  Future<void> _addCard() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      final cardNumber = _cardNumberController.text.replaceAll(RegExp(r'\D'), '');
      final lastFourDigits = cardNumber.substring(cardNumber.length - 4);
      final expiryParts = _expiryController.text.split('/');
      final expiryMonth = int.parse(expiryParts[0]);
      final expiryYear = int.parse(expiryParts[1]);
      final cardType = _detectCardType(cardNumber);
      final existingCards = await Supabase.instance.client
          .from('payment_cards')
          .select('id')
          .eq('passenger_uid', user.id);
      final isDefault = existingCards.isEmpty;
      await Supabase.instance.client
          .from('payment_cards')
          .insert({
            'passenger_uid': user.id,
            'card_number': lastFourDigits, 
            'expiry_month': expiryMonth,
            'expiry_year': expiryYear,
            'card_type': cardType,
            'is_default': isDefault,
          });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('card_added_successfully')),
            backgroundColor: RydyColors.cardBg,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (widget.redirectToHome) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const PassengerHomeScreen()),
          (route) => false,
        );
      } else {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).translate('error_adding_card')}: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  InputDecoration _inputDecoration({String? hint, IconData? icon, String? errorText}) {
    return InputDecoration(
      filled: true,
      fillColor: RydyColors.cardBg,
      prefixIcon: icon != null
          ? Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: RydyColors.cardBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: RydyColors.textColor, size: 24),
            )
          : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      hintText: hint,
      hintStyle: TextStyle(color: RydyColors.subText, fontWeight: FontWeight.w500),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      errorText: errorText,
      errorStyle: const TextStyle(color: Colors.red),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: RydyColors.cardBg, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RydyColors.darkBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).translate('add_new_debit_credit_card'),
          style: TextStyle(
            color: RydyColors.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          )
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: RydyColors.darkBg,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: RydyColors.textColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            const SizedBox(height: 80),
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context).translate('enter_card_details'),
                    style: TextStyle(
                      color: RydyColors.subText,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Montserrat',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: RydyColors.cardBg,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).translate('card_information'),
                    style: TextStyle(
                      color: RydyColors.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _cardNumberController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(
                      hint: AppLocalizations.of(context).translate('card_number'),
                      icon: Icons.credit_card,
                    ),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: RydyColors.textColor
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _cardNumberController.text = _formatCardNumber(value);
                        _cardNumberController.selection = TextSelection.fromPosition(
                          TextPosition(offset: _cardNumberController.text.length),
                        );
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context).translate('please_enter_card_number');
                      }
                      if (!_isValidCardNumber(value)) {
                        return AppLocalizations.of(context).translate('please_enter_valid_card_number');
                      }
                      return null;
                    },
                  ),
                  if (_cardNumberController.text.replaceAll(RegExp(r'\D'), '').length >= 6) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: RydyColors.darkBg.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: RydyColors.textColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _getCardIcon(_detectCardType(_cardNumberController.text)) != null
                              ? Image.asset(
                                  _getCardIcon(_detectCardType(_cardNumberController.text))!,
                                  width: 24,
                                  height: 16,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.credit_card,
                                      size: 16,
                                      color: RydyColors.textColor,
                                    );
                                  },
                                )
                              : Icon(
                                  Icons.credit_card,
                                  size: 16,
                                  color: RydyColors.textColor,
                                ),
                          const SizedBox(width: 8),
                          Text(
                            _getCardTypeDisplayName(_detectCardType(_cardNumberController.text)),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: RydyColors.textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _expiryController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(
                            hint: AppLocalizations.of(context).translate('mm_yy'),
                            icon: Icons.date_range,
                          ),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: RydyColors.textColor
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _expiryController.text = _formatExpiry(value);
                              _expiryController.selection = TextSelection.fromPosition(
                                TextPosition(offset: _expiryController.text.length),
                              );
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context).translate('required');
                            }
                            if (!_isValidExpiry(value)) {
                              return AppLocalizations.of(context).translate('invalid_expiry_date');
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextFormField(
                          controller: _cvcController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(
                            hint: AppLocalizations.of(context).translate('cvc'),
                            icon: Icons.lock_outline,
                          ),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: RydyColors.textColor
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context).translate('required');
                            }
                            if (value.length != 3) {
                              return AppLocalizations.of(context).translate('invalid_cvc');
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? MediaQuery.of(context).viewInsets.bottom + 16 : 24,
        ),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _addCard,
            style: ElevatedButton.styleFrom(
              backgroundColor: RydyColors.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              padding: const EdgeInsets.symmetric(vertical: 18),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: RydyColors.textColor,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    AppLocalizations.of(context).translate('add_card'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: RydyColors.textColor
                    )
                  ),
          ),
        ),
      ),
    );
  }
} 
