import 'package:flutter/material.dart';
import '../utils/theme_provider.dart';
import '../utils/delivery_flow.dart';
import 'delivery_map_full_screen.dart';
import 'delivery_complete_screen.dart';
import '../utils/animated_check.dart';
class LiveDeliveryTrackingScreen extends StatelessWidget {
  final List<Map<String, dynamic>>? deliveryAddresses;
  final Map<String, dynamic>? driverInfo;
  const LiveDeliveryTrackingScreen({Key? key, this.deliveryAddresses, this.driverInfo}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final String driverName = (driverInfo?['name'] ?? 'Pierre').toString();
    final double rating = (driverInfo?['rating'] ?? 4.9).toDouble();
    final String vehicle = (driverInfo?['vehicle'] ?? 'Toyota Corolla').toString();
    final String plate = (driverInfo?['plate'] ?? '257 TU').toString();
    return Scaffold(
      backgroundColor: RydyColors.darkBg,
      appBar: AppBar(
        backgroundColor: RydyColors.darkBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: RydyColors.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Live Delivery Tracking',
          style: TextStyle(
            color: RydyColors.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 4),
                  _GradientHeader(
                    title: 'Delivery Overview',
                    children: const [
                      _HeaderStat(title: '📦 Delivered', value: '2/4'),
                      _HeaderStat(title: '⏱️ Elapsed', value: '15m'),
                      _HeaderStat(title: '📏 Completed', value: '4.3km'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _DriverCard(
                    driverName: driverName,
                    rating: rating,
                    vehicle: vehicle,
                    plate: plate,
                    phone: '+33 6 12 34 56 78',
                  ),
                  const SizedBox(height: 16),
                  const _DestinationCard(
                    title: '🎯 Current Destination',
                    subtitle: 'John - 12 minutes away',
                    details: '3.2 km • ETA 2:33 PM',
                    progress: 0.62,
                  ),
                  const SizedBox(height: 16),
                  const _StatusList(
                    title: '📋 Package Status',
                    items: [
                      _StatusItem(text: 'Maria', sub: 'Delivered 2:15 PM', icon: 'done', tone: _StatusTone.success),
                      _StatusItem(text: 'Office', sub: 'Delivered 2:21 PM', icon: 'done', tone: _StatusTone.success),
                      _StatusItem(text: 'John', sub: 'In transit - 12 min', icon: '🚗', tone: _StatusTone.info),
                      _StatusItem(text: 'Sarah', sub: 'Next - 19 min', icon: '⏳', tone: _StatusTone.muted),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
          decoration: BoxDecoration(
            color: RydyColors.darkBg,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, -2),
                blurRadius: 10,
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: Container(
              decoration: BoxDecoration(
                color: RydyColors.cardBg,
                borderRadius: BorderRadius.circular(28),
              ),
              child: ElevatedButton(
                onPressed: () => _openMap(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Open Map',
                      style: TextStyle(
                        color: RydyColors.textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.map, color: RydyColors.textColor, size: 22),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DeliveryCompleteScreen()),
          ),
          backgroundColor: RydyColors.cardBg,
          label: const Text('Test Complete', style: TextStyle(color: RydyColors.textColor)),
          icon: const Icon(Icons.check_circle, color: RydyColors.textColor),
        ),
      ),
    );
  }
  void _openMap(BuildContext context) {
    final Stream<bool> allDeliveredStream = _mockAllDeliveredStream();
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) => DeliveryMapFullScreen(allDeliveredStream: allDeliveredStream),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(curved),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
  Future<void> completeIfAllDelivered(BuildContext context) async {
    await DeliveryFlowGuard.navigateToCompletionIfDone(context, deliveryAddresses);
  }
  Stream<bool> _mockAllDeliveredStream() async* {
    yield false;
    await Future.delayed(const Duration(seconds: 2));
    yield false;
    await Future.delayed(const Duration(seconds: 1));
    yield true;
  }
}
class _GradientHeader extends StatelessWidget {
  final String title;
  final List<_HeaderStat> children;
  const _GradientHeader({required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: RydyColors.cardBg,
        border: Border.all(color: RydyColors.dividerColor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 10),
          Row(
            children: children
                .map((e) => Expanded(child: e))
                .toList(),
          ),
        ],
      ),
    );
  }
}
class _HeaderStat extends StatelessWidget {
  final String title;
  final String value;
  const _HeaderStat({required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: RydyColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: RydyColors.subText.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: RydyColors.textColor,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: RydyColors.subText,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
class _DriverCard extends StatelessWidget {
  final String driverName;
  final double rating;
  final String vehicle;
  final String plate;
  final String phone;
  const _DriverCard({
    required this.driverName,
    required this.rating,
    required this.vehicle,
    required this.plate,
    required this.phone,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RydyColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: RydyColors.dividerColor.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: RydyColors.textColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Center(child: Text('👤', style: TextStyle(fontSize: 24, color: RydyColors.textColor))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        driverName,
                        style: const TextStyle(
                          color: RydyColors.textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: RydyColors.cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: RydyColors.subText.withOpacity(0.35)),
                      ),
                      child: Text('⭐ ${rating.toStringAsFixed(1)}', style: const TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('🚙 $vehicle • $plate', style: TextStyle(color: RydyColors.subText)),
                Text('📱 $phone', style: TextStyle(color: RydyColors.subText)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _DestinationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String details;
  final double progress; 
  const _DestinationCard({
    required this.title,
    required this.subtitle,
    required this.details,
    required this.progress,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RydyColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: RydyColors.dividerColor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: RydyColors.textColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('ETA 12m', style: TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.w700)),
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: RydyColors.subText)),
          Text(details, style: TextStyle(color: RydyColors.subText)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: RydyColors.darkBg,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFFFFF)),
            ),
          ),
        ],
      ),
    );
  }
}
enum _StatusTone { success, info, muted }
class _StatusItem {
  final String text;
  final String sub;
  final String icon;
  final _StatusTone tone;
  const _StatusItem({required this.text, required this.sub, required this.icon, required this.tone});
}
class _StatusList extends StatelessWidget {
  final String title;
  final List<_StatusItem> items;
  const _StatusList({required this.title, required this.items});
  Color _toneColor(_StatusTone t) {
    switch (t) {
      case _StatusTone.success:
        return RydyColors.textColor;
      case _StatusTone.info:
        return RydyColors.textColor;
      case _StatusTone.muted:
        return RydyColors.subText;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RydyColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: RydyColors.dividerColor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...items.map((e) {
            final c = _toneColor(e.tone);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: RydyColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: RydyColors.dividerColor.withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  if (e.tone == _StatusTone.success)
                    const AnimatedCheck(color: Color(0xFFFFFFFF), size: 18)
                  else
                    Text(e.icon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.text, style: const TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(e.sub, style: TextStyle(color: RydyColors.subText, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: c.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: c.withOpacity(0.35)),
                    ),
                    child: Text(
                      e.tone == _StatusTone.success
                          ? 'Done'
                          : e.tone == _StatusTone.info
                              ? 'Active'
                              : 'Next',
                      style: TextStyle(color: c, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
