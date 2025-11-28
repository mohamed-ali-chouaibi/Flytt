import 'package:flutter/material.dart';
import '../utils/theme_provider.dart';
import '../utils/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
class Promotion {
  final String id;
  final String code;
  final int percent;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String? passengerId;
  final DateTime? usedAt;
  Promotion({
    required this.id,
    required this.code,
    required this.percent,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    this.passengerId,
    this.usedAt,
  });
  static Promotion? active;
  factory Promotion.fromMap(Map<String, dynamic> map) {
    return Promotion(
      id: map['id'],
      code: map['code'],
      percent: map['percent'],
      title: map['title'],
      description: map['description'],
      startDate: DateTime.parse(map['start_date']),
      endDate: DateTime.parse(map['end_date']),
      isActive: map['is_active'] ?? true,
      passengerId: map['passenger_id'],
      usedAt: map['used_at'] != null ? DateTime.parse(map['used_at']) : null,
    );
  }
  bool get isValid {
    final now = DateTime.now();
    return isActive && now.isAfter(startDate) && now.isBefore(endDate);
  }
  bool get isExpired {
    final now = DateTime.now();
    return now.isAfter(endDate);
  }
}
class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({Key? key}) : super(key: key);
  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}
class _PromotionsScreenState extends State<PromotionsScreen> {
  final TextEditingController _promoController = TextEditingController();
  bool _isLoading = false;
  List<Promotion> _promotions = [];
  List<Promotion> _activePromotions = [];
  List<Promotion> _expiredPromotions = [];
  bool _isLoadingPromotions = true;
  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }
  Future<void> _loadPromotions() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('promotions')
            .select('*')
            .order('created_at', ascending: false);
        setState(() {
          _promotions = (response as List)
              .map((promo) => Promotion.fromMap(promo))
              .toList();
          _activePromotions = _promotions.where((p) => p.isValid).toList();
          _expiredPromotions = _promotions.where((p) => p.isExpired).toList();
          _isLoadingPromotions = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingPromotions = false;
      });
    }
  }
  Future<void> _applyPromoCode() async {
    if (_promoController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final code = _promoController.text.trim().toUpperCase();
        final response = await Supabase.instance.client
            .from('promotions')
            .select('*')
            .eq('code', code)
            .eq('is_active', true)
            .single();
        final promotion = Promotion.fromMap(response);
        if (!promotion.isValid) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('This promotion code is not valid or has expired.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        if (promotion.passengerId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You have already used this promotion code.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        await Supabase.instance.client
            .from('promotions')
            .update({
              'passenger_id': user.id,
              'used_at': DateTime.now().toIso8601String(),
            })
            .eq('id', promotion.id);
        Promotion.active = promotion;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Promotion ${promotion.code} applied successfully! ${promotion.percent}% discount activated.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _promoController.clear();
        _loadPromotions(); 
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid promotion code. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  Future<void> _activatePromotion(Promotion promotion) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        if (promotion.passengerId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You have already used this promotion.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        await Supabase.instance.client
            .from('promotions')
            .update({
              'passenger_id': user.id,
              'used_at': DateTime.now().toIso8601String(),
            })
            .eq('id', promotion.id);
        Promotion.active = promotion;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Promotion ${promotion.code} activated! ${promotion.percent}% discount applied.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadPromotions(); 
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to activate promotion. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: RydyColors.darkBg,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: RydyColors.darkBg,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    return Scaffold(
      backgroundColor: RydyColors.darkBg,
      appBar: AppBar(
        backgroundColor: RydyColors.darkBg,
        foregroundColor: RydyColors.textColor,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: CircleAvatar(
            backgroundColor: RydyColors.darkBg,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: RydyColors.textColor),
              onPressed: () => Navigator.of(context).pop(),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
            ),
          ),
        ),
        title: Text(
          AppLocalizations.of(context).translate('promotions'),
          style: TextStyle(
            color: RydyColors.textColor,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        centerTitle: true,
        toolbarHeight: 60,
        shadowColor: Colors.transparent,
      ),
      body: _isLoadingPromotions
          ? Center(
              child: CircularProgressIndicator(
                color: RydyColors.textColor,
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: RydyColors.cardBg.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.local_offer_rounded,
                              color: RydyColors.textColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context).translate('add_promo_code'),
                            style: TextStyle(
                              color: RydyColors.textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _promoController,
                        style: TextStyle(
                          color: RydyColors.textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        cursorColor: RydyColors.textColor,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context).translate('enter_promo_code'),
                          hintStyle: TextStyle(
                            color: RydyColors.subText,
                            fontWeight: FontWeight.w500,
                          ),
                          filled: true,
                          fillColor: RydyColors.darkBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: RydyColors.textColor, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _applyPromoCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: RydyColors.darkBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: RydyColors.textColor,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  AppLocalizations.of(context).translate('apply_code'),
                                  style: TextStyle(
                                    color: RydyColors.textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                if (_activePromotions.isNotEmpty) ...[
                  Text(
                    AppLocalizations.of(context).translate('active_promotions'),
                    style: TextStyle(
                      color: RydyColors.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ..._activePromotions.map((promotion) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildPromoCard(promotion),
                  )).toList(),
                ],
                const SizedBox(height: 32),
                if (_expiredPromotions.isNotEmpty) ...[
                  Text(
                    AppLocalizations.of(context).translate('expired_promotions'),
                    style: TextStyle(
                      color: RydyColors.subText,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ..._expiredPromotions.map((promotion) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildExpiredPromoCard(promotion),
                  )).toList(),
                ],
                if (_activePromotions.isEmpty && _expiredPromotions.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.local_offer_outlined,
                          size: 64,
                          color: RydyColors.subText.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context).translate('no_promotions_available'),
                          style: TextStyle(
                            color: RydyColors.subText,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
  Widget _buildPromoCard(Promotion promotion) {
    final isUsed = promotion.passengerId != null;
    final accentColor = isUsed ? RydyColors.subText : RydyColors.textColor;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RydyColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isUsed ? Icons.check_circle : Icons.local_offer_rounded,
              color: accentColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promotion.code,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: RydyColors.textColor,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  promotion.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: RydyColors.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${promotion.percent}% ${AppLocalizations.of(context).translate('off')} • ${AppLocalizations.of(context).translate('valid_until')} ${_formatDate(promotion.endDate)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: RydyColors.subText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (promotion.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    promotion.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: RydyColors.subText.withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isUsed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                AppLocalizations.of(context).translate('used'),
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            )
          else
            TextButton(
              onPressed: () => _activatePromotion(promotion),
              style: TextButton.styleFrom(
                backgroundColor: RydyColors.cardBg,
                foregroundColor: RydyColors.textColor,
                overlayColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                AppLocalizations.of(context).translate('apply'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: RydyColors.textColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
  Widget _buildExpiredPromoCard(Promotion promotion) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RydyColors.cardBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: RydyColors.subText.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: RydyColors.subText.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.local_offer_rounded, color: RydyColors.subText, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promotion.code,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: RydyColors.subText,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  promotion.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: RydyColors.subText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${AppLocalizations.of(context).translate('expired_on')} ${_formatDate(promotion.endDate)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: RydyColors.subText.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: RydyColors.subText.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              AppLocalizations.of(context).translate('expired'),
              style: TextStyle(
                color: RydyColors.subText,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 
