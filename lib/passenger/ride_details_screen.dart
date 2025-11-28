import 'dart:math';
import 'dart:ui';
import '../utils/theme_provider.dart';
import '../utils/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ride_selection_screen.dart';
class RideDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> ride;
  const RideDetailsScreen({Key? key, required this.ride}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final Color accent = ride['status'] == 'completed'
        ? RydyColors.textColor
        : (ride['status'] == 'cancelled' ? RydyColors.subText : RydyColors.textColor.withOpacity(0.7));
    final Color headerBg = accent.withOpacity(0.18);
    final rating = (ride['rating'] is num)
        ? (ride['rating'] as num).toDouble()
        : (ride['rating'] is List && ride['rating'].isNotEmpty && ride['rating'][0] is num)
            ? (ride['rating'][0] as num).toDouble()
            : 0.0;
    final bool isTopDriver = rating >= 4.7;
    final String statusText = ride['status'] == 'completed'
        ? AppLocalizations.of(context).translate('completed_successfully')
        : (ride['status'] == 'cancelled' ? AppLocalizations.of(context).translate('ride_was_cancelled') : AppLocalizations.of(context).translate('in_progress'));
    final user = Supabase.instance.client.auth.currentUser;
    final currency = ride['currency'] ?? getCurrencyFromPhone(user?.phone ?? '');
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: RydyColors.darkBg,
        foregroundColor: RydyColors.textColor,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: CircleAvatar(
            backgroundColor: RydyColors.darkBg,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: RydyColors.textColor),
              onPressed: () => Navigator.of(context).pop(),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
            ),
          ),
        ),
        title: Text(
          AppLocalizations.of(context).translate('ride_details'),
          style: TextStyle(
            color: RydyColors.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        toolbarHeight: 60,
        shadowColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  RydyColors.darkBg,
                  RydyColors.cardBg,
                  RydyColors.darkBg,
                ],
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 100, 20, 40),
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (ride['ride_type'] != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: RydyColors.textColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: RydyColors.textColor.withOpacity(0.2)),
                        ),
                        child: Text(
                          _getRideTypeDisplayName(ride['ride_type']),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: RydyColors.textColor,
                          ),
                        ),
                      ),
                    Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: RydyColors.cardBg,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: RydyColors.textColor.withOpacity(0.10),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    '${(ride['price'] as num?)?.toStringAsFixed(2) ?? '0.00'} $currency',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: RydyColors.textColor, letterSpacing: 0.5),
                  ),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: RydyColors.cardBg.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: accent.withOpacity(0.13), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.10),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.alt_route_rounded, color: accent, size: 28),
                            const SizedBox(width: 10),
                            Text(AppLocalizations.of(context).translate('route'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: RydyColors.textColor)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(AppLocalizations.of(context).translate('your_recent_ride'), style: TextStyle(fontSize: 14, color: RydyColors.subText)),
                        const SizedBox(height: 18),
                        Text(
                          ride['from_address'] ?? ride['startLocation'] ?? '',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: RydyColors.textColor),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: accent,
                                  thickness: 2,
                                  endIndent: 8,
                                ),
                              ),
                              Icon(Icons.directions_car, color: accent, size: 22),
                              Expanded(
                                child: Divider(
                                  color: accent,
                                  thickness: 2,
                                  indent: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          ride['to_address'] ?? ride['endLocation'] ?? '',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: RydyColors.textColor),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, color: accent, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _formatRideDate(ride['created_at']),
                              style: const TextStyle(color: RydyColors.textColor, fontSize: 15, fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    ride['status'] == 'completed'
                                        ? Icons.check_circle_rounded
                                        : (ride['status'] == 'cancelled' ? Icons.cancel_rounded : Icons.access_time_rounded),
                                    size: 16,
                                    color: accent,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    (ride['status'] ?? '').toString().toUpperCase(),
                                    style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStepCircle(Icons.radio_button_checked, RydyColors.textColor),
                    _buildStepLine(),
                    _buildStepCircle(
                      ride['status'] == 'completed'
                          ? Icons.check_circle_rounded
                          : (ride['status'] == 'cancelled' ? Icons.cancel_rounded : Icons.access_time_rounded),
                      accent,
                    ),
                  ],
                ),
              ),
              Center(
                child: Text(
                  statusText,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: accent),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [RydyColors.cardBg, accent.withOpacity(0.18), RydyColors.cardBg],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: RydyColors.cardBg.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: accent.withOpacity(0.10), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: RydyColors.darkBg.withOpacity(0.09),
                          blurRadius: 18,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: isTopDriver ? accent.withOpacity(0.15) : RydyColors.cardBg,
                          child: Stack(
                            alignment: Alignment.topRight,
                            children: [
                              const Icon(Icons.person, color: RydyColors.textColor, size: 32),
                              if (isTopDriver)
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: RydyColors.textColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.star, size: 14, color: RydyColors.cardBg),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person, size: 18, color: RydyColors.textColor),
                                  const SizedBox(width: 6),
                                                              Text(
                              ride['driverName'] ?? AppLocalizations.of(context).translate('unknown_driver'),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: RydyColors.textColor),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.star_rounded, size: 18, color: RydyColors.textColor),
                                  const SizedBox(width: 2),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: RydyColors.textColor),
                                  ),
                                  if (isTopDriver)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: RydyColors.textColor.withOpacity(0.18),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(AppLocalizations.of(context).translate('top_driver'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RydyColors.textColor)),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [RydyColors.cardBg, accent.withOpacity(0.18), RydyColors.cardBg],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: RydyColors.cardBg.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: accent.withOpacity(0.10), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: RydyColors.darkBg.withOpacity(0.09),
                          blurRadius: 18,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            Icon(Icons.timer_rounded, color: accent, size: 26),
                            const SizedBox(height: 6),
                            Text(
                              '${ride['duration_minutes'] ?? 0} min',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: RydyColors.textColor),
                            ),
                            const SizedBox(height: 2),
                            Text(AppLocalizations.of(context).translate('duration'), style: TextStyle(fontSize: 12, color: RydyColors.subText)),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(Icons.route_rounded, color: accent, size: 26),
                            const SizedBox(height: 6),
                            Text(
                              '${(ride['distance_km'] as num?)?.toStringAsFixed(1) ?? '0.0'} km',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: RydyColors.textColor),
                            ),
                            const SizedBox(height: 2),
                            Text(AppLocalizations.of(context).translate('distance'), style: TextStyle(fontSize: 12, color: RydyColors.subText)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  String _formatRideDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$day/$month/$year • $hour:$minute';
    } catch (e) {
      return 'N/A';
    }
  }
  Widget _buildStepCircle(IconData icon, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
  Widget _buildStepLine() {
    return Container(
      width: 40,
      height: 2,
      color: RydyColors.cardBg,
    );
  }
  String _getRideTypeDisplayName(String rideType) {
    switch (rideType.toLowerCase()) {
      case 'weego':
        return 'Weego';
      case 'comfort':
        return 'Comfort';
      case 'taxi':
        return 'Taxi';
      case 'eco':
        return 'Eco';
      case 'woman':
        return 'Woman';
      case 'weegoxl':
        return 'WeegoXL';
      default:
        return rideType;
    }
  }
} 
