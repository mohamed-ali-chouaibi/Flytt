import 'package:flutter/material.dart';
import '../utils/theme_provider.dart';
import '../utils/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}
class _SubscriptionScreenState extends State<SubscriptionScreen> 
    with TickerProviderStateMixin {
  String? _currentSubscription;
  String _selectedPlan = 'free';
  bool _isLoading = false;
  DateTime? _subscriptionStartDate;
  DateTime? _subscriptionEndDate;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  final List<Map<String, dynamic>> _subscriptionPlans = [
    {
      'id': 'free',
      'name': 'free',
      'price': '€0',
      'period': 'month',
      'description': 'standard_ride_hailing',
      'features': [
        'standard_pricing',
        'basic_customer_support',
        'standard_cancellation_policy',
        'regular_driver_matching',
      ],
      'color': RydyColors.subText,
      'popular': false,
    },
    {
      'id': 'saver',
      'name': 'saver',
      'price': '€9.99',
      'period': 'month',
      'description': 'save_on_every_ride',
      'features': [
        '10% off_all_rides',
        'priority_customer_support',
        'free_cancellations',
        'faster_driver_matching',
        'exclusive_promotions',
        'family_sharing',
      ],
      'color': RydyColors.textColor,
      'popular': true,
      'savings': 'save_month',
      'savings_amount': '15-30',
    },
    {
      'id': 'premium',
      'name': 'premium',
      'price': '€19.99',
      'period': 'month',
      'description': 'ultimate_ride_experience',
      'features': [
        '20% off_all_rides',
        'priority_support',
        'unlimited_free_cancellations',
        'instant_driver_matching',
        'exclusive_premium_vehicles',
        'family_sharing_premium',
        'monthly_ride_credits',
        'airport_priority_pickup',
      ],
      'color': RydyColors.textColor,
      'popular': false,
      'savings': 'save_month',
      'savings_amount': '40-80',
    },
  ];
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCurrentSubscription();
  }
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _fadeController.forward();
    _slideController.forward();
  }
  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }
  Future<void> _loadCurrentSubscription() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('passenger')
            .select('subscription_plan, subscription_start_date, subscription_end_date')
            .eq('uid', user.id)
            .single();
        setState(() {
          _currentSubscription = response['subscription_plan'] ?? 'free';
          _selectedPlan = _currentSubscription!;
          _subscriptionStartDate = response['subscription_start_date'] != null 
              ? DateTime.parse(response['subscription_start_date'])
              : null;
          _subscriptionEndDate = response['subscription_end_date'] != null 
              ? DateTime.parse(response['subscription_end_date'])
              : null;
        });
      }
    } catch (e) {
      print('Error loading subscription: $e');
    }
  }
  Future<void> _updateSubscription(String planId) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final now = DateTime.now();
        final endDate = now.add(const Duration(days: 30)); 
        await Supabase.instance.client
            .from('passenger')
            .update({
              'subscription_plan': planId,
              'subscription_start_date': now.toIso8601String(),
              'subscription_end_date': endDate.toIso8601String(),
            })
            .eq('uid', user.id);
        setState(() {
          _currentSubscription = planId;
          _selectedPlan = planId;
          _subscriptionStartDate = now;
          _subscriptionEndDate = endDate;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('subscription_updated_successfully')),
            backgroundColor: RydyColors.textColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error updating subscription: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('error_updating_subscription')),
          backgroundColor: RydyColors.subText,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  void _navigateToSubscriptionManagement() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => SubscriptionManagementScreen(
          currentPlan: _currentSubscription!,
          startDate: _subscriptionStartDate!,
          endDate: _subscriptionEndDate!,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final hasActiveSubscription = _currentSubscription != null && 
                                _currentSubscription != 'free' && 
                                _subscriptionEndDate != null && 
                                _subscriptionEndDate!.isAfter(DateTime.now());
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
          AppLocalizations.of(context).translate('subscription_plans'),
          style: TextStyle(
            color: RydyColors.textColor,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        centerTitle: true,
        toolbarHeight: 60,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              if (hasActiveSubscription) ...[
                _buildAnimatedSubscriptionCard(),
                const SizedBox(height: 24),
              ],
              ..._subscriptionPlans.asMap().entries.map((entry) {
                final index = entry.key;
                final plan = entry.value;
                return _buildAnimatedPlanCard(plan, index);
              }).toList(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildAnimatedSubscriptionCard() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.9 + (_fadeAnimation.value * 0.1),
          child: Container(
            padding: const EdgeInsets.all(24),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: RydyColors.textColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.star_rounded,
                        color: RydyColors.textColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context).translate('current_subscription'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: RydyColors.textColor,
                            ),
                          ),
                          Text(
                            AppLocalizations.of(context).translate(_currentSubscription!),
                            style: TextStyle(
                              fontSize: 16,
                              color: RydyColors.subText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildDateInfo(
                  'subscription_start_date',
                  _subscriptionStartDate!,
                  Icons.calendar_today_rounded,
                ),
                const SizedBox(height: 12),
                _buildDateInfo(
                  'subscription_end_date',
                  _subscriptionEndDate!,
                  Icons.event_available_rounded,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _navigateToSubscriptionManagement,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RydyColors.textColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 4,
                      shadowColor: Colors.black.withOpacity(0.2),
                    ),
                    child: Text(
                      AppLocalizations.of(context).translate('manage_subscription'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: RydyColors.darkBg,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget _buildAnimatedPlanCard(Map<String, dynamic> plan, int index) {
    final isSelected = _selectedPlan == plan['id'];
    final isCurrent = _currentSubscription == plan['id'];
    final isPopular = plan['popular'] ?? false;
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _fadeAnimation.value) * (index + 1)),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: _buildPlanCard(plan, isSelected, isCurrent, isPopular),
            ),
          ),
        );
      },
    );
  }
  Widget _buildDateInfo(String labelKey, DateTime date, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: RydyColors.textColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: RydyColors.textColor,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).translate(labelKey),
                style: TextStyle(
                  fontSize: 14,
                  color: RydyColors.subText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${date.day}/${date.month}/${date.year}',
                style: TextStyle(
                  fontSize: 16,
                  color: RydyColors.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildPlanCard(Map<String, dynamic> plan, bool isSelected, bool isCurrent, bool isPopular) {
    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: RydyColors.cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? RydyColors.textColor : RydyColors.subText.withOpacity(0.2),
              width: isSelected ? 3 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected 
                    ? RydyColors.textColor.withOpacity(0.3)
                    : Colors.black.withOpacity(0.1),
                blurRadius: isSelected ? 25 : 20,
                offset: const Offset(0, 8),
                spreadRadius: isSelected ? 2 : 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context).translate(plan['name']),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: RydyColors.textColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  if (isPopular)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: RydyColors.textColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        AppLocalizations.of(context).translate('most_popular'),
                        style: TextStyle(
                          color: RydyColors.darkBg,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    plan['price'],
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: RydyColors.textColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '/${plan['period']}',
                    style: TextStyle(
                      fontSize: 18,
                      color: RydyColors.subText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context).translate(plan['description']),
                style: TextStyle(
                  fontSize: 16,
                  color: RydyColors.subText,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              if (plan['savings'] != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: RydyColors.textColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: RydyColors.textColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    AppLocalizations.of(context).translate(plan['savings']).replaceAll('{amount}', plan['savings_amount']),
                    style: TextStyle(
                      fontSize: 14,
                      color: RydyColors.textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ...(plan['features'] as List<String>).map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: RydyColors.textColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: RydyColors.textColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context).translate(feature),
                        style: TextStyle(
                          fontSize: 15,
                          color: RydyColors.textColor,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 24),
              _buildAnimatedButton(plan, isCurrent),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildAnimatedButton(Map<String, dynamic> plan, bool isCurrent) {
    return GestureDetector(
      onTapDown: (_) {
        if (!isCurrent) {
          _scaleController.forward();
        }
      },
      onTapUp: (_) {
        if (!isCurrent) {
          _scaleController.reverse();
        }
      },
      onTapCancel: () {
        if (!isCurrent) {
          _scaleController.reverse();
        }
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isCurrent ? null : () => _updateSubscription(plan['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCurrent ? RydyColors.subText.withOpacity(0.2) : RydyColors.textColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  elevation: isCurrent ? 0 : 4,
                  shadowColor: Colors.black.withOpacity(0.2),
                ),
                child: _isLoading && _selectedPlan == plan['id']
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isCurrent ? RydyColors.subText : RydyColors.darkBg,
                          ),
                        ),
                      )
                    : Text(
                        isCurrent 
                            ? AppLocalizations.of(context).translate('current_plan')
                            : AppLocalizations.of(context).translate('select_plan'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isCurrent ? RydyColors.subText : RydyColors.darkBg,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
class SubscriptionManagementScreen extends StatefulWidget {
  final String currentPlan;
  final DateTime startDate;
  final DateTime endDate;
  const SubscriptionManagementScreen({
    Key? key,
    required this.currentPlan,
    required this.startDate,
    required this.endDate,
  }) : super(key: key);
  @override
  State<SubscriptionManagementScreen> createState() => _SubscriptionManagementScreenState();
}
class _SubscriptionManagementScreenState extends State<SubscriptionManagementScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _fadeController.forward();
    _slideController.forward();
  }
  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }
  Future<void> _cancelSubscription() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('passenger')
            .update({
              'subscription_plan': 'free',
              'subscription_start_date': null,
              'subscription_end_date': null,
            })
            .eq('id', user.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('subscription_cancelled_successfully')),
            backgroundColor: RydyColors.textColor,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error cancelling subscription: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('error_cancelling_subscription')),
          backgroundColor: RydyColors.subText,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    final daysRemaining = widget.endDate.difference(DateTime.now()).inDays;
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
          AppLocalizations.of(context).translate('manage_subscription'),
          style: TextStyle(
            color: RydyColors.textColor,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        centerTitle: true,
        toolbarHeight: 60,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: RydyColors.textColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.star_rounded,
                            color: RydyColors.textColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context).translate('current_plan'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: RydyColors.textColor,
                                ),
                              ),
                              Text(
                                AppLocalizations.of(context).translate(widget.currentPlan),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: RydyColors.subText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildDateInfo(
                      'subscription_start_date',
                      widget.startDate,
                      Icons.calendar_today_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildDateInfo(
                      'subscription_end_date',
                      widget.endDate,
                      Icons.event_available_rounded,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: daysRemaining <= 7 ? Colors.orange.withOpacity(0.1) : RydyColors.textColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: daysRemaining <= 7 ? Colors.orange.withOpacity(0.3) : RydyColors.textColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            daysRemaining <= 7 ? Icons.warning_rounded : Icons.info_rounded,
                            color: daysRemaining <= 7 ? Colors.orange : RydyColors.textColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              daysRemaining <= 0 
                                  ? AppLocalizations.of(context).translate('subscription_expired')
                                  : AppLocalizations.of(context).translate('days_remaining').replaceAll('{days}', daysRemaining.toString()),
                              style: TextStyle(
                                color: daysRemaining <= 7 ? Colors.orange : RydyColors.textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).translate('subscription_actions'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: RydyColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildAnimatedActionButton(
                      icon: Icons.cancel_rounded,
                      title: 'cancel_subscription',
                      subtitle: 'cancel_subscription_desc',
                      onTap: _showCancelConfirmation,
                      isDestructive: true,
                    ),
                    const SizedBox(height: 16),
                    _buildAnimatedActionButton(
                      icon: Icons.help_outline_rounded,
                      title: 'subscription_help',
                      subtitle: 'subscription_help_desc',
                      onTap: () {
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildDateInfo(String labelKey, DateTime date, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: RydyColors.textColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: RydyColors.textColor,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).translate(labelKey),
                style: TextStyle(
                  fontSize: 14,
                  color: RydyColors.subText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${date.day}/${date.month}/${date.year}',
                style: TextStyle(
                  fontSize: 16,
                  color: RydyColors.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildAnimatedActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (value * 0.1),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDestructive ? Colors.red.withOpacity(0.1) : RydyColors.darkBg.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDestructive ? Colors.red.withOpacity(0.3) : RydyColors.subText.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDestructive ? Colors.red.withOpacity(0.2) : RydyColors.textColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: isDestructive ? Colors.red : RydyColors.textColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).translate(title),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDestructive ? Colors.red : RydyColors.textColor,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context).translate(subtitle),
                          style: TextStyle(
                            fontSize: 14,
                            color: RydyColors.subText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: isDestructive ? Colors.red : RydyColors.subText,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RydyColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppLocalizations.of(context).translate('cancel_subscription_confirm_title'),
          style: TextStyle(
            color: RydyColors.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          AppLocalizations.of(context).translate('cancel_subscription_confirm_message'),
          style: TextStyle(
            color: RydyColors.subText,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context).translate('cancel'),
              style: TextStyle(color: RydyColors.subText),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelSubscription();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              AppLocalizations.of(context).translate('confirm_cancel'),
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
} 
