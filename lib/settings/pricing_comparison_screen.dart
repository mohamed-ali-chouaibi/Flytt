import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
String getCurrencyForCountry(String? countryCode) {
  switch (countryCode) {
    case 'TN':
      return 'TND';
    case 'FR':
      return 'EUR';
    case 'DE':
      return 'EUR';
    default:
      return 'TND';
  }
}
Future<String?> getUserCountryCode() async {
  try {
    final position = await Geolocator.getCurrentPosition();
    final apiKey = 'AIzaSyDaIk1468iXr5IaRhHvYe32tnWgLqyyTg4';
    final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$apiKey';
    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);
    if (data['results'] != null && data['results'].isNotEmpty) {
      for (var result in data['results']) {
        for (var comp in result['address_components']) {
          if (comp['types'].contains('country')) {
            return comp['short_name'];
          }
        }
      }
    }
  } catch (e) {}
  return 'TN'; 
}
class PricingComparisonScreen extends StatelessWidget {
  const PricingComparisonScreen({Key? key}) : super(key: key);
  Future<Map<String, dynamic>> _fetchTotalsAndCurrency() async {
    final user = Supabase.instance.client.auth.currentUser;
    String? countryCode = await getUserCountryCode();
    String currency = getCurrencyForCountry(countryCode);
    if (user == null) return {'day': 0, 'week': 0, 'month': 0, 'currency': currency};
    final rides = await Supabase.instance.client
        .from('ride_history')
        .select('price, created_at')
        .eq('passenger_uid', user.id)
        .order('created_at', ascending: false);
    if (rides == null || rides.isEmpty) return {'day': 0, 'week': 0, 'month': 0, 'currency': currency};
    final now = DateTime.now();
    double dayTotal = 0, weekTotal = 0, monthTotal = 0;
    for (final ride in rides) {
      final price = (ride['price'] as num?)?.toDouble() ?? 0.0;
      final createdAt = DateTime.tryParse(ride['created_at'] ?? '') ?? now;
      if (createdAt.year == now.year && createdAt.month == now.month && createdAt.day == now.day) {
        dayTotal += price;
      }
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));
      if (!createdAt.isBefore(weekStart) && !createdAt.isAfter(weekEnd)) {
        weekTotal += price;
      }
      if (createdAt.year == now.year && createdAt.month == now.month) {
        monthTotal += price;
      }
    }
    return {
      'day': dayTotal,
      'week': weekTotal,
      'month': monthTotal,
      'currency': currency,
    };
  }
  @override
  Widget build(BuildContext context) {
    double boltPerRide = 16.0; 
    int ridesPerDay = 1;
    int ridesPerWeek = 7;
    int ridesPerMonth = 30;
    double boltPerWeek = boltPerRide * ridesPerWeek;
    double boltPerMonth = boltPerRide * ridesPerMonth;
    Widget buildCard(String title, double yourValue, double boltValue, String subtitle, String currency) {
      final double savings = (boltValue - yourValue).clamp(0, double.infinity);
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2C3E50).withOpacity(0.10),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(fontSize: 15, color: Color(0xFF757575))),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rydy', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF26A69A))),
                    const SizedBox(height: 6),
                    Text('${yourValue.toStringAsFixed(2)} $currency', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Bolt', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
                    const SizedBox(height: 6),
                    Text('${boltValue.toStringAsFixed(2)} $currency', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF26A69A))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'You saved: ${savings.toStringAsFixed(2)} $currency',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF26A69A),
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pricing Comparison'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchTotalsAndCurrency(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final totals = snapshot.data!;
          final currency = totals['currency'] as String? ?? 'TND';
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              buildCard(
                'Per Day',
                totals['day'] ?? 0,
                boltPerRide * ridesPerDay,
                'Total spent today',
                currency,
              ),
              buildCard(
                'Per Week',
                totals['week'] ?? 0,
                boltPerWeek,
                'Total spent this week',
                currency,
              ),
              buildCard(
                'Per Month',
                totals['month'] ?? 0,
                boltPerMonth,
                'Total spent this month',
                currency,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF2C3E50).withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pricing Formulas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50))),
                    const SizedBox(height: 8),
                    Text('Rydy: Actual ride history', style: const TextStyle(fontSize: 14, color: Color(0xFF757575))),
                    Text('Bolt: 16.00 $currency per ride (example)', style: const TextStyle(fontSize: 14, color: Color(0xFF757575))),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
} 
