import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
class SurgePricingResult {
  final double finalPrice;
  final double surgeMultiplier;
  final double driverBonus;
  final double subscriptionDiscount;
  final String? surgeEventId;
  final Map<String, dynamic> pricingBreakdown;
  final bool hasSurge;
  final String? surgeZoneName;
  final String? eventType;
  final String? eventName;
  SurgePricingResult({
    required this.finalPrice,
    required this.surgeMultiplier,
    required this.driverBonus,
    required this.subscriptionDiscount,
    this.surgeEventId,
    required this.pricingBreakdown,
    required this.hasSurge,
    this.surgeZoneName,
    this.eventType,
    this.eventName,
  });
  factory SurgePricingResult.fromMap(Map<String, dynamic> map) {
    return SurgePricingResult(
      finalPrice: (map['final_price'] as num).toDouble(),
      surgeMultiplier: (map['surge_multiplier'] as num).toDouble(),
      driverBonus: (map['driver_bonus'] as num).toDouble(),
      subscriptionDiscount: (map['subscription_discount'] as num).toDouble(),
      surgeEventId: map['surge_event_id'] as String?,
      pricingBreakdown: jsonDecode(map['pricing_breakdown'] as String),
      hasSurge: (map['surge_multiplier'] as num).toDouble() > 1.0,
      surgeZoneName: map['pricing_breakdown'] != null 
          ? jsonDecode(map['pricing_breakdown'] as String)['surge_zone_name'] as String?
          : null,
      eventType: map['pricing_breakdown'] != null 
          ? jsonDecode(map['pricing_breakdown'] as String)['event_type'] as String?
          : null,
      eventName: map['pricing_breakdown'] != null 
          ? jsonDecode(map['pricing_breakdown'] as String)['event_name'] as String?
          : null,
    );
  }
}
class SurgeZone {
  final String id;
  final String name;
  final String countryCode;
  final String city;
  final double centerLat;
  final double centerLng;
  final int radiusMeters;
  final bool isActive;
  SurgeZone({
    required this.id,
    required this.name,
    required this.countryCode,
    required this.city,
    required this.centerLat,
    required this.centerLng,
    required this.radiusMeters,
    required this.isActive,
  });
  factory SurgeZone.fromMap(Map<String, dynamic> map) {
    return SurgeZone(
      id: map['id'] as String,
      name: map['name'] as String,
      countryCode: map['country_code'] as String,
      city: map['city'] as String,
      centerLat: (map['center_lat'] as num).toDouble(),
      centerLng: (map['center_lng'] as num).toDouble(),
      radiusMeters: map['radius_meters'] as int,
      isActive: map['is_active'] as bool,
    );
  }
}
class SurgeEvent {
  final String id;
  final String surgeZoneId;
  final String eventType;
  final String? eventName;
  final double baseMultiplier;
  final double driverBonusPerRide;
  final double maxMultiplier;
  final DateTime startTime;
  final DateTime endTime;
  final bool isActive;
  SurgeEvent({
    required this.id,
    required this.surgeZoneId,
    required this.eventType,
    this.eventName,
    required this.baseMultiplier,
    required this.driverBonusPerRide,
    required this.maxMultiplier,
    required this.startTime,
    required this.endTime,
    required this.isActive,
  });
  factory SurgeEvent.fromMap(Map<String, dynamic> map) {
    return SurgeEvent(
      id: map['id'] as String,
      surgeZoneId: map['surge_zone_id'] as String,
      eventType: map['event_type'] as String,
      eventName: map['event_name'] as String?,
      baseMultiplier: (map['base_multiplier'] as num).toDouble(),
      driverBonusPerRide: (map['driver_bonus_per_ride'] as num).toDouble(),
      maxMultiplier: (map['max_multiplier'] as num).toDouble(),
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: DateTime.parse(map['end_time'] as String),
      isActive: map['is_active'] as bool,
    );
  }
}
class SurgePricingService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static Future<SurgePricingResult> calculateSurgePricing({
    required String passengerUid,
    required String? driverUid,
    required double basePrice,
    required double distanceKm,
    required double lat,
    required double lng,
    required String countryCode,
  }) async {
    try {
      final response = await _supabase.rpc('calculate_surge_pricing', params: {
        'p_passenger_uid': passengerUid,
        'p_driver_uid': driverUid,
        'p_base_price': basePrice,
        'p_distance_km': distanceKm,
        'p_lat': lat,
        'p_lng': lng,
        'p_country_code': countryCode,
      });
      if (response is List && response.isNotEmpty) {
        return SurgePricingResult.fromMap(response.first);
      } else if (response is Map<String, dynamic>) {
        return SurgePricingResult.fromMap(response);
      } else {
      return SurgePricingResult(
        finalPrice: basePrice,
        surgeMultiplier: 1.0,
        driverBonus: 0.0,
        subscriptionDiscount: 0.0,
        pricingBreakdown: {
          'base_price': basePrice,
          'surge_multiplier': 1.0,
          'surge_amount': 0.0,
          'driver_bonus': 0.0,
          'subscription_discount': 0.0,
          'has_subscription': false,
          'surge_zone_name': '',
          'event_type': '',
          'event_name': '',
        },
        hasSurge: false,
      );
      }
    } catch (e) {
      print('Error calculating surge pricing: $e');
      return SurgePricingResult(
        finalPrice: basePrice,
        surgeMultiplier: 1.0,
        driverBonus: 0.0,
        subscriptionDiscount: 0.0,
        pricingBreakdown: {
          'base_price': basePrice,
          'surge_multiplier': 1.0,
          'surge_amount': 0.0,
          'driver_bonus': 0.0,
          'subscription_discount': 0.0,
          'has_subscription': false,
          'surge_zone_name': '',
          'event_type': '',
          'event_name': '',
        },
        hasSurge: false,
      );
    }
  }
  static Future<String?> getUserSubscription(String passengerUid) async {
    try {
      final response = await _supabase
          .from('passenger')
          .select('subscription_plan, subscription_end_date')
          .eq('id', passengerUid)
          .maybeSingle();
      if (response != null) {
        final plan = response['subscription_plan'] as String?;
        final endDate = response['subscription_end_date'] as String?;
        if (plan != null && plan != 'free' && endDate != null) {
          final endDateTime = DateTime.parse(endDate);
          if (endDateTime.isAfter(DateTime.now())) {
            return plan; 
          }
        }
      }
      return null; 
    } catch (e) {
      print('Error checking subscription: $e');
      return null;
    }
  }
  static Future<List<SurgeZone>> getActiveSurgeZones(String countryCode) async {
    try {
      final response = await _supabase
          .from('surge_zones')
          .select('*')
          .eq('country_code', countryCode)
          .eq('is_active', true);
      return (response as List)
          .map((zone) => SurgeZone.fromMap(zone))
          .toList();
    } catch (e) {
      print('Error getting surge zones: $e');
      return [];
    }
  }
  static Future<List<SurgeEvent>> getActiveSurgeEvents({
    required double lat,
    required double lng,
    required String countryCode,
  }) async {
    try {
      final response = await _supabase.rpc('is_in_surge_zone', params: {
        'p_lat': lat,
        'p_lng': lng,
        'p_country_code': countryCode,
      });
      if (response is List) {
        return response.map((event) => SurgeEvent.fromMap(event)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting surge events: $e');
      return [];
    }
  }
  static Future<String?> recordSurgePricing({
    required String? rideId,
    required String passengerUid,
    required String? driverUid,
    required String? surgeEventId,
    required double basePrice,
    required double surgeMultiplier,
    required double finalPrice,
    required double driverBonus,
    required double subscriptionDiscount,
    required double locationLat,
    required double locationLng,
  }) async {
    try {
      final response = await _supabase.rpc('record_surge_pricing', params: {
        'p_ride_id': rideId,
        'p_passenger_uid': passengerUid,
        'p_driver_uid': driverUid,
        'p_surge_event_id': surgeEventId,
        'p_base_price': basePrice,
        'p_surge_multiplier': surgeMultiplier,
        'p_final_price': finalPrice,
        'p_driver_bonus': driverBonus,
        'p_subscription_discount': subscriptionDiscount,
        'p_location_lat': locationLat,
        'p_location_lng': locationLng,
      });
      return response as String?;
    } catch (e) {
      print('Error recording surge pricing: $e');
      return null;
    }
  }
  static String getSurgeExplanation({
    required String eventType,
    required String? eventName,
    required String? surgeZoneName,
    required double surgeMultiplier,
    required double driverBonus,
    required bool hasSubscription,
  }) {
    final multiplier = (surgeMultiplier * 100).round();
    final bonus = driverBonus.toStringAsFixed(2);
    String explanation = '';
    switch (eventType) {
      case 'demand_high':
        explanation = 'Demand is high in this area. Drivers are getting a €$bonus bonus per ride to get you a ride faster.';
        break;
      case 'weather':
        explanation = 'Weather conditions are affecting ride availability. Drivers are getting a €$bonus bonus for driving in these conditions.';
        break;
      case 'event':
        explanation = eventName != null 
            ? 'Event: $eventName. Drivers are getting a €$bonus bonus for driving during this event.'
            : 'Special event in this area. Drivers are getting a €$bonus bonus per ride.';
        break;
      case 'traffic':
        explanation = 'Heavy traffic in this area. Drivers are getting a €$bonus bonus for navigating through traffic.';
        break;
      case 'night':
        explanation = 'Night time pricing. Drivers are getting a €$bonus bonus for driving at night.';
        break;
      default:
        explanation = 'Surge pricing is active in this area. Drivers are getting a €$bonus bonus per ride.';
    }
    if (hasSubscription) {
      explanation += ' Your subscription gives you a discount on surge pricing.';
    }
    return explanation;
  }
  static String getDriverNotificationText({
    required String eventType,
    required String? eventName,
    required String? surgeZoneName,
    required double driverBonus,
    required DateTime? endTime,
  }) {
    final bonus = driverBonus.toStringAsFixed(2);
    final timeLeft = endTime != null 
        ? _formatTimeLeft(endTime.difference(DateTime.now()))
        : '';
    String notification = '';
    switch (eventType) {
      case 'demand_high':
        notification = '🔥 Hot Zone Alert! Earn €$bonus bonus per ride in ${surgeZoneName ?? 'this area'}. $timeLeft';
        break;
      case 'weather':
        notification = '🌧️ Weather Bonus! Earn €$bonus bonus per ride for driving in current conditions. $timeLeft';
        break;
      case 'event':
        notification = eventName != null 
            ? '🎉 Event Bonus! Earn €$bonus bonus per ride during "$eventName". $timeLeft'
            : '🎉 Event Bonus! Earn €$bonus bonus per ride in ${surgeZoneName ?? 'this area'}. $timeLeft';
        break;
      case 'traffic':
        notification = '🚗 Traffic Bonus! Earn €$bonus bonus per ride for navigating through traffic. $timeLeft';
        break;
      case 'night':
        notification = '🌙 Night Bonus! Earn €$bonus bonus per ride for driving at night. $timeLeft';
        break;
      default:
        notification = '💰 Bonus Zone! Earn €$bonus bonus per ride in ${surgeZoneName ?? 'this area'}. $timeLeft';
    }
    return notification;
  }
  static String _formatTimeLeft(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m left';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m left';
    } else {
      return 'Ending soon';
    }
  }
  static Future<Map<String, dynamic>> predictSurgePricing({
    required double lat,
    required double lng,
    required String countryCode,
    required DateTime targetTime,
  }) async {
    try {
      final response = await _supabase
          .from('surge_analytics')
          .select('*')
          .eq('date', targetTime.toIso8601String().split('T')[0])
          .eq('hour', targetTime.hour)
          .limit(1)
          .maybeSingle();
      if (response != null) {
        return {
          'predicted_multiplier': response['avg_multiplier'] ?? 1.0,
          'confidence': 0.8,
          'based_on_rides': response['total_rides'] ?? 0,
        };
      }
      return {
        'predicted_multiplier': 1.0,
        'confidence': 0.0,
        'based_on_rides': 0,
      };
    } catch (e) {
      print('Error predicting surge pricing: $e');
      return {
        'predicted_multiplier': 1.0,
        'confidence': 0.0,
        'based_on_rides': 0,
      };
    }
  }
  static Map<String, dynamic> getTransparencyInfo({
    required double basePrice,
    required double finalPrice,
    required double surgeMultiplier,
    required double driverBonus,
    required String? eventType,
    required String? eventName,
    required String? surgeZoneName,
  }) {
    final surgeAmount = basePrice * (surgeMultiplier - 1.0);
    final percentage = ((surgeMultiplier - 1.0) * 100).round();
    return {
      'base_price': basePrice,
      'surge_amount': surgeAmount,
      'final_price': finalPrice,
      'surge_percentage': percentage,
      'driver_bonus': driverBonus,
      'event_type': eventType,
      'event_name': eventName,
      'surge_zone': surgeZoneName,
      'explanation': _getTransparencyExplanation(
        eventType: eventType,
        eventName: eventName,
        surgeZoneName: surgeZoneName,
        driverBonus: driverBonus,
        percentage: percentage,
      ),
    };
  }
  static String _getTransparencyExplanation({
    required String? eventType,
    required String? eventName,
    required String? surgeZoneName,
    required double driverBonus,
    required int percentage,
  }) {
    String reason = '';
    switch (eventType) {
      case 'demand_high':
        reason = 'High demand in ${surgeZoneName ?? 'this area'}';
        break;
      case 'weather':
        reason = 'Weather conditions affecting availability';
        break;
      case 'event':
        reason = eventName ?? 'Special event in this area';
        break;
      case 'traffic':
        reason = 'Heavy traffic conditions';
        break;
      case 'night':
        reason = 'Night time pricing';
        break;
      default:
        reason = 'High demand in this area';
    }
    return 'Surge pricing is $percentage% higher because of $reason. Drivers receive a €${driverBonus.toStringAsFixed(2)} bonus to ensure you get a ride quickly.';
  }
} 
