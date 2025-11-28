import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/theme_provider.dart';
import '../utils/app_localizations.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:ui' show Size;
const String _darkMapStyle = '''
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
class SetOnMapScreen extends StatefulWidget {
  final LatLng? initialLocation;
  const SetOnMapScreen({Key? key, this.initialLocation}) : super(key: key);
  @override
  State<SetOnMapScreen> createState() => _SetOnMapScreenState();
}
class _SetOnMapScreenState extends State<SetOnMapScreen> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  LatLng? _selectedLatLng;
  String? _selectedAddress;
  bool _loadingAddress = false;
  final _geocodingCache = <String, String>{};
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  BitmapDescriptor? _customMarkerIcon;
  Timer? _debounceTimer;
  bool _isLocating = true;
  @override
  void initState() {
    super.initState();
    _selectedLatLng = widget.initialLocation;
    _loadCustomMarkerIcon();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _slideController.forward();
    if (_selectedLatLng != null) {
      _isLocating = false;
      _reverseGeocode(_selectedLatLng!);
    } else {
      _getCurrentLocation();
    }
  }
  Future<void> _loadCustomMarkerIcon() async {
    try {
      _customMarkerIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(12, 12)),
        'assets/icon/pin.png',
      );
      if (kDebugMode) {
        print('Custom marker loaded successfully');
      }
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (kDebugMode) {
        print('Error loading custom marker icon: $e');
      }
      _customMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      if (!mounted) return;
      setState(() {});
    }
  }
  @override
  void dispose() {
    _slideController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocating = true;
    });
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      setState(() {
        _isLocating = false;
      });
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _isLocating = false;
        });
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _isLocating = false;
      });
      return;
    }
    try {
      final Position position = await Geolocator.getLastKnownPosition() 
          ?? await Geolocator.getCurrentPosition();
      setState(() {
        _selectedLatLng = LatLng(position.latitude, position.longitude);
        _isLocating = false;
      });
      _reverseGeocode(_selectedLatLng!);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current location: $e');
      }
      setState(() {
        _isLocating = false;
      });
    }
  }
  Future<void> _reverseGeocode(LatLng latLng) async {
    setState(() {
      _loadingAddress = true;
    });
    final cacheKey = '${latLng.latitude},${latLng.longitude}';
    if (_geocodingCache.containsKey(cacheKey)) {
      setState(() {
        _selectedAddress = _geocodingCache[cacheKey];
        _loadingAddress = false;
      });
      return;
    }
    final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=AIzaSyDaIk1468iXr5IaRhHvYe32tnWgLqyyTg4';
    final response = await http.get(Uri.parse(url));
    String address = '';
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['results'] != null && data['results'].isNotEmpty) {
        address = data['results'][0]['formatted_address'] ?? '';
      }
    }
    _geocodingCache[cacheKey] = address;
    if (!mounted) return;
    setState(() {
      _selectedAddress = address;
      _loadingAddress = false;
    });
  }
  Set<Marker> _getMarkers() {
    if (_selectedLatLng == null) return {};
    return {
      Marker(
        markerId: const MarkerId('selected_location'),
        position: _selectedLatLng!,
        icon: _customMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        anchor: const Offset(0.5, 1.0), 
        infoWindow: InfoWindow(
          title: AppLocalizations.of(context).translate('selected_location'),
          snippet: _selectedAddress ?? AppLocalizations.of(context).translate('no_address_selected'),
        ),
      ),
    };
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RydyColors.darkBg,
      body: Stack(
        children: [
          _buildMapSection(),
          _buildTopAppBar(),
          _buildBottomSheet(),
        ],
      ),
    );
  }
  Widget _buildMapSection() {
    if (_isLocating || _selectedLatLng == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _selectedLatLng!,
        zoom: 16,
      ),
      onMapCreated: (controller) {
        _mapController = controller;
      },
      style: _darkMapStyle,
      markers: _getMarkers(),
      mapType: MapType.normal,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      onCameraMove: (position) {
        _debounceTimer?.cancel();
        if (_mapController != null) {
          _mapController!.getLatLng(
            ScreenCoordinate(
              x: (MediaQuery.of(context).size.width / 2).round(),
              y: (MediaQuery.of(context).size.height / 2).round(),
            ),
          ).then((center) {
            if (mounted) {
              setState(() {
                _selectedLatLng = center;
              });
            }
          });
        }
      },
      onCameraIdle: () async {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
          if (_mapController != null && mounted) {
            final center = await _mapController!.getLatLng(
              ScreenCoordinate(
                x: (MediaQuery.of(context).size.width / 2).round(),
                y: (MediaQuery.of(context).size.height / 2).round(),
              ),
            );
            if (mounted) {
              setState(() {
                _selectedLatLng = center;
              });
              _reverseGeocode(center);
            }
          }
        });
      },
    );
  }
  Widget _buildTopAppBar() {
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
                      color: Colors.black.withValues(alpha: 0.1),
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
              GestureDetector(
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 16),
                          Text(AppLocalizations.of(context).translate('loading')),
                          Text(AppLocalizations.of(context).translate('current_location'), style: TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.w600),),
                        ],
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  await _getCurrentLocation();
                  if (!mounted) return;
                  if (_selectedLatLng != null && _mapController != null) {
                    await _mapController!.animateCamera(
                      CameraUpdate.newLatLng(_selectedLatLng!),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: RydyColors.darkBg,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.my_location, color: RydyColors.textColor),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context).translate('current_location'),
                        style: TextStyle(
                          color: RydyColors.textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildBottomSheet() {
    return SlideTransition(
      position: _slideAnimation,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: RydyColors.darkBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: RydyColors.cardBg.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: RydyColors.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: RydyColors.textColor.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: RydyColors.textColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.place,
                          color: RydyColors.textColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _loadingAddress
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 16,
                                    width: 120,
                                    decoration: BoxDecoration(
                                      color: RydyColors.subText.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 14,
                                    width: 80,
                                    decoration: BoxDecoration(
                                      color: RydyColors.subText.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context).translate('selected_address'),
                                    style: TextStyle(
                                      color: RydyColors.subText,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedAddress ?? AppLocalizations.of(context).translate('no_address_selected'),
                                    style: TextStyle(
                                      color: RydyColors.textColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                      ),
                      if (_selectedAddress != null && _selectedAddress!.isNotEmpty && !_loadingAddress)
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: RydyColors.textColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.copy, size: 18, color: RydyColors.textColor),
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              await Clipboard.setData(ClipboardData(text: _selectedAddress!));
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.white, size: 20),
                                      const SizedBox(width: 8),
                                      Text(AppLocalizations.of(context).translate('address_copied_clipboard')),
                                    ],
                                  ),
                                  backgroundColor: RydyColors.textColor,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _selectedLatLng != null && _selectedAddress != null && !_loadingAddress
                        ? () {
                            Navigator.pop(context, {
                              'latLng': _selectedLatLng,
                              'address': _selectedAddress,
                            });
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedLatLng != null && _selectedAddress != null && !_loadingAddress
                          ? RydyColors.cardBg
                          : RydyColors.darkBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: _selectedLatLng != null && _selectedAddress != null && !_loadingAddress
                              ? RydyColors.textColor
                              : RydyColors.subText,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Confirm Location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _selectedLatLng != null && _selectedAddress != null && !_loadingAddress
                                ? RydyColors.textColor
                                : RydyColors.subText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 
