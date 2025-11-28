import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/theme_provider.dart';
class RateDeliveryScreen extends StatefulWidget {
  const RateDeliveryScreen({Key? key}) : super(key: key);
  @override
  State<RateDeliveryScreen> createState() => _RateDeliveryScreenState();
}
class _RateDeliveryScreenState extends State<RateDeliveryScreen> {
  int _starRating = 0; 
  final TextEditingController _feedbackController = TextEditingController();
  static const int _maxChars = 500;
  String _speed = '';
  String _condition = '';
  String _professionalism = '';
  @override
  void dispose() {
    _feedbackController.dispose();
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
        centerTitle: true,
        title: const Text(
          'Rate Delivery',
          style: TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.w600),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _StarPatternPainter(opacity: 0.08))),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _driverProfile(),
                  const SizedBox(height: 16),
                  _ratingSection(),
                  const SizedBox(height: 12),
                  _categoriesSection(),
                  const SizedBox(height: 12),
                  _feedbackSection(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _starRating > 0 ? RydyColors.cardBg : RydyColors.cardBg.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: ElevatedButton(
                      onPressed: _starRating > 0 ? () {} : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        disabledBackgroundColor: Colors.transparent,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Submit Review',
                            style: TextStyle(
                              color: _starRating > 0 ? RydyColors.textColor : RydyColors.textColor.withOpacity(0.45),
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.send, size: 20, color: _starRating > 0 ? RydyColors.textColor : RydyColors.textColor.withOpacity(0.45)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: Container(
                    decoration: BoxDecoration(
                      color: RydyColors.cardBg,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                      child: const Text('Skip for now', style: TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _driverProfile() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RydyColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RydyColors.dividerColor.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: RydyColors.textColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('👤', style: TextStyle(fontSize: 34))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Pierre Martin', style: TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.w800, fontSize: 18)),
                SizedBox(height: 4),
                Text('⭐4.9 • 247 deliveries', style: TextStyle(color: RydyColors.subText)),
                SizedBox(height: 2),
                Text('Toyota Corolla • 257 TU', style: TextStyle(color: RydyColors.subText)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _ratingSection() {
    const labels = ['Poor', 'Fair', 'Good', 'Great', 'Excellent'];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RydyColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RydyColors.dividerColor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('How was your delivery experience?', style: TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < _starRating;
              return IconButton(
                onPressed: () => setState(() => _starRating = i + 1),
                icon: Icon(filled ? Icons.star : Icons.star_border, color: filled ? const Color(0xFFFFC107) : RydyColors.subText, size: 32),
              );
            }),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels.map((t) => Expanded(
              child: Text(
                t,
                textAlign: TextAlign.center,
                style: TextStyle(color: RydyColors.subText, fontSize: 12),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
  Widget _categoriesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RydyColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RydyColors.dividerColor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Delivery Speed', style: TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _chipRow([
            _Choice('Fast', 'fast'),
            _Choice('Average', 'avg'),
            _Choice('Slow', 'slow'),
          ], _speed, (v) => setState(() => _speed = v)),
          const SizedBox(height: 12),
          const Text('Package Condition', style: TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _chipRow([
            _Choice('Perfect', 'perfect'),
            _Choice('Good', 'good'),
            _Choice('Damaged', 'bad'),
          ], _condition, (v) => setState(() => _condition = v)),
          const SizedBox(height: 12),
          const Text('Driver Professionalism', style: TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _chipRow([
            _Choice('Excellent', 'ex'),
            _Choice('Good', 'g'),
            _Choice('Poor', 'p'),
          ], _professionalism, (v) => setState(() => _professionalism = v)),
        ],
      ),
    );
  }
  Widget _chipRow(List<_Choice> items, String current, Function(String) onSelect) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((c) {
        final selected = c.value == current;
        return ChoiceChip(
          label: Text(c.label),
          selected: selected,
          onSelected: (_) => onSelect(c.value),
          labelStyle: TextStyle(
            color: selected ? RydyColors.textColor : RydyColors.subText,
            fontWeight: FontWeight.w600,
          ),
          selectedColor: RydyColors.cardBg,
          backgroundColor: RydyColors.darkBg,
          side: BorderSide(color: selected ? RydyColors.textColor.withOpacity(0.35) : RydyColors.dividerColor.withOpacity(0.35)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        );
      }).toList(),
    );
  }
  Widget _feedbackSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RydyColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RydyColors.dividerColor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Additional comments (optional)', style: TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: RydyColors.darkBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: RydyColors.dividerColor.withOpacity(0.35)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Stack(
              children: [
                TextField(
                  controller: _feedbackController,
                  maxLines: 6,
                  maxLength: _maxChars,
                  style: const TextStyle(color: RydyColors.textColor),
                  decoration: const InputDecoration(
                    hintText: 'How was your experience? What could be improved?',
                    hintStyle: TextStyle(color: RydyColors.subText),
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Text('${_feedbackController.text.length}/$_maxChars', style: const TextStyle(color: RydyColors.subText, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  } 
}
class _Choice {
  final String label;
  final String value;
  _Choice(this.label, this.value);
}
class _StarPatternPainter extends CustomPainter {
  final double opacity;
  _StarPatternPainter({required this.opacity});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withOpacity(opacity);
    final rnd = Random(7);
    for (int i = 0; i < 70; i++) {
      final cx = rnd.nextDouble() * size.width;
      final cy = rnd.nextDouble() * size.height;
      final r = 1.0 + rnd.nextDouble() * 1.2;
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
