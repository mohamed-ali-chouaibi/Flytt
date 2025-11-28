import 'package:flutter/material.dart';
import '../Package/delivery_complete_screen.dart';
class DeliveryFlowGuard {
  static bool areAllDelivered(List<Map<String, dynamic>>? deliveries) {
    if (deliveries == null || deliveries.isEmpty) return false;
    for (final d in deliveries) {
      final delivered = d['delivered'] == true;
      if (!delivered) return false;
    }
    return true;
  }
  static Future<void> navigateToCompletionIfDone(
    BuildContext context,
    List<Map<String, dynamic>>? deliveries,
  ) async {
    if (areAllDelivered(deliveries)) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DeliveryCompleteScreen()),
      );
    }
  }
}
