import 'dart:math';
class PricingConfig {
  final String countryCode;
  final String currency;
  final double basePrice;
  final double baseRangeKm;
  final double pricePerKm;
  final double commission;
  final double surgeMultiplier;
  final double nightBasePrice;
  final double nightPricePerKm;
  final double scooterUnlock;
  final double scooterPricePerMin;
  final double nightScooterUnlock;
  final double nightScooterPricePerMin;
  final int nightStartHour;
  final int nightEndHour;
  const PricingConfig({
    required this.countryCode,
    required this.currency,
    required this.basePrice,
    required this.baseRangeKm,
    required this.pricePerKm,
    required this.commission,
    required this.surgeMultiplier,
    required this.nightBasePrice,
    required this.nightPricePerKm,
    required this.scooterUnlock,
    required this.scooterPricePerMin,
    required this.nightScooterUnlock,
    required this.nightScooterPricePerMin,
    required this.nightStartHour,
    required this.nightEndHour,
  });
}
class PricingUtils {
  static const Map<String, PricingConfig> _pricingConfigs = {
    'FR': PricingConfig(
      countryCode: 'FR',
      currency: 'EUR',
      basePrice: 11.0,
      baseRangeKm: 3.0,
      pricePerKm: 1.05,
      commission: 0.05,
      surgeMultiplier: 1.5,
      nightBasePrice: 12.5,
      nightPricePerKm: 1.1,
      scooterUnlock: 0.5,
      scooterPricePerMin: 0.2,
      nightScooterUnlock: 0.75,
      nightScooterPricePerMin: 0.25,
      nightStartHour: 22,
      nightEndHour: 6,
    ),
    'EE': PricingConfig(
      countryCode: 'EE',
      currency: 'EUR',
      basePrice: 4.2,
      baseRangeKm: 2.0,
      pricePerKm: 0.7,
      commission: 0.05,
      surgeMultiplier: 1.5,
      nightBasePrice: 4.8,
      nightPricePerKm: 0.7,
      scooterUnlock: 0.4,
      scooterPricePerMin: 0.15,
      nightScooterUnlock: 0.4,
      nightScooterPricePerMin: 0.15,
      nightStartHour: 23,
      nightEndHour: 5,
    ),
    'LV': PricingConfig(
      countryCode: 'LV',
      currency: 'EUR',
      basePrice: 3.2,
      baseRangeKm: 0.5,
      pricePerKm: 0.5,
      commission: 0.05,
      surgeMultiplier: 1.5,
      nightBasePrice: 3.8,
      nightPricePerKm: 0.7,
      scooterUnlock: 0.4,
      scooterPricePerMin: 0.15,
      nightScooterUnlock: 0.4,
      nightScooterPricePerMin: 0.15,
      nightStartHour: 23,
      nightEndHour: 5,
    ),
    'LT': PricingConfig(
      countryCode: 'LT',
      currency: 'EUR',
      basePrice: 3.6,
      baseRangeKm: 2.6,
      pricePerKm: 0.5,
      commission: 0.05,
      surgeMultiplier: 1.5,
      nightBasePrice: 3.8,
      nightPricePerKm: 0.7,
      scooterUnlock: 0.4,
      scooterPricePerMin: 0.15,
      nightScooterUnlock: 0.4,
      nightScooterPricePerMin: 0.15,
      nightStartHour: 23,
      nightEndHour: 5,
    ),
    'DE': PricingConfig(
      countryCode: 'DE',
      currency: 'EUR',
      basePrice: 5.5,
      baseRangeKm: 0.6,
      pricePerKm: 0.5,
      commission: 0.05,
      surgeMultiplier: 1.5,
      nightBasePrice: 6.5,
      nightPricePerKm: 0.65,
      scooterUnlock: 0.4,
      scooterPricePerMin: 0.25,
      nightScooterUnlock: 0.4,
      nightScooterPricePerMin: 0.25,
      nightStartHour: 22,
      nightEndHour: 6,
    ),
    'IT': PricingConfig(
      countryCode: 'IT',
      currency: 'EUR',
      basePrice: 4.5,
      baseRangeKm: 2.0,
      pricePerKm: 0.8,
      commission: 0.05,
      surgeMultiplier: 1.5,
      nightBasePrice: 5.5,
      nightPricePerKm: 1.0,
      scooterUnlock: 0.4,
      scooterPricePerMin: 0.18,
      nightScooterUnlock: 0.4,
      nightScooterPricePerMin: 0.22,
      nightStartHour: 22,
      nightEndHour: 6,
    ),
    'BE': PricingConfig(
      countryCode: 'BE',
      currency: 'EUR',
      basePrice: 7.5,
      baseRangeKm: 2.0,
      pricePerKm: 0.45,
      commission: 0.05,
      surgeMultiplier: 1.5,
      nightBasePrice: 9.5,
      nightPricePerKm: 0.5,
      scooterUnlock: 0.6,
      scooterPricePerMin: 0.95,
      nightScooterUnlock: 0.8,
      nightScooterPricePerMin: 1.1,
      nightStartHour: 22,
      nightEndHour: 6,
    ),
    'ES': PricingConfig(
      countryCode: 'ES',
      currency: 'EUR',
      basePrice: 8.5,
      baseRangeKm: 2.0,
      pricePerKm: 0.75,
      commission: 0.05,
      surgeMultiplier: 1.5,
      nightBasePrice: 9.5,
      nightPricePerKm: 0.5,
      scooterUnlock: 0.4,
      scooterPricePerMin: 0.15,
      nightScooterUnlock: 0.4,
      nightScooterPricePerMin: 0.15,
      nightStartHour: 23,
      nightEndHour: 6,
    ),
    'PT': PricingConfig(
      countryCode: 'PT',
      currency: 'EUR',
      basePrice: 3.5,
      baseRangeKm: 3.0,
      pricePerKm: 0.55,
      commission: 0.05,
      surgeMultiplier: 1.5,
      nightBasePrice: 4.2,
      nightPricePerKm: 0.65,
      scooterUnlock: 0.35,
      scooterPricePerMin: 0.18,
      nightScooterUnlock: 0.35,
      nightScooterPricePerMin: 0.18,
      nightStartHour: 23,
      nightEndHour: 6,
    ),
    'TN': PricingConfig(
      countryCode: 'TN',
      currency: 'TND',
      basePrice: 6.5,
      baseRangeKm: 0.85,
      pricePerKm: 1.2,
      commission: 0.05,
      surgeMultiplier: 1.5,
      nightBasePrice: 7.5,
      nightPricePerKm: 1.3,
      scooterUnlock: 1.0,
      scooterPricePerMin: 0.3,
      nightScooterUnlock: 1.2,
      nightScooterPricePerMin: 0.35,
      nightStartHour: 22,
      nightEndHour: 6,
    ),
  };
  static PricingConfig? getPricingConfig(String countryCode) {
    return _pricingConfigs[countryCode];
  }
  static bool isNightTime([String? countryCode]) {
    final now = DateTime.now();
    final hour = now.hour;
    if (countryCode != null) {
      final config = getPricingConfig(countryCode);
      if (config != null) {
        if (config.nightStartHour > config.nightEndHour) {
          return hour >= config.nightStartHour || hour < config.nightEndHour;
        } else {
          return hour >= config.nightStartHour && hour < config.nightEndHour;
        }
      }
    }
    return hour >= 22 || hour < 6;
  }
  static double calculateCarPrice({
    required String countryCode,
    required double distanceKm,
    required int durationMinutes,
    bool applySurge = false,
    double? customSurgeMultiplier,
  }) {
    final config = getPricingConfig(countryCode);
    if (config == null) {
      return _calculateTunisiaFallback(distanceKm, durationMinutes);
    }
    final isNight = isNightTime();
    final basePrice = isNight ? config.nightBasePrice : config.basePrice;
    final pricePerKm = isNight ? config.nightPricePerKm : config.pricePerKm;
    final baseRangeKm = config.baseRangeKm;
    double price;
    if (distanceKm <= baseRangeKm) {
      price = basePrice;
    } else {
      final extraDistance = distanceKm - baseRangeKm;
      price = basePrice + (extraDistance * pricePerKm);
    }
    if (applySurge) {
      price *= customSurgeMultiplier ?? config.surgeMultiplier;
    }
    return price;
  }
  static double calculateScooterPrice({
    required String countryCode,
    required int durationMinutes,
    bool applySurge = false,
    double? customSurgeMultiplier,
  }) {
    final config = getPricingConfig(countryCode);
    if (config == null) {
      return 2.0 + (durationMinutes * 0.2);
    }
    final isNight = isNightTime();
    final unlockFee = isNight ? config.nightScooterUnlock : config.scooterUnlock;
    final pricePerMin = isNight ? config.nightScooterPricePerMin : config.scooterPricePerMin;
    double price = unlockFee + (durationMinutes * pricePerMin);
    if (applySurge) {
      price *= customSurgeMultiplier ?? config.surgeMultiplier;
    }
    return price;
  }
  static String getCurrency(String countryCode) {
    final config = getPricingConfig(countryCode);
    return config?.currency ?? 'EUR';
  }
  static double getCommission(String countryCode) {
    final config = getPricingConfig(countryCode);
    return config?.commission ?? 0.05;
  }
  static double getSurgeMultiplier(String countryCode) {
    final config = getPricingConfig(countryCode);
    return config?.surgeMultiplier ?? 1.5;
  }
  static double _calculateTunisiaFallback(double distanceKm, int durationMinutes) {
    if (distanceKm <= 0.85) {
      return 6.5;
    } else {
      return 3.5 + (distanceKm * 1.20) + (durationMinutes * 0.26);
    }
  }
  static bool shouldApplySurgePricing(String countryCode) {
    final random = Random();
    return random.nextDouble() < 0.2; 
  }
  static Map<String, dynamic> getPricingInfo(String countryCode) {
    final config = getPricingConfig(countryCode);
    if (config == null) return {};
    final isNight = isNightTime();
    return {
      'country': countryCode,
      'currency': config.currency,
      'isNight': isNight,
      'car': {
        'basePrice': isNight ? config.nightBasePrice : config.basePrice,
        'baseRangeKm': config.baseRangeKm,
        'pricePerKm': isNight ? config.nightPricePerKm : config.pricePerKm,
        'surgeMultiplier': config.surgeMultiplier,
      },
      'scooter': {
        'unlockFee': isNight ? config.nightScooterUnlock : config.scooterUnlock,
        'pricePerMin': isNight ? config.nightScooterPricePerMin : config.scooterPricePerMin,
        'surgeMultiplier': config.surgeMultiplier,
      },
      'commission': config.commission,
    };
  }
} 
