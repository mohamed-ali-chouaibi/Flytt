import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../utils/theme_provider.dart';
import '../utils/delivery_flow.dart';
import 'delivery_complete_screen.dart';
const String _kGoogleApiKey = 'AIzaSyDaIk1468iXr5IaRhHvYe32tnWgLqyyTg4';
class DeliveryMapFullScreen extends StatefulWidget {
  final Stream<bool>? allDeliveredStream; 
  const DeliveryMapFullScreen({Key? key, this.allDeliveredStream}) : super(key: key);
  @override
  State<DeliveryMapFullScreen> createState() => _DeliveryMapFullScreenState();
}
class _DeliveryMapFullScreenState extends State<DeliveryMapFullScreen> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  late final AnimationController _sheetController;
  late final Animation<Offset> _sheetSlide;
  bool _isLocating = true;
  LatLng? _currentLatLng;
  StreamSubscription<bool>? _allDeliveredSub;
  final List<LatLng> _routePoints = const [
    LatLng(36.8065, 10.1815), 
    LatLng(36.8200, 10.1700),
    LatLng(36.8300, 10.1600),
    LatLng(36.8400, 10.1500),
  ];
  static const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#1A1A1A"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#FFFFFF"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#1A1A1A"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#2B2B2B"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#2B2B2B"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#232323"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#2B2B2B"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#BBBBBB"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#444444"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","stylers":[{"color":"#1E1E1E"}]}
]
''';
  @override
  void initState() {
    super.initState();
    _sheetController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _sheetSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(parent: _sheetController, curve: Curves.easeOutCubic),
    );
    _initLocationAndData();
    if (widget.allDeliveredStream != null) {
      _allDeliveredSub = widget.allDeliveredStream!.listen((done) async {
        if (done && mounted) {
          await Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DeliveryCompleteScreen()),
          );
        }
      });
    }
  }
  Future<void> _initLocationAndData() async {
    await _getCurrentLocation();
    _buildMarkers();
    await _buildPolyline();
    if (mounted) _sheetController.forward();
  }
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocating = true;
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLocating = false);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLocating = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLocating = false);
        return;
      }
      final Position position = await Geolocator.getLastKnownPosition() ?? await Geolocator.getCurrentPosition();
      _currentLatLng = LatLng(position.latitude, position.longitude);
    } catch (e) {
      if (kDebugMode) {
        print('Location error: $e');
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }
  void _buildMarkers() {
    final markers = <Marker>{};
    if (_currentLatLng != null) {
      markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: _currentLatLng!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Driver', snippet: 'Pierre ⭐4.9'),
      ));
    }
    for (int i = 0; i < _routePoints.length; i++) {
      markers.add(Marker(
        markerId: MarkerId('stop_$i'),
        position: _routePoints[i],
        icon: BitmapDescriptor.defaultMarkerWithHue(i < 2 ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(title: 'Stop ${i + 1}'),
      ));
    }
    setState(() => _markers
      ..clear()
      ..addAll(markers));
  }
  Future<void> _buildPolyline() async {
    if (_routePoints.length < 2) {
      return;
    }
    final origin = _routePoints.first;
    final destination = _routePoints.last;
    final waypoints = _routePoints.length > 2
        ? _routePoints.sublist(1, _routePoints.length - 1)
        : <LatLng>[];
    final String wpParam = waypoints.isNotEmpty
        ? '&waypoints=optimize:true|' +
            waypoints.map((p) => '${p.latitude},${p.longitude}').join('|')
        : '';
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '$wpParam'
      '&mode=driving&key=${_kGoogleApiKey}',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final overview = route['overview_polyline'];
          if (overview != null && overview['points'] != null) {
            final String encoded = overview['points'];
            final List<LatLng> decoded = _decodePolyline(encoded);
            final polyline = Polyline(
              polylineId: const PolylineId('route'),
              color: RydyColors.textColor,
              width: 5,
              points: decoded,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              jointType: JointType.round,
            );
            if (!mounted) return;
            setState(() => _polylines
              ..clear()
              ..add(polyline));
            if (_mapController != null) {
              final bounds = _boundsFromLatLngList(decoded);
              await _mapController!.animateCamera(
                CameraUpdate.newLatLngBounds(bounds, 60),
              );
            }
            return;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Directions error: $e');
      }
    }
    final fallback = Polyline(
      polylineId: const PolylineId('route_fallback'),
      color: Colors.lightBlueAccent,
      width: 5,
      points: _routePoints,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      jointType: JointType.round,
    );
    if (!mounted) return;
    setState(() => _polylines
      ..clear()
      ..add(fallback));
  }
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;
      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }
  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double x0 = list.first.latitude, x1 = list.first.latitude;
    double y0 = list.first.longitude, y1 = list.first.longitude;
    for (final LatLng latLng in list) {
      if (latLng.latitude > x1) x1 = latLng.latitude;
      if (latLng.latitude < x0) x0 = latLng.latitude;
      if (latLng.longitude > y1) y1 = latLng.longitude;
      if (latLng.longitude < y0) y0 = latLng.longitude;
    }
    return LatLngBounds(southwest: LatLng(x0, y0), northeast: LatLng(x1, y1));
  }
  @override
  void dispose() {
    _sheetController.dispose();
    _allDeliveredSub?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RydyColors.darkBg,
      body: Stack(
        children: [
          _buildMap(),
          _buildTopBar(context),
          _buildBottomInfo(),
        ],
      ),
    );
  }
  Widget _buildMap() {
    if (_isLocating && _currentLatLng == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final initial = _currentLatLng ?? _routePoints.first;
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: initial, zoom: 13.5),
      onMapCreated: (c) async {
        _mapController = c;
        await _mapController?.setMapStyle(_darkMapStyle);
      },
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
    );
  }
  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: RydyColors.darkBg,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: RydyColors.textColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: RydyColors.darkBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.directions, color: RydyColors.textColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Route Active',
                      style: TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildBottomInfo() {
    return SlideTransition(
      position: _sheetSlide,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: RydyColors.darkBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: RydyColors.cardBg,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('👤 Driver: Pierre ⭐4.9', style: TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text('🚙 Toyota Corolla • 257 TU', style: TextStyle(color: RydyColors.subText)),
                          Text('📱 +33 6 12 34 56 78', style: TextStyle(color: RydyColors.subText)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: RydyColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('ETA 12m', style: TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🎯 Current Destination:', style: TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('John - 12 minutes away', style: TextStyle(color: RydyColors.subText)),
                          Text('3.2 km • ETA 2:33 PM', style: TextStyle(color: RydyColors.subText)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await DeliveryFlowGuard.navigateToCompletionIfDone(context, null);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: RydyColors.textColor,
                          side: BorderSide(color: RydyColors.textColor.withOpacity(0.35)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('📞 Call'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await DeliveryFlowGuard.navigateToCompletionIfDone(context, null);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: RydyColors.textColor,
                          side: BorderSide(color: RydyColors.textColor.withOpacity(0.35)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('💬 Chat'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
