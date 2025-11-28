import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart' as poly;
import 'ride_in_progress_screen.dart';
import '../utils/theme_provider.dart';
import '../utils/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postgrest/postgrest.dart';
import 'add_card_screen.dart';
import 'promotions_screen.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'dart:core';
import 'dart:async';
import '../utils/pricing_utils.dart';
import '../utils/surge_pricing_service.dart';
const Map<String, String> countryToCurrency = {
  'TN': 'TND',
  'FR': 'EUR',
  'CH': 'CHF',
  'DE': 'EUR',
  'US': 'USD',
};
String getCountryCodeFromPhone(String phoneNumber) {
  try {
    final phone = PhoneNumber.parse(phoneNumber);
    return phone.isoCode as String? ?? 'TN';
  } catch (_) {
    return 'TN';
  }
}
String getCurrencyFromPhone(String phoneNumber) {
  final countryCode = getCountryCodeFromPhone(phoneNumber);
  return countryToCurrency[countryCode] ?? 'TND';
}
const String mapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      { "color": "#1A1A1A" }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      { "color": "#FFFFFF" }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      { "color": "#1A1A1A" }
    ]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [
      { "color": "#2B2B2B" }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [
      { "color": "#2B2B2B" }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      { "color": "#232323" }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      { "color": "#2B2B2B" }
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [
      { "color": "#BBBBBB" }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      { "color": "#444444" }
    ]
  },
  {
    "featureType": "transit",
    "stylers": [
      { "visibility": "off" }
    ]
  },
  {
    "featureType": "water",
    "stylers": [
      { "color": "#1E1E1E" }
    ]
  }
]
''';
class RideSelectionScreen extends StatefulWidget {
  final String fromAddress;
  final String toAddress;
  final LatLng fromLatLng;
  final LatLng toLatLng;
  final int durationMinutes;
  final double distanceKm;
  const RideSelectionScreen({
    Key? key,
    required this.fromAddress,
    required this.toAddress,
    required this.fromLatLng,
    required this.toLatLng,
    required this.durationMinutes,
    required this.distanceKm,
  }) : super(key: key);
  @override
  State<RideSelectionScreen> createState() => _RideSelectionScreenState();
}
class _RideSelectionScreenState extends State<RideSelectionScreen> with TickerProviderStateMixin {
  GoogleMapController? mapController;
  int selectedIndex = 0; 
  int selectedFilter = 0; 
  String paymentMethod = 'Cash';
  String? selectedCardId;
  List<Map<String, dynamic>> _savedCards = [];
  bool _isLoadingCards = true;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Set<Marker> _driverMarkers = {};
  Timer? _driverMarkersTimer;
  BitmapDescriptor? _driverCarIcon;
  String? _driverCarIconRideType;
  Set<String> _availableRideTypes = <String>{};
  Timer? _availabilityTimer;
  double? _userToDestDistanceKm;
  String? _userCountryCode;
  final _geocodingCache = <String, String>{};
  bool get isInFrance => _userCountryCode == 'FR';
  RealtimeChannel? _driverReqChannel;
  bool _hasNavigatedToInProgress = false;
  Timer? _driverReqPollTimer;
  Promotion? _activePromotion;
  bool _isLoadingPromotion = true;
  List<Map<String, dynamic>> rideOptions = [];
  bool _isLoadingEtas = true;
  Timer? _etaTimer;
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  static const double _minSheetSize = 0.30;
  bool _isSheetMinimized = false;
  String? _currentSubscription;
  DateTime? _subscriptionStartDate;
  DateTime? _subscriptionEndDate;
  bool _isLoadingSubscription = true;
  SurgePricingResult? _surgePricingResult;
  bool _isLoadingSurgePricing = true;
  static const bool enableDriverSimulation = false;
  @override
  void initState() {
    super.initState();
    print('RideSelectionScreen initState called');
    print('From: ${widget.fromAddress}');
    print('To: ${widget.toAddress}');
    print('From LatLng: ${widget.fromLatLng}');
    print('To LatLng: ${widget.toLatLng}');
    try {
      _setDepartureMarker();
      _drawRouteFromDepartureToDestination();
      _initUserToDestDistance();
      _detectUserCountry();
      _userCountryCode ??= 'TN';
      _loadSavedCards();
      _loadActivePromotion();
      _loadCurrentSubscription();
      _calculateSurgePricing();
      _initRideOptions();
      _updateDriverCarIconForCurrentType();
      _startDriverMarkersPolling();
      _startAvailabilityPolling();
      _startEtaPolling();
      _sheetController.addListener(() {
        final size = _sheetController.size;
        final isMin = size <= (_minSheetSize + 0.001);
        if (isMin != _isSheetMinimized) {
          setState(() {
            _isSheetMinimized = isMin;
          });
        }
      });
    } catch (e) {
      print('Error in initState: $e');
    }
  }
  @override
  void dispose() {
    try {
      _driverReqChannel?.unsubscribe();
    } catch (_) {}
    try {
      _driverReqPollTimer?.cancel();
    } catch (_) {}
    try {
      _driverMarkersTimer?.cancel();
    } catch (_) {}
    try {
      _availabilityTimer?.cancel();
    } catch (_) {}
    try {
      _etaTimer?.cancel();
    } catch (_) {}
    super.dispose();
  }
  Future<void> _loadActivePromotion() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('promotions')
            .select('*')
            .eq('passenger_id', user.id)
            .not('used_at', 'is', null)
            .order('used_at', ascending: false)
            .limit(1)
            .maybeSingle();
        if (response != null) {
          final promotion = Promotion.fromMap(response);
          if (promotion.isValid) {
            setState(() {
              _activePromotion = promotion;
              _isLoadingPromotion = false;
            });
          } else {
            setState(() {
              _isLoadingPromotion = false;
            });
          }
        } else {
          setState(() {
            _isLoadingPromotion = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingPromotion = false;
      });
    }
  }
  Future<void> _loadCurrentSubscription() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('passenger')
            .select('subscription_plan, subscription_start_date, subscription_end_date')
            .eq('id', user.id)
            .single();
        setState(() {
          _currentSubscription = response['subscription_plan'] ?? 'free';
          _subscriptionStartDate = response['subscription_start_date'] != null 
              ? DateTime.parse(response['subscription_start_date'])
              : null;
          _subscriptionEndDate = response['subscription_end_date'] != null 
              ? DateTime.parse(response['subscription_end_date'])
              : null;
          _isLoadingSubscription = false;
        });
      }
    } catch (e) {
      print('Error loading subscription: $e');
      setState(() {
        _isLoadingSubscription = false;
      });
    }
  }
  Future<void> _calculateSurgePricing() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final double distanceKm = _userToDestDistanceKm ?? widget.distanceKm;
        final countryCode = _userCountryCode ?? 'TN';
        final shouldApplySurge = await _shouldApplySurgePricing(
          lat: widget.fromLatLng.latitude,
          lng: widget.fromLatLng.longitude,
          countryCode: countryCode,
        );
        if (shouldApplySurge) {
          final surgeEvents = await SurgePricingService.getActiveSurgeEvents(
            lat: widget.fromLatLng.latitude,
            lng: widget.fromLatLng.longitude,
            countryCode: countryCode,
          );
                      if (surgeEvents.isNotEmpty) {
              final surgeEvent = surgeEvents.first;
              setState(() {
                _surgePricingResult = SurgePricingResult(
                  finalPrice: 0, 
                  surgeMultiplier: surgeEvent.baseMultiplier,
                  driverBonus: surgeEvent.driverBonusPerRide,
                  subscriptionDiscount: 0,
                  pricingBreakdown: {},
                  hasSurge: true,
                  surgeZoneName: null,
                  eventType: surgeEvent.eventType,
                  eventName: surgeEvent.eventName,
                );
                _isLoadingSurgePricing = false;
              });
            }
        } else {
          setState(() {
            _surgePricingResult = null;
            _isLoadingSurgePricing = false;
          });
        }
      }
    } catch (e) {
      print('Error calculating surge pricing: $e');
      setState(() {
        _isLoadingSurgePricing = false;
      });
    }
  }
  Future<bool> _shouldApplySurgePricing({
    required double lat,
    required double lng,
    required String countryCode,
  }) async {
    try {
      final surgeEvents = await SurgePricingService.getActiveSurgeEvents(
        lat: lat,
        lng: lng,
        countryCode: countryCode,
      );
      return surgeEvents.isNotEmpty;
    } catch (e) {
      print('Error checking surge pricing: $e');
      return false;
    }
  }
  Future<void> _loadSavedCards() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('payment_cards')
            .select('*')
            .eq('passenger_uid', user.id)
            .order('is_default', ascending: false);
        setState(() {
          _savedCards = List<Map<String, dynamic>>.from(response);
          _isLoadingCards = false;
        });
        if (_savedCards.isNotEmpty) {
          final defaultCard = _savedCards.firstWhere(
            (card) => card['is_default'] == true,
            orElse: () => _savedCards.first,
          );
          setState(() {
            selectedCardId = defaultCard['id'];
            paymentMethod = 'Card';
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingCards = false;
      });
    }
  }
  String _getCardDisplayName(Map<String, dynamic> card) {
    final cardType = card['card_type'] ?? 'Card';
    final lastFour = card['card_number'] ?? '****';
    return '$cardType •••• $lastFour';
  }
  String? _getCardIcon(String? cardType) {
    switch (cardType?.toLowerCase()) {
      case 'visa':
        return 'assets/cards/visa.png';
      case 'mastercard':
        return 'assets/cards/mastercard.png';
      case 'amex':
        return 'assets/cards/amex.png';
      case 'discover':
        return 'assets/cards/discover.png';
      case 'paypal':
        return 'assets/cards/paypal.png';
      default:
        return null; 
    }
  }
  Future<void> _setDepartureMarker() async {
    final markerIcon = await GlassyWaypointMarker.generateBitmapDescriptor(
      durationMinutes: widget.durationMinutes,
      distanceKm: widget.distanceKm,
    );
    final remainingDistanceKm = await _calculateRemainingDistance();
    final destinationIcon = await GlassyDestinationMarker.generateBitmapDescriptor(distanceKm: remainingDistanceKm);
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('departure'),
          position: widget.fromLatLng,
          icon: markerIcon,
          anchor: const Offset(0.5, 1.0),
        ),
        Marker(
          markerId: const MarkerId('destination'),
          position: widget.toLatLng,
          icon: destinationIcon,
          anchor: const Offset(0.5, 1.0),
        ),
      };
    });
  }
  Future<double> _calculateRemainingDistance() async {
    final currentPosition = await Geolocator.getCurrentPosition();
    final distanceInMeters = Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      widget.toLatLng.latitude,
      widget.toLatLng.longitude,
    );
    return distanceInMeters / 1000;
  }
  Future<void> _drawRouteFromDepartureToDestination() async {
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${widget.fromLatLng.latitude},${widget.fromLatLng.longitude}&destination=${widget.toLatLng.latitude},${widget.toLatLng.longitude}&key=AIzaSyDaIk1468iXr5IaRhHvYe32tnWgLqyyTg4';
    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);
    if (data['routes'] != null && data['routes'].isNotEmpty) {
      final points = data['routes'][0]['overview_polyline']['points'];
      final List<List<num>> decoded = poly.decodePolyline(points);
      final List<LatLng> polylineCoords = decoded.map((e) => LatLng(e[0].toDouble(), e[1].toDouble())).toList();
      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            color: Colors.white,
            width: 4,
            points: polylineCoords,
          ),
        };
      });
    }
  }
  Future<void> _initUserToDestDistance() async {
    final distance = await _calculateRemainingDistance();
    setState(() {
      _userToDestDistanceKm = distance;
    });
  }
  Future<void> _detectUserCountry() async {
    final position = await Geolocator.getCurrentPosition();
    final apiKey = 'AIzaSyDaIk1468iXr5IaRhHvYe32tnWgLqyyTg4';
    final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$apiKey';
    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);
    if (data['results'] != null && data['results'].isNotEmpty) {
      for (var result in data['results']) {
        for (var comp in result['address_components']) {
          if (comp['types'].contains('country')) {
            setState(() {
              _userCountryCode = comp['short_name'];
            });
            return;
          }
        }
      }
    }
    setState(() {
      _userCountryCode = null;
    });
  }
  double calculateRidePrice(double distanceKm) {
    final countryCode = _userCountryCode ?? 'TN';
    final applySurge = PricingUtils.shouldApplySurgePricing(countryCode);
    return PricingUtils.calculateCarPrice(
      countryCode: countryCode,
      distanceKm: distanceKm,
      durationMinutes: widget.durationMinutes,
      applySurge: applySurge,
    );
  }
  double applyPromotionDiscount(double originalPrice) {
    if (_activePromotion != null && _activePromotion!.isValid) {
      final discountAmount = originalPrice * (_activePromotion!.percent / 100);
      return originalPrice - discountAmount;
    }
    return originalPrice;
  }
  double applySubscriptionDiscount(double originalPrice) {
    if (_currentSubscription != null && 
        _currentSubscription != 'free' && 
        _subscriptionEndDate != null && 
        _subscriptionEndDate!.isAfter(DateTime.now())) {
      switch (_currentSubscription) {
        case 'saver':
          return originalPrice * 0.9;
        case 'premium':
          return originalPrice * 0.8;
        default:
          return originalPrice;
      }
    }
    return originalPrice;
  }
  double calculateFinalPrice(double originalPrice) {
    double priceAfterSubscription = applySubscriptionDiscount(originalPrice);
    return applyPromotionDiscount(priceAfterSubscription);
  }
  bool get hasActiveSubscription {
    return _currentSubscription != null && 
           _currentSubscription != 'free' && 
           _subscriptionEndDate != null && 
           _subscriptionEndDate!.isAfter(DateTime.now());
  }
  String get subscriptionDiscountText {
    if (!hasActiveSubscription) return '';
    switch (_currentSubscription) {
      case 'saver':
        return '10% off';
      case 'premium':
        return '20% off';
      default:
        return '';
    }
  }
  Future<String> _getUserCurrency() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
      final wallet = await Supabase.instance.client
            .from('passenger_wallets')
          .select('currency')
          .eq('passenger_uid', user.id)
          .maybeSingle();
      if (wallet != null && wallet['currency'] != null) {
        return wallet['currency'];
      } else {
          return PricingUtils.getCurrency(_userCountryCode ?? 'TN');
      }
      } catch (e) {
        print('Error getting user currency: $e');
        return PricingUtils.getCurrency(_userCountryCode ?? 'TN');
    }
    }
    return PricingUtils.getCurrency(_userCountryCode ?? 'TN');
  }
  Future<int> fetchClosestDriverEta(String rideType, double lat, double lng) async {
  try {
    final response = await Supabase.instance.client
        .rpc('get_closest_driver_eta', params: {
          'p_lat': lat,
          'p_lng': lng,
          'p_ride_type': _normalizeRideType(rideType),
        });
    if (response is int) return response;
    if (response is double) return response.round();
    if (response is num) return response.toInt();
    if (response is Map) {
      final value = response['get_closest_driver_eta'];
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is num) return value.toInt();
      print('Unknown value in map: $value (${value.runtimeType})');
      final dataWrapped = response['data'];
      if (dataWrapped is int) return dataWrapped;
      if (dataWrapped is double) return dataWrapped.round();
      if (dataWrapped is num) return dataWrapped.toInt();
    } else {
      print('Unknown response type: ${response.runtimeType}');
    }
  } catch (e) {
    print('Error in fetchClosestDriverEta: $e');
    final mockEtas = {
      'flytt': 5,
      'comfort': 8,
      'taxi': 3,
      'eco': 6,
      'woman': 10,
      'flyttxl': 12,
    };
    return mockEtas[rideType] ?? 8;
  }
  return 8; 
}
  Future<List<Map<String, dynamic>>> getClosestDrivers(String rideType, double lat, double lng) async {
    try {
      final response = await Supabase.instance.client
          .rpc('get_closest_drivers', params: {
            'p_lat': lat,
            'p_lng': lng,
            'p_ride_type': _normalizeRideType(rideType),
            'p_limit': 10, 
          });
      print('get_closest_drivers raw: $response');
      if (response is List) {
        return _normalizeDriverList(List<Map<String, dynamic>>.from(response));
      }
      if (response is Map && response['data'] is List) {
        return _normalizeDriverList(List<Map<String, dynamic>>.from(response['data'] as List));
      }
      print('Unexpected response type: ${response.runtimeType}');
      return [];
    } catch (e) {
      print('Error in getClosestDrivers: $e');
      return [];
    }
  }
  String _normalizeRideType(String rideType) {
    final lower = rideType.toLowerCase();
    switch (lower) {
      case 'flytt':
        return 'flytt';
      case 'flyttxl':
        return 'flyttxl';
      default:
        return lower;
    }
  }
  List<Map<String, dynamic>> _normalizeDriverList(List<Map<String, dynamic>> input) {
    return input.map((raw) {
      final Map<String, dynamic> m = Map<String, dynamic>.from(raw);
      final driverUid = m['driver_uid'] ?? m['driver_id'] ?? m['uid'] ?? m['id'];
      final distance = m['distance_km'] ?? m['distance'] ?? m['dist_km'] ?? m['distance_meters'];
      final eta = m['eta_minutes'] ?? m['eta'] ?? m['eta_min'] ?? m['eta_minute'];
      double? distanceKm;
      if (distance is num) {
        distanceKm = distance.toDouble();
      } else if (distance is String) {
        distanceKm = double.tryParse(distance);
      }
      if (m['distance_meters'] != null && distanceKm == null) {
        final meters = m['distance_meters'];
        if (meters is num) distanceKm = meters.toDouble() / 1000.0;
      }
      int? etaMinutes;
      if (eta is num) {
        etaMinutes = eta.toInt();
      } else if (eta is String) {
        etaMinutes = int.tryParse(eta);
      }
      return {
        'driver_uid': driverUid,
        'distance_km': distanceKm ?? 1.0,
        'eta_minutes': etaMinutes ?? 8,
      };
    }).where((e) => e['driver_uid'] != null).toList();
  }
  Future<String?> findAndRequestDriver(String rideId, String rideType, double lat, double lng) async {
    try {
      print('Finding drivers for ride: $rideId, type: $rideType');
      var drivers = await getClosestDrivers(rideType, lat, lng);
      if (drivers.isEmpty) {
        print('No available drivers found from backend.');
        if (enableDriverSimulation) {
          print('Driver simulation enabled: creating a simulated driver.');
          drivers = [
            {
              'driver_uid': 'SIM_DRIVER_${DateTime.now().millisecondsSinceEpoch}',
              'distance_km': 1.2,
              'eta_minutes': 5,
            }
          ];
        } else {
          return null;
        }
      }
      print('Found ${drivers.length} available drivers');
      for (int i = 0; i < drivers.length; i++) {
        final driver = drivers[i];
        final driverUid = driver['driver_uid'];
        final distanceKm = (driver['distance_km'] is num) ? (driver['distance_km'] as num).toDouble() : 1.0;
        final etaMinutes = (driver['eta_minutes'] is num) ? (driver['eta_minutes'] as num).toInt() : 8;
        print('Trying driver ${i + 1}/${drivers.length}: $driverUid (${distanceKm.toStringAsFixed(2)}km away)');
        if (driverUid.toString().startsWith('SIM_DRIVER_')) {
          return driverUid;
        }
        final requestSent = await sendRideRequestToDriver(rideId, driverUid, distanceKm, etaMinutes);
        if (!requestSent) {
          print('Failed to send request to driver: $driverUid');
          continue;
        }
        final accepted = await waitForDriverResponseRealtime(rideId, driverUid, timeout: const Duration(seconds: 60));
        if (accepted) {
          print('Driver accepted: $driverUid');
          return driverUid;
        } else {
          print('Driver rejected or timed out: $driverUid');
        }
      }
      print('No drivers accepted the ride request');
      return null;
    } catch (e) {
      print('Error in findAndRequestDriver: $e');
      return null;
    }
  }
  Future<bool> sendRideRequestToDriver(String rideId, String driverUid, double distanceKm, int etaMinutes) async {
    try {
      await Supabase.instance.client
          .from('driver_requests')
          .insert({
            'ride_id': rideId,
            'driver_uid': driverUid,
            'status': 'pending',
            'distance_km': distanceKm,
            'eta_minutes': etaMinutes,
          });
      return true;
    } catch (e) {
      print('Error inserting driver request: $e');
      return false;
    }
  }
  Future<bool> waitForDriverResponseRealtime(String rideId, String driverUid, {Duration timeout = const Duration(seconds: 30)}) async {
    final completer = Completer<bool>();
    final channelName = 'driver_req_${rideId}_$driverUid';
    final channel = Supabase.instance.client.channel(channelName);
    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'driver_requests',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'ride_id',
        value: rideId,
      ),
      callback: (payload) {
        try {
          final newRec = payload.newRecord;
          if (newRec == null) return;
          if (newRec['driver_uid']?.toString() != driverUid.toString()) return;
          final status = newRec['status']?.toString();
          if (status == 'accepted') {
            if (!completer.isCompleted) completer.complete(true);
          } else if (status == 'rejected' || status == 'expired') {
            if (!completer.isCompleted) completer.complete(false);
          }
        } catch (e) {
          print('Realtime payload error: $e');
        }
      },
    );
    await channel.subscribe();
    try {
      final existing = await Supabase.instance.client
          .from('driver_requests')
          .select('status')
          .eq('ride_id', rideId)
          .eq('driver_uid', driverUid)
          .single();
      final status = existing['status']?.toString();
      if (status == 'accepted') {
        if (!completer.isCompleted) completer.complete(true);
      } else if (status == 'rejected' || status == 'expired') {
        if (!completer.isCompleted) completer.complete(false);
      }
    } catch (_) {}
    Future.delayed(timeout, () {
      if (!completer.isCompleted) completer.complete(false);
    });
    final result = await completer.future;
    try {
      await channel.unsubscribe();
    } catch (_) {}
    return result;
  }
  void _listenForDriverRequestAcceptance({
    required String rideId,
    required double priceSnapshot,
  }) {
    if (_driverReqChannel != null) return; 
    final channelName = 'driver_req_$rideId';
    final channel = Supabase.instance.client.channel(channelName);
    _driverReqChannel = channel;
    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'driver_requests',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'ride_id',
        value: rideId,
      ),
      callback: (payload) async {
        try {
          print('driver_requests UPDATE payload: ${payload.newRecord}');
          final newRec = payload.newRecord;
          if (newRec == null) return;
          final status = newRec['status']?.toString();
          if (status == 'accepted' && !_hasNavigatedToInProgress) {
            final driverUid = newRec['driver_uid']?.toString();
            print('driver_requests accepted by $driverUid, navigating...');
            _hasNavigatedToInProgress = true;
            try { await _driverReqChannel?.unsubscribe(); } catch (_) {}
            try { _driverReqPollTimer?.cancel(); } catch (_) {}
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => RideInProgressScreen(
                  fromAddress: widget.fromAddress,
                  toAddress: widget.toAddress,
                  price: priceSnapshot,
                  paymentMethod: paymentMethod,
                  durationMinutes: widget.durationMinutes,
                  distanceKm: widget.distanceKm,
                  rideId: rideId,
                  fromLatLng: widget.fromLatLng,
                  toLatLng: widget.toLatLng,
                  driverUid: driverUid,
                ),
              ),
            );
          }
        } catch (e) {
          print('Error handling driver_requests realtime update: $e');
        }
      },
    );
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'driver_requests',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'ride_id',
        value: rideId,
      ),
      callback: (payload) async {
        try {
          print('driver_requests INSERT payload: ${payload.newRecord}');
          final newRec = payload.newRecord;
          if (newRec == null) return;
          final status = newRec['status']?.toString();
          if (status == 'accepted' && !_hasNavigatedToInProgress) {
            final driverUid = newRec['driver_uid']?.toString();
            print('driver_requests accepted on INSERT by $driverUid, navigating...');
            _hasNavigatedToInProgress = true;
            try { await _driverReqChannel?.unsubscribe(); } catch (_) {}
            try { _driverReqPollTimer?.cancel(); } catch (_) {}
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => RideInProgressScreen(
                  fromAddress: widget.fromAddress,
                  toAddress: widget.toAddress,
                  price: priceSnapshot,
                  paymentMethod: paymentMethod,
                  durationMinutes: widget.durationMinutes,
                  distanceKm: widget.distanceKm,
                  rideId: rideId,
                  fromLatLng: widget.fromLatLng,
                  toLatLng: widget.toLatLng,
                  driverUid: driverUid,
                ),
              ),
            );
          }
        } catch (e) {
          print('Error handling driver_requests realtime insert: $e');
        }
      },
    );
    channel.subscribe();
    _checkDriverRequestAcceptedOnce(rideId: rideId, priceSnapshot: priceSnapshot);
    _startDriverRequestPolling(rideId: rideId, priceSnapshot: priceSnapshot, maxAttempts: 15, interval: const Duration(seconds: 2));
  }
  Future<void> _checkDriverRequestAcceptedOnce({
    required String rideId,
    required double priceSnapshot,
  }) async {
    if (_hasNavigatedToInProgress) return;
    try {
      final resp = await Supabase.instance.client
          .from('driver_requests')
          .select('status, driver_uid')
          .eq('ride_id', rideId)
          .eq('status', 'accepted')
          .limit(1)
          .maybeSingle();
      if (resp != null) {
        print('driver_requests already accepted; navigating...');
        _hasNavigatedToInProgress = true;
        try { await _driverReqChannel?.unsubscribe(); } catch (_) {}
        try { _driverReqPollTimer?.cancel(); } catch (_) {}
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RideInProgressScreen(
              fromAddress: widget.fromAddress,
              toAddress: widget.toAddress,
              price: priceSnapshot,
              paymentMethod: paymentMethod,
              durationMinutes: widget.durationMinutes,
              distanceKm: widget.distanceKm,
              rideId: rideId,
              fromLatLng: widget.fromLatLng,
              toLatLng: widget.toLatLng,
              driverUid: resp['driver_uid']?.toString(),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error checking driver_requests accepted state: $e');
    }
  }
  void _startDriverRequestPolling({
    required String rideId,
    required double priceSnapshot,
    required int maxAttempts,
    required Duration interval,
  }) {
    int attempts = 0;
    _driverReqPollTimer?.cancel();
    _driverReqPollTimer = Timer.periodic(interval, (t) async {
      if (_hasNavigatedToInProgress) {
        t.cancel();
        return;
      }
      attempts += 1;
      if (attempts > maxAttempts) {
        print('Polling timeout for driver_requests acceptance');
        t.cancel();
        return;
      }
      try {
        final resp = await Supabase.instance.client
            .from('driver_requests')
            .select('status, driver_uid')
            .eq('ride_id', rideId)
            .eq('status', 'accepted')
            .limit(1)
            .maybeSingle();
        if (resp != null && !_hasNavigatedToInProgress) {
          print('driver_requests accepted via polling; navigating...');
          _hasNavigatedToInProgress = true;
          try { await _driverReqChannel?.unsubscribe(); } catch (_) {}
          try { _driverReqPollTimer?.cancel(); } catch (_) {}
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RideInProgressScreen(
                fromAddress: widget.fromAddress,
                toAddress: widget.toAddress,
                price: priceSnapshot,
                paymentMethod: paymentMethod,
                durationMinutes: widget.durationMinutes,
                distanceKm: widget.distanceKm,
                rideId: rideId,
                fromLatLng: widget.fromLatLng,
              toLatLng: widget.toLatLng,
              driverUid: resp['driver_uid']?.toString(),
              ),
            ),
          );
        }
      } catch (e) {
        print('Polling error for driver_requests: $e');
      }
    });
  }
  Future<void> _initRideOptions() async {
    final double distanceKm = _userToDestDistanceKm ?? widget.distanceKm;
    final countryCode = _userCountryCode ?? 'TN';
    final currency = PricingUtils.getCurrency(countryCode);
    final isNight = PricingUtils.isNightTime(countryCode);
    final surgeMultiplier = _surgePricingResult?.surgeMultiplier;
    final hasSurge = surgeMultiplier != null && surgeMultiplier > 1.0;
    final carBasePrice = PricingUtils.calculateCarPrice(
      countryCode: countryCode,
      distanceKm: distanceKm,
      durationMinutes: widget.durationMinutes,
      applySurge: hasSurge,
      customSurgeMultiplier: surgeMultiplier,
    );
    final List<Map<String, dynamic>> baseOptions = [
      {
        'name': 'Flytt',
        'ride_type': 'flytt',
        'price': calculateFinalPrice(carBasePrice * 1),
        'originalPrice': carBasePrice * 1,
        'image': 'assets/images/flytt.png',
        'eco': true,
        'time': null,
        'capacity': 4,
        'isRecommended': true,
      },
      {
        'name': 'Comfort',
        'ride_type': 'comfort',
        'price': calculateFinalPrice(carBasePrice),
        'originalPrice': carBasePrice,
        'image': 'assets/images/comfort.png',
        'eco': false,
        'time': null,
        'capacity': 4,
      },
      {
        'name': 'Taxi',
        'ride_type': 'taxi',
        'price': calculateFinalPrice(carBasePrice * 1.1),
        'originalPrice': carBasePrice * 1.1,
        'image': 'assets/images/taxi.png',
        'eco': false,
        'time': null,
        'capacity': 4,
      },
      {
        'name': 'Eco',
        'ride_type': 'eco',
        'price': calculateFinalPrice(carBasePrice * 1),
        'originalPrice': carBasePrice * 1,
        'image': 'assets/images/eco.png',
        'eco': true,
        'time': null,
        'capacity': 4,
      },
      {
        'name': 'Woman',
        'ride_type': 'woman',
        'price': calculateFinalPrice(carBasePrice * 1),
        'originalPrice': carBasePrice * 1,
        'image': 'assets/images/woman.png',
        'eco': false,
        'time': null,
        'capacity': 4,
      },
      {
        'name': 'FlyttXL',
        'ride_type': 'flyttxl',
        'price': calculateFinalPrice(carBasePrice * 1.2),
        'originalPrice': carBasePrice * 1.2,
        'image': 'assets/images/flyttxl.png',
        'eco': false,
        'time': null,
        'capacity': 8,
      },
    ];
    setState(() {
      rideOptions = baseOptions;
      _isLoadingEtas = true;
    });
    for (int i = 0; i < rideOptions.length; i++) {
      final eta = await fetchClosestDriverEta(
        rideOptions[i]['ride_type'],
        widget.fromLatLng.latitude,
        widget.fromLatLng.longitude,
      );
      setState(() {
        rideOptions[i]['time'] = '$eta min';
      });
    }
    setState(() {
      _isLoadingEtas = false;
    });
  }
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    controller.setMapStyle(mapStyle);
  }
  String _assetForRideType(String rideType) {
    switch (rideType.toLowerCase()) {
      case 'flytt':
        return 'assets/images/flytt_2d.png';
      case 'comfort':
        return 'assets/images/comfort_2d.png';
      case 'taxi':
        return 'assets/images/taxi_2d.png';
      case 'eco':
        return 'assets/images/eco_2d.png';
      case 'woman':
        return 'assets/images/woman_2d.png';
      case 'flyttxl':
        return 'assets/images/flyttxl_2d.png';
      default:
        return 'assets/images/flytt_2d.png';
    }
  }
  Future<void> _loadDriverCarIcon(String rideType) async {
    try {
      final asset = _assetForRideType(rideType);
      _driverCarIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(12, 12)),
        asset,
      );
      _driverCarIconRideType = rideType;
    } catch (e) {
      _driverCarIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      _driverCarIconRideType = rideType;
    }
  }
  Future<void> _updateDriverCarIconForCurrentType() async {
    final rt = _currentSelectedRideType();
    if (_driverCarIconRideType == rt && _driverCarIcon != null) return;
    await _loadDriverCarIcon(rt);
    if (!mounted) return;
    setState(() {});
  }
  void _startDriverMarkersPolling() {
    _driverMarkersTimer?.cancel();
    _driverMarkersTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      await _fetchAndRenderNearbyDrivers();
    });
  }
  void _startAvailabilityPolling() {
    _availabilityTimer?.cancel();
    _availabilityTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      await _refreshRideTypeAvailability();
    });
    _refreshRideTypeAvailability();
  }
  void _startEtaPolling() {
    _etaTimer?.cancel();
    _etaTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      await _refreshEtas();
    });
    _refreshEtas();
  }
  Future<void> _refreshEtas() async {
    try {
      if (!mounted || rideOptions.isEmpty) return;
      for (int i = 0; i < rideOptions.length; i++) {
        final rideType = rideOptions[i]['ride_type'];
        final eta = await fetchClosestDriverEta(
          rideType,
          widget.fromLatLng.latitude,
          widget.fromLatLng.longitude,
        );
        if (!mounted) return;
        setState(() {
          rideOptions[i]['time'] = '$eta min';
        });
      }
    } catch (e) {
    }
  }
  Future<void> _refreshRideTypeAvailability() async {
    try {
      final rows = await Supabase.instance.client
          .from('driver')
          .select('ride_type')
          .eq('is_available', true)
          .eq('is_online', true)
          .not('lat', 'is', null)
          .not('lng', 'is', null)
          .limit(200);
      if (!mounted) return;
      final List data = rows is List ? rows : [];
      final next = <String>{};
      for (final r in data) {
        final t = r['ride_type']?.toString();
        if (t != null && t.isNotEmpty) next.add(_normalizeRideType(t));
      }
      setState(() {
        _availableRideTypes = next;
      });
    } catch (e) {
    }
  }
  String _currentSelectedRideType() {
    final safeSelectedIndex = selectedIndex < rideOptions.length ? selectedIndex : 0;
    final type = rideOptions.isNotEmpty ? (rideOptions[safeSelectedIndex]['ride_type']?.toString() ?? 'flytt') : 'flytt';
    return _normalizeRideType(type);
  }
  bool _shouldStartMinimized() {
    int availableCount = 0;
    for (final ride in rideOptions) {
      final t = _normalizeRideType(ride['ride_type']);
      if (_availableRideTypes.contains(t)) {
        availableCount += 1;
      }
    }
    return availableCount <= 1; 
  }
  Future<void> _fetchAndRenderNearbyDrivers() async {
    try {
      final rideType = _currentSelectedRideType();
      if (_driverCarIconRideType != rideType) {
        await _loadDriverCarIcon(rideType);
      }
      final rows = await Supabase.instance.client
          .from('driver')
          .select('uid, lat, lng')
          .eq('ride_type', rideType)
          .eq('is_available', true)
          .eq('is_online', true)
          .not('lat', 'is', null)
          .not('lng', 'is', null)
          .limit(50);
      if (!mounted) return;
      final List data = rows is List ? rows : [];
      final BitmapDescriptor icon = _driverCarIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      final newMarkers = <Marker>{};
      for (final r in data) {
        final lat = (r['lat'] as num?)?.toDouble();
        final lng = (r['lng'] as num?)?.toDouble();
        final uid = r['uid']?.toString() ?? '${lat}_${lng}';
        if (lat == null || lng == null) continue;
        newMarkers.add(
          Marker(
            markerId: MarkerId('drv_$uid'),
            position: LatLng(lat, lng),
            icon: icon,
            anchor: const Offset(0.5, 0.5),
            zIndex: 1.0,
          ),
        );
      }
      setState(() {
        _driverMarkers = newMarkers;
      });
    } catch (e) {
    }
  }
  @override
  Widget build(BuildContext context) {
    print('RideSelectionScreen build called');
    final themeProvider = Provider.of<ThemeProvider>(context);
    final double distanceKm = _userToDestDistanceKm ?? widget.distanceKm;
    final double basePrice = calculateRidePrice(distanceKm);
    print('Distance: $distanceKm, Base Price: $basePrice');
    final safeSelectedIndex = selectedIndex < rideOptions.length ? selectedIndex : 0;
    print('Ride options count: ${rideOptions.length}');
    print('Selected index: $selectedIndex, Safe index: $safeSelectedIndex');
    if (rideOptions.isEmpty) {
      print('WARNING: No ride options available, adding fallback');
    }
    final bool promoActive = selectedFilter == 1;
    return Scaffold(
      backgroundColor: RydyColors.darkBg,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF181818), Color(0xFF232323), Color(0xFF232B3E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.fromLatLng,
              zoom: 13.5,
            ),
            onMapCreated: _onMapCreated,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
            markers: {..._markers, ..._driverMarkers},
            polylines: _polylines,
          ),
          Positioned(
            top: 32,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: RydyColors.darkBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.13),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: RydyColors.darkBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_back, color: RydyColors.textColor),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.radio_button_checked, color: RydyColors.textColor, size: 16),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                widget.fromAddress,
                                style: TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.w600, fontSize: 15),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.location_on, color: RydyColors.subText, size: 16),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                widget.toAddress,
                                style: TextStyle(color: RydyColors.subText, fontWeight: FontWeight.w400, fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
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
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: _shouldStartMinimized() ? _minSheetSize : 0.55,
            minChildSize: _minSheetSize,
            maxChildSize: 0.85,
            snap: true,
            snapSizes: const [0.35, 0.55, 0.85],
            builder: (context, scrollController) {
              print('DraggableScrollableSheet builder called');
              print('Ride options length: ${rideOptions.length}');
              return ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                child: Container(
                  decoration: BoxDecoration(
                    color: RydyColors.darkBg,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.13),
                        blurRadius: 24,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 5,
                        margin: const EdgeInsets.only(top: 10, bottom: 18),
                        decoration: BoxDecoration(
                          color: RydyColors.subText.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      if (_activePromotion != null && _activePromotion!.isValid)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.local_offer, color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${_activePromotion!.code} - ${_activePromotion!.percent}% off applied!',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (hasActiveSubscription)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: RydyColors.textColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: RydyColors.textColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.star_rounded, color: RydyColors.textColor, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${AppLocalizations.of(context).translate(_currentSubscription!)} - $subscriptionDiscountText applied!',
                                  style: TextStyle(
                                    color: RydyColors.textColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                         child: rideOptions.isEmpty 
                           ? Center(
                               child: Text(
                                 'No ride options available',
                                 style: TextStyle(color: RydyColors.textColor),
                               ),
                             )
                           : ListView.builder(
                               controller: scrollController,
                              padding: const EdgeInsets.only(bottom: 20),
                              itemCount: rideOptions.length,
                              itemBuilder: (context, idx) {
                                print('Building ride option $idx: ${rideOptions[idx]['name']}');
                                final ride = rideOptions[idx];
                                final isSelected = idx == safeSelectedIndex;
                                final hasPromotionDiscount = _activePromotion != null && _activePromotion!.isValid;
                                final hasSubscriptionDiscount = hasActiveSubscription;
                                final hasAnyDiscount = hasPromotionDiscount || hasSubscriptionDiscount;
                                final String rideType = _normalizeRideType(ride['ride_type']);
                                final bool isAvailableType = _availableRideTypes.contains(rideType);
                                if (_isSheetMinimized) {
                                  final int preferredIndex = safeSelectedIndex < rideOptions.length ? safeSelectedIndex : 0;
                                  if (idx != preferredIndex) {
                                    return const SizedBox.shrink();
                                  }
                                }
                                return AnimatedSize(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                  alignment: Alignment.topCenter,
                                  child: isAvailableType
                                      ? GestureDetector(
                                          onTap: () async {
                                            setState(() => selectedIndex = idx);
                                            await _updateDriverCarIconForCurrentType();
                                            _startDriverMarkersPolling();
                                          },
                                          child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: RydyColors.cardBg,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: isSelected ? RydyColors.textColor : RydyColors.subText.withOpacity(0.13),
                                        width: isSelected ? 2.2 : 1.2,
                                      ),
                                      boxShadow: isSelected
                                          ? [BoxShadow(color: RydyColors.textColor.withOpacity(0.10), blurRadius: 12, offset: const Offset(0, 4))]
                                          : [],
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 54,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: RydyColors.darkBg,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Image.asset(ride['image'], fit: BoxFit.contain),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(ride['name'], style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: RydyColors.textColor)),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(Icons.access_time, size: 15, color: RydyColors.subText),
                                                  const SizedBox(width: 3),
                                                  ride['time'] == null
                                                    ? SizedBox(width: 24, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                                                    : Text(ride['time'], style: TextStyle(fontSize: 13, color: RydyColors.subText)),
                                                  const SizedBox(width: 10),
                                                  Icon(Icons.person, size: 15, color: RydyColors.subText),
                                                  const SizedBox(width: 3),
                                                  Text(ride['capacity'].toString(), style: TextStyle(fontSize: 13, color: RydyColors.subText)),
                                                  if (ride['type'] != null) ...[
                                                    const SizedBox(width: 10),
                                                    Text(ride['type'], style: TextStyle(fontSize: 13, color: RydyColors.subText)),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            if (hasAnyDiscount && ride['originalPrice'] != ride['price'])
                                              Text(
                                                '${ride['originalPrice'].toStringAsFixed(2)} ${PricingUtils.getCurrency(_userCountryCode ?? 'TN')}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: RydyColors.subText,
                                                  decoration: TextDecoration.lineThrough,
                                                ),
                                              ),
                                            Text(
                                              '${ride['price'].toStringAsFixed(2)} ${PricingUtils.getCurrency(_userCountryCode ?? 'TN')}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 19,
                                                color: hasAnyDiscount && ride['originalPrice'] != ride['price'] 
                                                    ? (hasSubscriptionDiscount ? RydyColors.textColor : Colors.green)
                                                    : RydyColors.textColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                              ),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                );
                              },
                            ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: RydyColors.darkBg,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, -2)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                width: 116, 
                                child: GestureDetector(
                                  onTap: () => _showPaymentMethodSheet(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: RydyColors.darkBg,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
                                      border: Border.all(color: RydyColors.subText.withOpacity(0.18)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Image.asset('assets/cards/cash.png', width: 22, height: 22),
                                        const SizedBox(width: 7),
                                        Text(paymentMethod == 'Cash' ? AppLocalizations.of(context).translate('cash') : AppLocalizations.of(context).translate('card'), style: TextStyle(color: RydyColors.subText, fontWeight: FontWeight.w600, fontSize: 15)),
                                        const Icon(Icons.keyboard_arrow_down, color: RydyColors.subText, size: 22),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 52,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        print('Select button pressed');
                                        try {
                                          final user = Supabase.instance.client.auth.currentUser;
                                          print('User: ${user?.id}');
                                          final currency = await _getUserCurrency();
                                          print('Currency: $currency');
                                          final rideInsert = {
                                            'passenger_uid': user?.id,
                                            'from_address': widget.fromAddress,
                                            'to_address': widget.toAddress,
                                            'from_lat': widget.fromLatLng.latitude,
                                            'from_lng': widget.fromLatLng.longitude,
                                            'to_lat': widget.toLatLng.latitude,
                                            'to_lng': widget.toLatLng.longitude,
                                            'distance_km': widget.distanceKm,
                                            'duration_minutes': widget.durationMinutes,
                                            'price': rideOptions[safeSelectedIndex]['price'],
                                            'payment_method': paymentMethod,
                                            'ride_type': _normalizeRideType(rideOptions[safeSelectedIndex]['ride_type']),
                                            'status': 'requested',
                                            'currency': currency,
                                          };
                                          print('Ride insert data: $rideInsert');
                                          if (_activePromotion != null && _activePromotion!.isValid) {
                                            rideInsert['promotion_id'] = _activePromotion!.id;
                                            rideInsert['discount_percent'] = _activePromotion!.percent;
                                            rideInsert['original_price'] = rideOptions[safeSelectedIndex]['originalPrice'];
                                          }
                                          print('Inserting ride into database...');
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  ),
                                                  SizedBox(width: 16),
                                                  Text(AppLocalizations.of(context).translate('finding_driver')),
                                                ],
                                              ),
                                              duration: Duration(seconds: 30),
                                            ),
                                          );
                                          final response = await Supabase.instance.client
                                              .from('rides')
                                              .insert(rideInsert)
                                              .select()
                                              .single();
                                          final rideId = response['id'];
                                          print('Ride inserted successfully with ID: $rideId');
                                          _listenForDriverRequestAcceptance(
                                            rideId: rideId,
                                            priceSnapshot: (rideOptions[safeSelectedIndex]['price'] as num).toDouble(),
                                          );
                                          print('Starting driver matching process...');
                                          final selectedDriverUid = await findAndRequestDriver(
                                            rideId,
                                            rideOptions[safeSelectedIndex]['ride_type'],
                                            widget.fromLatLng.latitude,
                                            widget.fromLatLng.longitude,
                                          );
                                          if (selectedDriverUid != null) {
                                            final isSim = selectedDriverUid.toString().startsWith('SIM_DRIVER_');
                                            if (isSim) {
                                              await Supabase.instance.client
                                                  .from('rides')
                                                  .update({
                                                    'status': 'accepted',
                                                  })
                                                  .eq('id', rideId);
                                            } else {
                                              await Supabase.instance.client
                                                  .from('rides')
                                                  .update({
                                                    'driver_uid': selectedDriverUid,
                                                    'status': 'accepted',
                                                  })
                                                  .eq('id', rideId);
                                            }
                                            print('Driver found and assigned: $selectedDriverUid');
                                          } else {
                                            try {
                                              final rejected = await Supabase.instance.client
                                                  .from('driver_requests')
                                                  .select('status')
                                                  .eq('ride_id', rideId)
                                                  .eq('status', 'rejected');
                                              final hasExplicitRejection = (rejected is List) && rejected.isNotEmpty;
                                              if (hasExplicitRejection) {
                                                await Supabase.instance.client
                                                    .from('rides')
                                                    .update({'status': 'no_drivers_available'})
                                                    .eq('id', rideId);
                                                print('No drivers available for this ride (explicit rejection found)');
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(AppLocalizations.of(context).translate('no_drivers_available')),
                                                    backgroundColor: Colors.orange,
                                                    duration: const Duration(seconds: 3),
                                                  ),
                                                );
                                              } else {
                                                print('No driver accepted yet; no explicit rejection found. Continuing to listen.');
                                              }
                                            } catch (e) {
                                              print('Error checking driver rejections: $e');
                                            }
                                            return; 
                                          }
                                          if (!_hasNavigatedToInProgress) {
                                            print('Navigating to RideInProgressScreen (inline fallback)...');
                                            _hasNavigatedToInProgress = true;
                                            try { await _driverReqChannel?.unsubscribe(); } catch (_) {}
                                            if (!mounted) return; 
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => RideInProgressScreen(
                                                  fromAddress: widget.fromAddress,
                                                  toAddress: widget.toAddress,
                                                  price: (rideOptions[safeSelectedIndex]['price'] as num).toDouble(),
                                                  paymentMethod: paymentMethod,
                                                  durationMinutes: widget.durationMinutes,
                                                  distanceKm: widget.distanceKm,
                                                  rideId: rideId,
                                                  fromLatLng: widget.fromLatLng,
                                                  toLatLng: widget.toLatLng,
                                                ),
                                              ),
                                            );
                                            print('Navigation completed');
                                          }
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(AppLocalizations.of(context).translate('driver_found')),
                                              backgroundColor: Colors.green,
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        } catch (e) {
                                          print('Error in select button: $e');
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(AppLocalizations.of(context).translate('error_requesting_ride').replaceAll('{error}', e.toString())),
                                              backgroundColor: Colors.red,
                                              duration: const Duration(seconds: 3),
                                            ),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: RydyColors.cardBg,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(32),
                                        ),
                                        elevation: 2,
                                      ),
                                                                              child: Text(
                                          '${AppLocalizations.of(context).translate('select')}  ${rideOptions[safeSelectedIndex]['name']}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: RydyColors.textColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const PromotionsScreen()),
                                    );
                                    if (result == true) {
                                      _loadActivePromotion();
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: RydyColors.darkBg,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
                                      border: Border.all(color: RydyColors.subText.withOpacity(0.18)),
                                    ),
                                    child: Icon(
                                      _activePromotion != null && _activePromotion!.isValid 
                                          ? Icons.local_offer 
                                          : Icons.local_offer_outlined,
                                      color: _activePromotion != null && _activePromotion!.isValid 
                                          ? Colors.green 
                                          : RydyColors.subText,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  String _getArrivalTime(BuildContext context) {
    final now = DateTime.now();
    final arrival = now.add(Duration(minutes: widget.durationMinutes));
    final hour = arrival.hour;
    final minute = arrival.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : hour;
    return '$hour12:$minute $period';
  }
  Widget _buildFilterPill(String text, int index, bool isSelected, IconData icon) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final bgColor = isSelected ? RydyColors.cardBg : (isDarkMode ? RydyColors.darkBg : RydyColors.darkBg);
    final borderColor = isSelected ? RydyColors.cardBg : RydyColors.subText.withOpacity(0.18);
    final textColor = isSelected ? RydyColors.textColor : RydyColors.subText;
    final iconColor = isSelected ? RydyColors.textColor : RydyColors.subText;
    return GestureDetector(
      onTap: () => setState(() => selectedFilter = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _showPaymentMethodSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: RydyColors.darkBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: RydyColors.subText.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: Image.asset('assets/cards/cash.png', width: 22, height: 22),
                  title: Text(AppLocalizations.of(context).translate('cash'), style: TextStyle(fontWeight: FontWeight.w600, color: RydyColors.subText, fontSize: 16)),
                  trailing: paymentMethod == 'Cash' ? Icon(Icons.check_circle, color: RydyColors.textColor, size: 22) : null,
                  onTap: () {
                    setState(() {
                      paymentMethod = 'Cash';
                      selectedCardId = null;
                    });
                    Navigator.pop(context);
                  },
                ),
                ..._savedCards.map((card) => ListTile(
                      leading: _getCardIcon(card['card_type']) != null
                          ? Image.asset(
                              _getCardIcon(card['card_type'])!,
                              width: 22,
                              height: 22,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.credit_card, color: paymentMethod == 'Card' && selectedCardId == card['id'] ? RydyColors.subText : RydyColors.subText, size: 22);
                              },
                            )
                          : Icon(Icons.credit_card, color: paymentMethod == 'Card' && selectedCardId == card['id'] ? RydyColors.subText : RydyColors.subText, size: 22),
                      title: Text(_getCardDisplayName(card), style: TextStyle(fontWeight: FontWeight.w600, color: RydyColors.textColor, fontSize: 16)),
                      trailing: paymentMethod == 'Card' && selectedCardId == card['id'] ? Icon(Icons.check_circle, color: RydyColors.subText, size: 22) : null,
                      onTap: () {
                        setState(() {
                          paymentMethod = 'Card';
                          selectedCardId = card['id'];
                        });
                        Navigator.pop(context);
                      },
                    )),
                ListTile(
                  leading: Container(
                    width: 32,
                    height: 22,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Image.asset('assets/cards/visa.png', fit: BoxFit.contain),
                  ),
                  title: Text(AppLocalizations.of(context).translate('add_card'), style: TextStyle(fontWeight: FontWeight.w600, color: RydyColors.textColor.withOpacity(0.7), fontSize: 16)),
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddCardScreen()),
                    );
                    if (result == true) {
                      _loadSavedCards();
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}
class PatternPainter extends CustomPainter {
  final Color color;
  PatternPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const spacing = 20.0;
    for (var i = 0; i < size.width.toInt(); i += spacing.toInt()) {
      for (var j = 0; j < size.height.toInt(); j += spacing.toInt()) {
        canvas.drawCircle(Offset(i.toDouble(), j.toDouble()), 1, paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
class GlassyWaypointMarker extends StatelessWidget {
  final int durationMinutes;
  final double distanceKm;
  const GlassyWaypointMarker({Key? key, required this.durationMinutes, required this.distanceKm}) : super(key: key);
  static Future<BitmapDescriptor> generateBitmapDescriptor({required int durationMinutes, required double distanceKm}) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const double size = 140;
    final Paint paint = Paint()..color = const Color(0xFF4CAF50);
    canvas.drawCircle(const Offset(size / 2, 54), 46, paint);
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(const Offset(size / 2, 54), 46, borderPaint);
    final pillPaint = Paint()..color = const Color(0xFF7EE587);
    final pillRect = Rect.fromCenter(center: Offset(size / 2, 112), width: 12, height: 36);
    final pillRRect = RRect.fromRectAndRadius(pillRect, const Radius.circular(8));
    canvas.drawRRect(pillRRect, pillPaint);
    final textPainter = TextPainter(
      text: TextSpan(
        text: durationMinutes.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 36,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size / 2 - textPainter.width / 2, 38));
    final minPainter = TextPainter(
      text: const TextSpan(
        text: 'min',
        style: TextStyle(
          color: Color(0xFFE0F2F1),
          fontWeight: FontWeight.w500,
          fontSize: 16,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    minPainter.layout();
    minPainter.paint(canvas, Offset(size / 2 - minPainter.width / 2, 82));
    final distPainter = TextPainter(
      text: TextSpan(
        text: '${distanceKm.toStringAsFixed(1)} km',
        style: const TextStyle(
          color: Color(0xFFE0F2F1),
          fontWeight: FontWeight.w500,
          fontSize: 14,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    distPainter.layout();
    distPainter.paint(canvas, Offset(size / 2 - distPainter.width / 2, 104));
    final ui.Image img = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
class GlassyDestinationMarker {
  static Future<BitmapDescriptor> generateBitmapDescriptor({required double distanceKm}) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const double size = 140;
    final Paint paint = Paint()..color = const Color(0xFFE53935);
    canvas.drawCircle(const Offset(size / 2, 54), 46, paint);
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(const Offset(size / 2, 54), 46, borderPaint);
    final pillPaint = Paint()..color = const Color(0xFFEF5350);
    final pillRect = Rect.fromCenter(center: Offset(size / 2, 112), width: 12, height: 36);
    final pillRRect = RRect.fromRectAndRadius(pillRect, const Radius.circular(8));
    canvas.drawRRect(pillRRect, pillPaint);
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${distanceKm.toStringAsFixed(1)} km',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 28,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size / 2 - textPainter.width / 2, 38));
    final ui.Image img = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }
} 
