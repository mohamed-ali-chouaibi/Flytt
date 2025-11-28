import 'package:flutter/material.dart';
import '../utils/theme_provider.dart';
import 'package_creation_screen.dart';
class PackageDeliveryScreen extends StatefulWidget {
  const PackageDeliveryScreen({Key? key}) : super(key: key);
  @override
  State<PackageDeliveryScreen> createState() => _PackageDeliveryScreenState();
}
class _PackageDeliveryScreenState extends State<PackageDeliveryScreen> {
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
          'Package Delivery',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [  
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Text(
                  'How it works',
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 20, 
                    color: RydyColors.textColor,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Column(
                  children: [
                    _buildStepCard(
                      icon: Icons.map_outlined,
                      title: 'Add Addresses',
                      subtitle: 'Enter pickup and delivery locations',
                      stepNumber: '1',
                    ),
                    const SizedBox(height: 8),
                    _buildStepCard(
                      icon: Icons.straighten,
                      title: 'Choose Size or Dimensions',
                      subtitle: 'Pick preset size or enter L×W×H',
                      stepNumber: '2',
                    ),
                    const SizedBox(height: 8),
                    _buildStepCard(
                      icon: Icons.my_location,
                      title: 'Track Live',
                      subtitle: 'Watch driver in real-time',
                      stepNumber: '3',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Text(
                  'Transparent Pricing',
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 20, 
                    color: RydyColors.textColor,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Container(
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
                    children: [
                      _buildPricingRow('Small (< 2kg)', '€11', '15-30min'),
                      const Divider(color: RydyColors.dividerColor, height: 1),
                      _buildPricingRow('Medium (2–5kg)', '€13', '20-40min'),
                      const Divider(color: RydyColors.dividerColor, height: 1),
                      _buildPricingRow('Large (5–10kg)', '€15', '25-50min'),
                      const Divider(color: RydyColors.dividerColor, height: 1),
                      _buildPricingRow('X-Large (10–20kg)', '€18', '30-60min'),
                      const Divider(color: RydyColors.dividerColor, height: 1),
                      _buildPricingRow('Oversize (20kg+)', 'Base €25 + €2/kg over 20', '60-120min'),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Text(
                  'Dimensions-Based Pricing',
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 20, 
                    color: RydyColors.textColor,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                      Text(
                        'Volumetric Weight = (L × W × H) / 5000',
                        style: TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Automatic type by weight: Small <2kg, Medium 2–5kg, Large 5–10kg, X‑Large 10–20kg, Oversize 20kg+ (Base €25 + €2/kg >20).',
                        style: TextStyle(color: RydyColors.subText, fontSize: 14, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Text(
                  'Bulk Discounts',
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 20, 
                    color: RydyColors.textColor,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Column(
                  children: [
                    _buildDiscountCard(
                      icon: Icons.celebration,
                      title: '5+ packages',
                      subtitle: '€1 OFF each',
                      description: 'Save more with multiple deliveries',
                      color: Colors.amber,
                    ),
                    const SizedBox(height: 12),
                    _buildDiscountCard(
                      icon: Icons.star,
                      title: '€100+ total',
                      subtitle: '10% OFF order',
                      description: 'Big orders get bigger savings',
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Padding(
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PackageCreationScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continue',
                          style: TextStyle(
                            color: RydyColors.textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward, color: RydyColors.textColor, size: 22),
                      ],
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
  Widget _buildStepCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String stepNumber,
  }) {
    return Container(
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
      child: ListTile(
        leading: Container(
          decoration: BoxDecoration(
            color: RydyColors.darkBg,
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(12),
          child: Text(
            stepNumber,
            style: TextStyle(
              color: RydyColors.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: RydyColors.textColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 15,
            color: RydyColors.subText,
          ),
        ),
        trailing: Icon(icon, color: RydyColors.subText, size: 24),
        onTap: () {},
      ),
    );
  }
  Widget _buildPricingRow(String size, String price, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              size,
              style: TextStyle(
                color: RydyColors.textColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            price,
            style: TextStyle(
              color: RydyColors.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            time,
            style: TextStyle(
              color: RydyColors.subText,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildDiscountCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RydyColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: RydyColors.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: RydyColors.subText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
