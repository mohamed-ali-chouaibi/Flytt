import 'package:flutter/material.dart';
import '../utils/theme_provider.dart';
import 'live_delivery_tracking_screen.dart';
class DeliveryConfirmationScreen extends StatefulWidget {
  final List<Map<String, dynamic>> deliveryAddresses;
  final String itemDescription;
  const DeliveryConfirmationScreen({
    Key? key,
    required this.deliveryAddresses,
    required this.itemDescription,
  }) : super(key: key);
  @override
  State<DeliveryConfirmationScreen> createState() => _DeliveryConfirmationScreenState();
}
class _DeliveryConfirmationScreenState extends State<DeliveryConfirmationScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeHeader;
  late final Animation<Offset> _slideHeader;
  late final Animation<double> _fadeRoute;
  late final Animation<Offset> _slideRoute;
  late final Animation<double> _fadePackages;
  late final Animation<Offset> _slidePackages;
  late final Animation<double> _fadePricing;
  late final Animation<Offset> _slidePricing;
  late final Animation<double> _fadeIncluded;
  late final Animation<Offset> _slideIncluded;
  late final Animation<double> _fadeButton;
  late final Animation<Offset> _slideButton;
  final Map<String, double> _packagePrices = {
    'Small': 11.0,
    'Medium': 13.0,
    'Large': 15.0,
    'X-Large': 18.0,
  };
  double get _subtotal {
    double total = 0;
    for (var delivery in widget.deliveryAddresses) {
      final String packageSize = delivery['packageSize'] as String;
      final int quantity = delivery['quantity'] as int;
      total += (_packagePrices[packageSize] ?? 0) * quantity;
    }
    return total;
  }
  int get _totalPackages {
    return widget.deliveryAddresses.fold(0, (sum, delivery) => sum + (delivery['quantity'] as int));
  }
  double get _volumeDiscount {
    if (_subtotal >= 100.0) {
      return ((_subtotal / 100).floor() * 10.0);
    } else if (_totalPackages >= 5) {
      return _totalPackages * 1.0;
    }
    return 0.0;
  }
  double get _totalPrice => (_subtotal - _volumeDiscount).clamp(0, double.infinity);
  List<int> get _segmentEtas {
    final int stops = widget.deliveryAddresses.length;
    if (stops <= 0) return [];
    final List<int> etas = [];
    int base = 5;
    for (int i = 0; i < stops; i++) {
      etas.add(base);
      base += (i == 0 ? 3 : 4); 
    }
    return etas;
  }
  int get _totalEtaMinutes {
    if (_segmentEtas.isEmpty) return 0;
    return _segmentEtas.fold(0, (a, b) => a + b);
  }
  List<Widget> _buildTimelineEntries() {
    final List<Widget> widgets = [];
    final List<int> etas = _segmentEtas;
    widgets.add(Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.circle_outlined, color: RydyColors.textColor, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Your Location',
            style: TextStyle(color: RydyColors.textColor, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ));
    if (etas.isNotEmpty) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(left: 22, top: 4, bottom: 8),
        child: Text('↓ ${etas.first} min', style: TextStyle(color: RydyColors.subText, fontSize: 13)),
      ));
    }
    for (int i = 0; i < widget.deliveryAddresses.length; i++) {
      final delivery = widget.deliveryAddresses[i];
      final bool isLast = i == widget.deliveryAddresses.length - 1;
      final String packageSize = (delivery['packageSize'] ?? '').toString();
      final double unitPrice = _packagePrices[packageSize] ?? 0;
      final String packageName = (delivery['packageName'] ?? '').toString().trim();
      final String address = (delivery['address'] ?? '').toString();
      final String label = packageName.isNotEmpty ? packageName : address;
      widgets.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isLast ? Icons.circle : Icons.circle_outlined, color: RydyColors.textColor, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label - $packageSize ${unitPrice.toStringAsFixed(0)}',
              style: TextStyle(color: RydyColors.textColor, fontSize: 14),
            ),
          ),
        ],
      ));
      if (!isLast && i + 1 < etas.length) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 22, top: 4, bottom: 8),
          child: Text('↓ ${etas[i + 1]} min', style: TextStyle(color: RydyColors.subText, fontSize: 13)),
        ));
      }
    }
    return widgets;
  }
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeHeader = CurvedAnimation(parent: _animationController, curve: const Interval(0.00, 0.40, curve: Curves.easeOut));
    _slideHeader = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animationController, curve: const Interval(0.00, 0.40, curve: Curves.easeOut)));
    _fadeRoute = CurvedAnimation(parent: _animationController, curve: const Interval(0.10, 0.50, curve: Curves.easeOut));
    _slideRoute = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animationController, curve: const Interval(0.10, 0.50, curve: Curves.easeOut)));
    _fadePackages = CurvedAnimation(parent: _animationController, curve: const Interval(0.20, 0.60, curve: Curves.easeOut));
    _slidePackages = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animationController, curve: const Interval(0.20, 0.60, curve: Curves.easeOut)));
    _fadePricing = CurvedAnimation(parent: _animationController, curve: const Interval(0.30, 0.70, curve: Curves.easeOut));
    _slidePricing = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animationController, curve: const Interval(0.30, 0.70, curve: Curves.easeOut)));
    _fadeIncluded = CurvedAnimation(parent: _animationController, curve: const Interval(0.40, 0.80, curve: Curves.easeOut));
    _slideIncluded = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animationController, curve: const Interval(0.40, 0.80, curve: Curves.easeOut)));
    _fadeButton = CurvedAnimation(parent: _animationController, curve: const Interval(0.60, 1.00, curve: Curves.easeOut));
    _slideButton = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animationController, curve: const Interval(0.60, 1.00, curve: Curves.easeOut)));
    _animationController.forward();
  }
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RydyColors.darkBg,
      appBar: AppBar(
        backgroundColor: RydyColors.darkBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: RydyColors.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Confirm Delivery',
          style: TextStyle(
            color: RydyColors.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeTransition(
                      opacity: _fadeHeader,
                      child: SlideTransition(
                        position: _slideHeader,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: RydyColors.cardBg,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.access_time, color: RydyColors.textColor, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Delivery Timeline',
                                    style: TextStyle(
                                      color: RydyColors.textColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 19,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ..._buildTimelineEntries(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeTransition(
                      opacity: _fadeRoute,
                      child: SlideTransition(
                        position: _slideRoute,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: RydyColors.cardBg,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.inventory_2, color: RydyColors.textColor, size: 18),
                                  const SizedBox(width: 8),
                                  Text('$_totalPackages packages', style: TextStyle(color: RydyColors.textColor, fontSize: 15, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.attach_money, color: RydyColors.textColor, size: 18),
                                  const SizedBox(width: 8),
                                  Text('£${_totalPrice.toStringAsFixed(2)} total', style: TextStyle(color: RydyColors.textColor, fontSize: 15)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.schedule, color: RydyColors.textColor, size: 18),
                                  const SizedBox(width: 8),
                                  Text('${_totalEtaMinutes} minutes', style: TextStyle(color: RydyColors.textColor, fontSize: 15)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: _fadePackages,
                      child: SlideTransition(
                        position: _slidePackages,
                        child: _buildSectionCard(
                          title: 'Included:',
                          icon: Icons.check_circle,
                          child: Column(
                            children: [
                              _buildIncludedItem('Live tracking'),
                              _buildIncludedItem('Package protection'),
                              _buildIncludedItem('Instant updates'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: _fadePricing,
                      child: SlideTransition(
                        position: _slidePricing,
                        child: _buildSectionCard(
                          title: 'Pricing:',
                          icon: Icons.money,
                          child: Column(
                            children: [
                              _buildPricingRow('Subtotal:', '£${_subtotal.toStringAsFixed(2)}', false),
                              if (_volumeDiscount > 0)
                                _buildPricingRow('Discount:', '-£${_volumeDiscount.toStringAsFixed(2)}', false),
                              const Divider(color: RydyColors.dividerColor, height: 20),
                              _buildPricingRow('Total:', '£${_totalPrice.toStringAsFixed(2)}', true),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: _fadeIncluded,
                      child: SlideTransition(
                        position: _slideIncluded,
                        child: _buildSectionCard(
                      title: 'Included:',
                      icon: Icons.check_circle,
                      child: Column(
                        children: [
                          _buildIncludedItem('One driver, optimized route'),
                          _buildIncludedItem('Live GPS tracking'),
                          _buildIncludedItem('30-45 minute delivery'),
                          _buildIncludedItem('Package insurance'),
                        ],
                      ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            FadeTransition(
              opacity: _fadeButton,
              child: SlideTransition(
                position: _slideButton,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: Container(
                      decoration: BoxDecoration(
                        color: RydyColors.cardBg,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: ElevatedButton(
                        onPressed: _processPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'PAY £${_totalPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: RydyColors.textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RydyColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: RydyColors.textColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: RydyColors.textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 19,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
  Widget _buildPricingRow(String label, String value, bool isTotal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? RydyColors.textColor : RydyColors.subText,
              fontSize: isTotal ? 15 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isTotal ? RydyColors.textColor : RydyColors.subText,
              fontSize: isTotal ? 15 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildIncludedItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(Icons.check, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: RydyColors.textColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  void _processPayment() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: RydyColors.cardBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: RydyColors.textColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Processing Payment...',
                style: TextStyle(
                  color: RydyColors.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pop(context); 
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LiveDeliveryTrackingScreen(
            deliveryAddresses: widget.deliveryAddresses,
            driverInfo: {
              'name': 'Pierre',
              'rating': 4.92,
              'vehicle': 'Toyota Corolla',
              'plate': '257 TU',
            },
          ),
        ),
      );
    });
  }
}
