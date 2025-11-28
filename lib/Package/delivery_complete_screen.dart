import 'package:flutter/material.dart';
import '../utils/theme_provider.dart';
import '../utils/animated_check.dart';
import 'rate_delivery_screen.dart';
import 'package_creation_screen.dart';
import '../utils/pdf_generator.dart';
class DeliveryCompleteScreen extends StatefulWidget {
  const DeliveryCompleteScreen({Key? key}) : super(key: key);
  @override
  State<DeliveryCompleteScreen> createState() => _DeliveryCompleteScreenState();
}
class _DeliveryCompleteScreenState extends State<DeliveryCompleteScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleIn;
  late final Animation<double> _fadeIn;
  late final AnimationController _starController;
  late final Animation<double> _starPulse;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _scaleIn = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
    _starController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _starPulse = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _starController, curve: Curves.easeInOut),
    );
  }
  @override
  void dispose() {
    _controller.dispose();
    _starController.dispose();
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
        title: const Text('Delivery Complete', style: TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.w700)),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  ScaleTransition(
                    scale: _scaleIn,
                    child: FadeTransition(
                      opacity: _fadeIn,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: RydyColors.cardBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: RydyColors.dividerColor.withOpacity(0.35), width: 2),
                        ),
                        child: const Center(
                          child: AnimatedCheck(color: Color(0xFFFFFFFF), size: 72),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'All Packages Delivered!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: 0.2),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '4/4 successful deliveries • Total time: 35 minutes',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: RydyColors.subText, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  _summaryCard(),
                  const SizedBox(height: 16),
                  _metricsCard(),
                  const SizedBox(height: 16),
                  _receiptCard(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: RydyColors.darkBg,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    color: RydyColors.cardBg,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const RateDeliveryScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ScaleTransition(
                          scale: _starPulse,
                          child: const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                        ),
                        const SizedBox(width: 8),
                        const Text('Rate Delivery', style: TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.w700, fontSize: 18)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: RydyColors.cardBg,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            final file = await PdfGenerator.generateInvoice(
                              invoiceNumber: 'INV-${DateTime.now().millisecondsSinceEpoch}',
                              invoiceDate: DateTime.now(),
                              shipperName: 'Flytt Logistics',
                              consigneeName: 'Customer',
                              lines: [
                                InvoiceLine(description: '4 packages × €11', qty: 1, unit: 44.00),
                                InvoiceLine(description: 'Volume discount', qty: 1, unit: -4.00),
                                InvoiceLine(description: 'Service fee', qty: 1, unit: 0.00),
                              ],
                              total: 40.0,
                              currency: '€',
                              logoAssetPath: 'assets/icon/logo.png',
                              driverName: 'Pierre Martin',
                              driverPhone: '+33 6 12 34 56 78',
                              shippingAddress: '123 Main Street, Apt 4B',
                              shippingCity: 'Paris',
                              shippingPostalCode: '75001',
                              shippingCountry: 'France',
                              packages: [
                                PackageDetail(
                                  receiverName: 'Maria Garcia',
                                  address: '45 Rue de Rivoli, Paris',
                                  weight: '1.6 kg',
                                  size: 'Small',
                                ),
                                PackageDetail(
                                  receiverName: 'Office Reception',
                                  address: '78 Avenue des Champs-Élysées, Paris',
                                  weight: '3.2 kg',
                                  size: 'Medium',
                                ),
                                PackageDetail(
                                  receiverName: 'John Smith',
                                  address: '12 Place de la Concorde, Paris',
                                  weight: '7.8 kg',
                                  size: 'Large',
                                ),
                                PackageDetail(
                                  receiverName: 'Sarah Johnson',
                                  address: '9 Rue de la Paix, Paris',
                                  weight: '1.9 kg',
                                  size: 'Small',
                                ),
                              ],
                            );
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('PDF saved to: ${file.path}'), behavior: SnackBarBehavior.floating),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          ),
                          child: const Text('📄 Receipt', style: TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: RydyColors.cardBg,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const PackageCreationScreen()));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          ),
                          child: const Text('📦 Send More', style: TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _summaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RydyColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RydyColors.dividerColor.withOpacity(0.25),),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.inventory_2_rounded, color: RydyColors.textColor, size: 18),
              SizedBox(width: 8),
              Text('Delivery Summary', style: TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          _summaryTile('Maria • 2:15 PM • Signed by customer'),
          _summaryTile('Office • 2:21 PM • Left with reception'),
          _summaryTile('John • 2:33 PM • Handed directly'),
          _summaryTile('Sarah • 2:40 PM • Delivered to door'),
        ],
      ),
    );
  }
  Widget _summaryTile(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const AnimatedCheck(color: Color(0xFFFFFFFF), size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: RydyColors.subText, fontSize: 14))),
        ],
      ),
    );
  }
  Widget _metricsCard() {
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
        children: const [
          _metricRow('🚗 Driver: Pierre ⭐4.9'),
          SizedBox(height: 6),
          _metricRow('📏 Total Distance: 8.5 km'),
          SizedBox(height: 6),
          _metricRow('⏱️ Total Time: 35 minutes'),
          SizedBox(height: 6),
          _metricRow('📦 Packages: 4 delivered'),
          SizedBox(height: 6),
          _metricRow('🎯 Efficiency: 78% route optimization'),
        ],
      ),
    );
  }
  Widget _receiptCard() {
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
          const Text('🧾 Delivery Receipt', style: TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          _receiptRow('4 packages × €11', '€44.00'),
          _receiptRow('Volume discount', '-€4.00'),
          _receiptRow('Service fee', '€0.00'),
          const Divider(color: RydyColors.dividerColor, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Total', style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18, fontWeight: FontWeight.w800)),
              Text('€40.00', style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: RydyColors.subText, fontSize: 14)),
          Text(value, style: TextStyle(color: RydyColors.textColor, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
class _metricRow extends StatelessWidget {
  final String text;
  const _metricRow(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(color: RydyColors.subText));
  }
}
