import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'ride_rating_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/theme_provider.dart';
import '../utils/app_localizations.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart' as poly;
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
enum RideState {
  waitingForDriver,    
  driverArrived,       
  drivingToDestination, 
  rideCompleted        
}
class RideInProgressScreen extends StatefulWidget {
  final String fromAddress;
  final String toAddress;
  final double price;
  final String paymentMethod;
  final int durationMinutes;
  final double distanceKm;
  final String rideId;
  final LatLng fromLatLng;
  final LatLng toLatLng;
  final String? driverUid;
  const RideInProgressScreen({
    Key? key,
    required this.fromAddress,
    required this.toAddress,
    required this.price,
    required this.paymentMethod,
    required this.durationMinutes,
    required this.distanceKm,
    required this.rideId,
    required this.fromLatLng,
    required this.toLatLng,
    this.driverUid,
  }) : super(key: key);
  @override
  State<RideInProgressScreen> createState() => _RideInProgressScreenState();
}
class _RideInProgressScreenState extends State<RideInProgressScreen> {
  GoogleMapController? mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  String driverName = 'Driver';
  String driverAvatar = 'assets/images/driver_avatar.png';
  String? rideCurrency = 'TND';
  RealtimeChannel? _rideStatusChannel;
  RealtimeChannel? _driverLocationChannel;
  Timer? _rideUpdateTimer;
  Timer? _driverLocationTimer;
  Map<String, dynamic>? _driverInfo;
  Map<String, dynamic>? _rideInfo;
  bool _isLoadingDriverInfo = true;
  String? _currentRideStatus;
  RideState _currentRideState = RideState.waitingForDriver;
  LatLng? _driverLocation;
  BitmapDescriptor? _driverCarIcon;
  List<LatLng> _driverRoutePoints = [];
  List<LatLng> _rideRoutePoints = [];
  @override
  void initState() {
    super.initState();
    _loadDriverInfo();
    _loadDriverRequestInfo(); 
    _listenForRideUpdates();
    _startRideStatusPolling();
    _loadDriverCarIcon();
    _startDriverLocationTracking();
    _setTestDriverLocation();
  }
  void _setTestDriverLocation() {
    setState(() {
      _driverLocation = LatLng(
        widget.fromLatLng.latitude + 0.01, 
        widget.fromLatLng.longitude + 0.01, 
      );
    });
    print('Test driver location set: ${_driverLocation!.latitude}, ${_driverLocation!.longitude}');
    Future.delayed(const Duration(milliseconds: 500), () {
      _updateDriverMarker();
      _drawRideRoute(); 
    });
  }
  @override
  void dispose() {
    try {
      _rideStatusChannel?.unsubscribe();
    } catch (_) {}
    try {
      _driverLocationChannel?.unsubscribe();
    } catch (_) {}
    try {
      _rideUpdateTimer?.cancel();
    } catch (_) {}
    try {
      _driverLocationTimer?.cancel();
    } catch (_) {}
    super.dispose();
  }
  Future<void> _loadDriverInfo() async {
    if (widget.driverUid == null) return;
    try {
      print('Loading driver info for driver: ${widget.driverUid}');
      final response = await Supabase.instance.client
          .from('driver')
          .select('name, surname, phone, profile_image_url, rating')
          .eq('uid', widget.driverUid!) 
          .maybeSingle();
      print('Driver info response: $response');
      if (response != null) {
        setState(() {
          _driverInfo = response;
          driverName = '${response['name'] ?? ''} ${response['surname'] ?? ''}'.trim();
          driverAvatar = response['profile_image_url'] ?? 'assets/images/driver_avatar.png';
          _isLoadingDriverInfo = false;
        });
        print('Driver info loaded successfully: $driverName');
      } else {
        print('No driver info found');
        setState(() {
          _isLoadingDriverInfo = false;
        });
      }
    } catch (e) {
      print('Error loading driver info: $e');
      setState(() {
        _isLoadingDriverInfo = false;
      });
    }
  }
  Future<void> _loadRideInfo() async {
    try {
      final response = await Supabase.instance.client
          .from('rides')
          .select('status, currency, driver_uid')
          .eq('id', widget.rideId)
          .maybeSingle();
      if (response != null) {
        setState(() {
          _rideInfo = response;
          _currentRideStatus = response['status'];
          rideCurrency = response['currency'] ?? 'TND';
          _updateRideState(response['status']);
        });
      }
    } catch (e) {
      print('Error loading ride info: $e');
    }
  }
  void _updateRideState(String? status) {
    switch (status) {
      case 'pending':
        _currentRideState = RideState.waitingForDriver;
        break;
      case 'accepted':
        _currentRideState = RideState.waitingForDriver;
        if (_driverLocation != null) {
          _drawDriverToPickupRoute();
        }
        break;
      case 'driver_arrived':
        _currentRideState = RideState.driverArrived;
        break;
      case 'in_progress':
        _currentRideState = RideState.drivingToDestination;
        _drawRideRoute();
        break;
      case 'completed':
        _currentRideState = RideState.rideCompleted;
        break;
      case 'cancelled':
      case 'rejected':
        _currentRideState = RideState.waitingForDriver;
        break;
      default:
        _currentRideState = RideState.waitingForDriver;
    }
  }
  void _listenForRideUpdates() {
    final channelName = 'driver_request_updates_${widget.rideId}';
    final channel = Supabase.instance.client.channel(channelName);
    _rideStatusChannel = channel;
    print('Setting up driver_requests listener for ride: ${widget.rideId}');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'driver_requests',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'ride_id',
        value: widget.rideId,
      ),
      callback: (payload) async {
        try {
          print('Driver request update received: ${payload.newRecord}');
          final newRec = payload.newRecord;
          if (newRec == null) return;
          final status = newRec['status']?.toString();
          final driverUid = newRec['driver_uid']?.toString();
          print('Driver request status: $status, driver_uid: $driverUid');
          if (status != null && status != _currentRideStatus) {
            setState(() {
              _currentRideStatus = status;
              _updateRideState(status);
            });
            if (status == 'accepted' && driverUid != null) {
              print('Driver request accepted, updating driver info');
              await _loadDriverInfo();
            } else if (status == 'completed') {
              _handleRideCompleted();
            } else if (status == 'cancelled') {
              _handleRideCancelled();
            }
          }
        } catch (e) {
          print('Error handling driver request update: $e');
        }
      },
    );
    channel.subscribe();
    print('Driver requests channel subscribed');
  }
  void _startRideStatusPolling() {
    _rideUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await _loadDriverRequestInfo();
    });
  }
  Future<void> _loadDriverRequestInfo() async {
    try {
      print('Loading driver request info for ride: ${widget.rideId}');
      final response = await Supabase.instance.client
          .from('driver_requests')
          .select('status, driver_uid, responded_at')
          .eq('ride_id', widget.rideId)
          .order('requested_at', ascending: false)
          .limit(1)
          .maybeSingle();
      print('Driver request response: $response');
      if (response != null) {
        final status = response['status']?.toString();
        final driverUid = response['driver_uid']?.toString();
        print('Driver request status: $status, driver_uid: $driverUid');
        if (status != null && status != _currentRideStatus) {
          setState(() {
            _currentRideStatus = status;
            _updateRideState(status);
          });
          if (status == 'accepted' && driverUid != null) {
            print('Driver request accepted via polling, updating driver info');
            await _loadDriverInfo();
          }
        }
      } else {
        print('No driver request found for this ride');
      }
    } catch (e) {
      print('Error loading driver request info: $e');
    }
  }
  Future<void> _loadDriverCarIcon() async {
    try {
      print('Loading driver car icon: assets/images/flytt_2d.png');
      _driverCarIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(24, 24)),
        'assets/images/flytt_2d.png',
      );
      print('Driver car icon loaded successfully');
    } catch (e) {
      print('Error loading driver car icon: $e');
      try {
        _driverCarIcon = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(24, 24)),
          'assets/images/flytt_2d.png',
        );
        print('Driver car icon loaded from alternative path');
      } catch (e2) {
        print('Error loading from alternative path: $e2');
        _driverCarIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      }
    }
  }
  void _startDriverLocationTracking() {
    if (widget.driverUid == null) return;
    _fetchDriverLocation();
    _listenForDriverLocationUpdates();
    _driverLocationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _fetchDriverLocation();
    });
  }
  void _listenForDriverLocationUpdates() {
    final channelName = 'driver_location_${widget.driverUid}';
    final channel = Supabase.instance.client.channel(channelName);
    _driverLocationChannel = channel;
    print('Setting up driver location listener for driver: ${widget.driverUid}');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'driver',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'uid', 
        value: widget.driverUid,
      ),
      callback: (payload) async {
        try {
          print('Received driver location update: ${payload.newRecord}');
          final newRec = payload.newRecord;
          if (newRec == null) return;
          final lat = newRec['lat'] as double?;
          final lng = newRec['lng'] as double?;
          print('Driver location update - lat: $lat, lng: $lng');
          if (lat != null && lng != null) {
            setState(() {
              _driverLocation = LatLng(lat, lng);
            });
            _updateDriverMarker();
            _updateMapCamera();
          } else {
            print('Driver location coordinates are null');
          }
        } catch (e) {
          print('Error handling driver location update: $e');
        }
      },
    );
    channel.subscribe();
    print('Driver location channel subscribed');
  }
  Future<void> _fetchDriverLocation() async {
    if (widget.driverUid == null) return;
    try {
      print('Fetching driver location for driver: ${widget.driverUid}');
      final response = await Supabase.instance.client
          .from('driver')
          .select('lat, lng, name, surname, rating, profile_image_url')
          .eq('uid', widget.driverUid!) 
          .maybeSingle();
      print('Driver location response: $response');
      if (response != null) {
        final lat = response['lat'] as double?;
        final lng = response['lng'] as double?;
        print('Driver coordinates: lat=$lat, lng=$lng');
        if (lat != null && lng != null) {
          setState(() {
            _driverLocation = LatLng(lat, lng);
          });
          _updateDriverMarker();
        } else {
          print('Driver coordinates are null');
        }
      } else {
        print('No driver location found in database');
      }
    } catch (e) {
      print('Error fetching driver location: $e');
    }
  }
  void _updateDriverMarker() {
    if (_driverLocation == null) {
      print('Driver location is null, cannot update marker');
      return;
    }
    if (_driverCarIcon == null) {
      print('Driver car icon is null, using default marker');
      _driverCarIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
    print('Updating driver marker at: ${_driverLocation!.latitude}, ${_driverLocation!.longitude}');
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverLocation!,
          icon: _driverCarIcon!,
          anchor: const Offset(0.5, 0.5),
          rotation: 0, 
        ),
        Marker(
          markerId: const MarkerId('departure'),
          position: widget.fromLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
        Marker(
          markerId: const MarkerId('destination'),
          position: widget.toLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      };
    });
    if (_currentRideState == RideState.waitingForDriver) {
      print('Drawing driver to pickup route');
      _drawDriverToPickupRoute();
    }
  }
  Future<void> _drawDriverToPickupRoute() async {
    if (_driverLocation == null) {
      print('Driver location is null, cannot draw route');
      return;
    }
    try {
      print('Drawing route from driver to pickup');
      final url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${_driverLocation!.latitude},${_driverLocation!.longitude}&destination=${widget.fromLatLng.latitude},${widget.fromLatLng.longitude}&key=AIzaSyDaIk1468iXr5IaRhHvYe32tnWgLqyyTg4';
      print('Directions URL: $url');
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);
      print('Directions response status: ${data['status']}');
      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final points = data['routes'][0]['overview_polyline']['points'];
        final List<List<num>> decoded = poly.decodePolyline(points);
        final List<LatLng> polylineCoords = decoded.map((e) => LatLng(e[0].toDouble(), e[1].toDouble())).toList();
        print('Decoded polyline points: ${polylineCoords.length}');
        setState(() {
          _driverRoutePoints = polylineCoords;
          _polylines = {
            Polyline(
              polylineId: const PolylineId('driver_route'),
              color: Colors.blue,
              width: 4,
              points: polylineCoords,
            ),
            Polyline(
              polylineId: const PolylineId('ride_route'),
              color: Colors.white,
              width: 4,
              points: _rideRoutePoints.isNotEmpty ? _rideRoutePoints : [
                widget.fromLatLng,
                widget.toLatLng,
              ],
            ),
          };
        });
        print('Polylines updated successfully');
      } else {
        print('No routes found in directions response');
      }
    } catch (e) {
      print('Error drawing driver route: $e');
    }
  }
  Future<void> _drawRideRoute() async {
    try {
      print('Drawing ride route from pickup to destination');
      final url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${widget.fromLatLng.latitude},${widget.fromLatLng.longitude}&destination=${widget.toLatLng.latitude},${widget.toLatLng.longitude}&key=AIzaSyDaIk1468iXr5IaRhHvYe32tnWgLqyyTg4';
      print('Ride route URL: $url');
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);
      print('Ride route response status: ${data['status']}');
      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final points = data['routes'][0]['overview_polyline']['points'];
        final List<List<num>> decoded = poly.decodePolyline(points);
        final List<LatLng> polylineCoords = decoded.map((e) => LatLng(e[0].toDouble(), e[1].toDouble())).toList();
        print('Ride route decoded points: ${polylineCoords.length}');
        setState(() {
          _rideRoutePoints = polylineCoords;
          _polylines = {
            Polyline(
              polylineId: const PolylineId('driver_route'),
              color: Colors.blue,
              width: 4,
              points: _driverRoutePoints,
            ),
            Polyline(
              polylineId: const PolylineId('ride_route'),
              color: Colors.white,
              width: 4,
              points: polylineCoords,
            ),
          };
        });
        print('Ride route polylines updated successfully');
      } else {
        print('No ride route found in directions response');
      }
    } catch (e) {
      print('Error drawing ride route: $e');
    }
  }
  void _updateMapCamera() {
    if (_driverLocation == null || mapController == null) return;
    mapController!.animateCamera(
      CameraUpdate.newLatLng(_driverLocation!),
    );
  }
  void _handleRideCompleted() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RideRatingScreen(
            rideId: widget.rideId,
            driverId: widget.driverUid ?? 'driver-id',
            price: widget.price,
            fromAddress: widget.fromAddress,
            toAddress: widget.toAddress,
          ),
        ),
      );
    }
  }
  void _handleRideCancelled() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('ride_cancelled')),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    }
  }
  Future<bool> _markDriverArrived() async {
    try {
      await Supabase.instance.client
          .from('rides')
          .update({'status': 'driver_arrived'})
          .eq('id', widget.rideId);
      return true;
    } catch (e) {
      print('Error marking driver arrived: $e');
      return false;
    }
  }
  Future<bool> _startRide() async {
    try {
      await Supabase.instance.client
          .from('driver_requests')
          .update({'status': 'in_progress'})
          .eq('ride_id', widget.rideId)
          .eq('status', 'accepted');
      return true;
    } catch (e) {
      print('Error starting ride: $e');
      return false;
    }
  }
  Future<bool> _completeRide() async {
    try {
      await Supabase.instance.client
          .from('driver_requests')
          .update({'status': 'completed'})
          .eq('ride_id', widget.rideId)
          .eq('status', 'in_progress');
      return true;
    } catch (e) {
      print('Error completing ride: $e');
      return false;
    }
  }
  Widget _buildStatusContent() {
    switch (_currentRideState) {
      case RideState.waitingForDriver:
        return _buildWaitingForDriverContent();
      case RideState.driverArrived:
        return _buildDriverArrivedContent();
      case RideState.drivingToDestination:
        return _buildDrivingToDestinationContent();
      case RideState.rideCompleted:
        return _buildRideCompletedContent();
    }
  }
  Widget _buildWaitingForDriverContent() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.blue.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Icon(Icons.directions_car, color: Colors.blue, size: 16),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context).translate('driver_coming'),
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: RydyColors.cardBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            '${widget.durationMinutes} ${AppLocalizations.of(context).translate('min')}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1.2,
              color: RydyColors.textColor,
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildDriverArrivedContent() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.green.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on, color: Colors.green, size: 16),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context).translate('driver_arrived'),
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: RydyColors.cardBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            AppLocalizations.of(context).translate('ready_to_start'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1.2,
              color: RydyColors.textColor,
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildDrivingToDestinationContent() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.orange.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Icon(Icons.navigation, color: Colors.orange, size: 16),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context).translate('on_the_way'),
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: RydyColors.cardBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            '${widget.distanceKm.toStringAsFixed(1)} ${AppLocalizations.of(context).translate('km')}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1.2,
              color: RydyColors.textColor,
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildRideCompletedContent() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.2),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.purple.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.purple, size: 16),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context).translate('ride_completed'),
                style: const TextStyle(
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: RydyColors.cardBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            '${widget.price.toStringAsFixed(2)} ${rideCurrency ?? 'TND'}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1.2,
              color: RydyColors.textColor,
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildActionButton() {
    switch (_currentRideState) {
      case RideState.waitingForDriver:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: null, 
            icon: const Icon(Icons.hourglass_empty, color: RydyColors.subText),
            label: Text(
              AppLocalizations.of(context).translate('waiting_for_driver'),
              style: TextStyle(
                color: RydyColors.subText,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: RydyColors.cardBg.withOpacity(0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              padding: const EdgeInsets.symmetric(vertical: 18),
              elevation: 0,
            ),
          ),
        );
      case RideState.driverArrived:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              final success = await _startRide();
              if (!success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context).translate('error_starting_ride')),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.play_arrow, color: RydyColors.textColor),
            label: Text(
              AppLocalizations.of(context).translate('start_ride'),
              style: TextStyle(
                color: RydyColors.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              padding: const EdgeInsets.symmetric(vertical: 18),
              elevation: 2,
            ),
          ),
        );
      case RideState.drivingToDestination:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              final success = await _completeRide();
              if (!success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context).translate('error_completing_ride')),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.check_circle, color: RydyColors.textColor),
            label: Text(
              AppLocalizations.of(context).translate('finish_ride'),
              style: TextStyle(
                color: RydyColors.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: RydyColors.cardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              padding: const EdgeInsets.symmetric(vertical: 18),
              elevation: 2,
            ),
          ),
        );
      case RideState.rideCompleted:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => RideRatingScreen(
                    rideId: widget.rideId,
                    driverId: widget.driverUid ?? 'driver-id',
                    price: widget.price,
                    fromAddress: widget.fromAddress,
                    toAddress: widget.toAddress,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.star, color: RydyColors.textColor),
            label: Text(
              AppLocalizations.of(context).translate('rate_ride'),
              style: TextStyle(
                color: RydyColors.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              padding: const EdgeInsets.symmetric(vertical: 18),
              elevation: 2,
            ),
          ),
        );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RydyColors.darkBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: CircleAvatar(
              backgroundColor: RydyColors.darkBg,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: RydyColors.textColor),
                onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.fromLatLng,
                zoom: 13.5,
              ),
              onMapCreated: (controller) {
                mapController = controller;
                controller.setMapStyle(mapStyle);
                print('Map created, updating markers...');
                print('Driver location: $_driverLocation');
                print('Driver car icon: $_driverCarIcon');
                _updateDriverMarker();
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapType: MapType.normal,
              markers: _markers,
              polylines: _polylines,
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: RydyColors.darkBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black,
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusContent(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                            radius: 32,
                          backgroundImage: _isLoadingDriverInfo 
                              ? null 
                              : (driverAvatar.startsWith('http') 
                                  ? NetworkImage(driverAvatar) 
                                  : AssetImage(driverAvatar) as ImageProvider),
                          child: _isLoadingDriverInfo 
                              ? CircularProgressIndicator(strokeWidth: 2)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isLoadingDriverInfo ? 'Loading...' : driverName, 
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: RydyColors.textColor)
                                  ),
                              const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      if (_driverInfo?['rating'] != null) ...[
                                        Icon(Icons.star, color: Colors.amber, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          _driverInfo!['rating'].toStringAsFixed(1),
                                          style: const TextStyle(fontSize: 14, color: RydyColors.subText),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                              Text(AppLocalizations.of(context).translate('professional_driver'), style: const TextStyle(fontSize: 14, color: RydyColors.subText)),
                                    ],
                                  ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: RydyColors.cardBg,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              widget.paymentMethod.toLowerCase() == 'cash' 
                                  ? Image.asset('assets/cards/cash.png', width: 18, height: 18)
                                          : Icon(Icons.credit_card, color: RydyColors.textColor, size: 18),
                              const SizedBox(width: 7),
                               Text(AppLocalizations.of(context).translate(widget.paymentMethod.toLowerCase()), style: const TextStyle(fontWeight: FontWeight.w600, color: RydyColors.textColor)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: RydyColors.darkBg,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${widget.price.toStringAsFixed(2)} ${rideCurrency ?? 'TND'}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: RydyColors.textColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _buildActionButton(),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
