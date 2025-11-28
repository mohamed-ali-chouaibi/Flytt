import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart' as poly;
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'ride_selection_screen.dart';
import '../utils/theme_provider.dart';
import '../utils/app_localizations.dart';
import 'package:provider/provider.dart';
import 'set_on_map_screen.dart';
import 'saved_location_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
const String kGoogleApiKey = 'AIzaSyDaIk1468iXr5IaRhHvYe32tnWgLqyyTg4';
class FindRidesScreen extends StatefulWidget {
  final gm.LatLng? initialLocation;
  const FindRidesScreen({Key? key, this.initialLocation}) : super(key: key);
  @override
  State<FindRidesScreen> createState() => _FindRidesScreenState();
}
class _FindRidesScreenState extends State<FindRidesScreen> {
  gm.GoogleMapController? mapController;
  final Set<gm.Marker> _markers = {};
  final List<gm.LatLng> _polylinePoints = [];
  gm.LatLng? _fromLatLng;
  gm.LatLng? _toLatLng;
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  List<dynamic> _predictions = [];
  bool _isSearchingPickup = false;
  bool _isSearchingDestination = false;
  String? _userCountryCode;
  static const gm.CameraPosition _initialPosition = gm.CameraPosition(
    target: gm.LatLng(35.8245, 10.6346),
    zoom: 15.0,
  );
  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _fromLatLng = gm.LatLng(position.latitude, position.longitude);
      _fromController.text = AppLocalizations.of(context).translate('current_location');
      _markers.removeWhere((m) => m.markerId.value == 'from');
      _markers.add(gm.Marker(
        markerId: const gm.MarkerId('from'),
        position: _fromLatLng!,
        infoWindow: const gm.InfoWindow(title: 'From'),
      ));
    });
    mapController?.animateCamera(gm.CameraUpdate.newLatLng(_fromLatLng!));
    if (_fromLatLng != null && _toLatLng != null) {
      _fetchRoutePolyline();
    }
    _tryNavigateToRideSelection(context);
  }
  Future<void> _fetchRoutePolyline() async {
    if (_fromLatLng == null || _toLatLng == null) return;
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${_fromLatLng!.latitude},${_fromLatLng!.longitude}&destination=${_toLatLng!.latitude},${_toLatLng!.longitude}&key=AIzaSyDaIk1468iXr5IaRhHvYe32tnWgLqyyTg4';
    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);
    if (data['routes'] != null && data['routes'].isNotEmpty) {
      final points = data['routes'][0]['overview_polyline']['points'];
      final List<gm.LatLng> polylineCoords = poly.decodePolyline(points)
          .map((e) => gm.LatLng(e[0].toDouble(), e[1].toDouble()))
          .toList();
    setState(() {
        _polylinePoints.clear();
        _polylinePoints.addAll(polylineCoords);
      });
      }
  }
  Future<void> _getPlacePredictions(String input, {bool isPickup = true}) async {
    if (input.isEmpty) {
      setState(() {
        _predictions = [];
      });
      return;
    }
    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=AIzaSyDaIk1468iXr5IaRhHvYe32tnWgLqyyTg4';
    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);
    setState(() {
      _predictions = data['predictions'] ?? [];
    });
  }
  Future<gm.LatLng?> _geocodeAddress(String address) async {
    final url = 'https://maps.googleapis.com/maps/api/geocode/json?address=$address&key=AIzaSyDaIk1468iXr5IaRhHvYe32tnWgLqyyTg4';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['results'] != null && data['results'].isNotEmpty) {
        final loc = data['results'][0]['geometry']['location'];
        return gm.LatLng(loc['lat'], loc['lng']);
      }
    }
    return null;
  }
  void _tryNavigateToRideSelection(BuildContext context) async {
    if (_fromLatLng != null && _toLatLng != null &&
        _fromController.text.isNotEmpty && _toController.text.isNotEmpty) {
      final url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${_fromLatLng!.latitude},${_fromLatLng!.longitude}&destination=${_toLatLng!.latitude},${_toLatLng!.longitude}&key=AIzaSyDaIk1468iXr5IaRhHvYe32tnWgLqyyTg4';
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);
      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final leg = data['routes'][0]['legs'][0];
        final durationMinutes = (leg['duration']['value'] as int? ?? 0) ~/ 60;
        final distanceKm = (leg['distance']['value'] as int? ?? 0) / 1000.0;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RideSelectionScreen(
              fromAddress: _fromController.text,
              toAddress: _toController.text,
              fromLatLng: LatLng(_fromLatLng!.latitude, _fromLatLng!.longitude),
              toLatLng: LatLng(_toLatLng!.latitude, _toLatLng!.longitude),
              durationMinutes: durationMinutes,
              distanceKm: distanceKm,
            ),
          ),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final darkBg = RydyColors.darkBg;
    final cardBg = RydyColors.cardBg;
    final textColor = RydyColors.textColor;
    final subText = RydyColors.subText;
    return Scaffold(
      backgroundColor: darkBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppBar(
              backgroundColor: RydyColors.darkBg,
              foregroundColor: RydyColors.textColor,
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: CircleAvatar(
                  backgroundColor: RydyColors.darkBg,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: RydyColors.textColor),
                    onPressed: () => Navigator.of(context).pop(),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                  ),
                ),
              ),
              title: Text(
                AppLocalizations.of(context).translate('plan_your_ride'),
                style: TextStyle(
                  color: RydyColors.textColor,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
              centerTitle: true,
              toolbarHeight: 60,
              shadowColor: Colors.transparent,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.13),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: cardBg,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Icon(Icons.my_location, color: subText, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _fromController,
                              style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 17),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: AppLocalizations.of(context).translate('my_location'),
                                hintStyle: TextStyle(color: subText, fontWeight: FontWeight.w400, fontSize: 17),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _isSearchingPickup = true;
                                  _isSearchingDestination = false;
                                });
                                _getPlacePredictions(value, isPickup: true);
                              },
                              onTap: () {
                                setState(() {
                                  _isSearchingPickup = true;
                                  _isSearchingDestination = false;
                                });
                                _getPlacePredictions(_fromController.text, isPickup: true);
                              },
                              onEditingComplete: () async {
                                if (_fromController.text.isNotEmpty && _fromLatLng == null) {
                                  final latLng = await _geocodeAddress(_fromController.text);
                                  if (latLng != null) {
                                    setState(() => _fromLatLng = latLng);
                                  }
                                }
                                _tryNavigateToRideSelection(context);
                              },
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add, color: subText, size: 24),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      height: 1,
                      color: subText.withOpacity(0.13),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: cardBg,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Icon(Icons.location_on, color: subText, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _toController,
                              style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 17),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: AppLocalizations.of(context).translate('where_to'),
                                hintStyle: TextStyle(color: subText, fontWeight: FontWeight.w400, fontSize: 17),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _isSearchingPickup = false;
                                  _isSearchingDestination = true;
                                });
                                _getPlacePredictions(value, isPickup: false);
                              },
                              onTap: () {
                                setState(() {
                                  _isSearchingPickup = false;
                                  _isSearchingDestination = true;
                                });
                                _getPlacePredictions(_toController.text, isPickup: false);
                              },
                              onEditingComplete: () async {
                                if (_toController.text.isNotEmpty && _toLatLng == null) {
                                  final latLng = await _geocodeAddress(_toController.text);
                                  if (latLng != null) {
                                    setState(() => _toLatLng = latLng);
                                  }
                                }
                                _tryNavigateToRideSelection(context);
                              },
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.swap_vert, color: subText, size: 24),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                    if (_predictions.isNotEmpty)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: ListView.separated(
                          key: ValueKey(_predictions.length),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _predictions.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: subText.withOpacity(0.10)),
                          itemBuilder: (context, i) {
                            final prediction = _predictions[i];
                            final types = prediction['types'] ?? [];
                            return InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () async {
                                final placeId = prediction['place_id'];
                                final detailsUrl = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=AIzaSyDaIk1468iXr5IaRhHvYe32tnWgLqyyTg4';
                                final detailsResponse = await http.get(Uri.parse(detailsUrl));
                                final detailsData = json.decode(detailsResponse.body);
                                final location = detailsData['result']['geometry']['location'];
                                final latLng = gm.LatLng(location['lat'], location['lng']);
                                setState(() {
                                  if (_isSearchingPickup) {
                                    _fromController.text = prediction['description'];
                                    _fromLatLng = latLng;
                                    _markers.removeWhere((m) => m.markerId.value == 'from');
                                    _markers.add(gm.Marker(
                                      markerId: const gm.MarkerId('from'),
                                      position: latLng,
                                      infoWindow: const gm.InfoWindow(title: 'From'),
                                    ));
                                  } else if (_isSearchingDestination) {
                                    _toController.text = prediction['description'];
                                    _toLatLng = latLng;
                                    _markers.removeWhere((m) => m.markerId.value == 'to');
                                    _markers.add(gm.Marker(
                                      markerId: const gm.MarkerId('to'),
                                      position: latLng,
                                      infoWindow: const gm.InfoWindow(title: 'To'),
                                    ));
                                  }
                                  _predictions = [];
                                });
                                if (_fromLatLng != null && _toLatLng != null) {
                                  _fetchRoutePolyline();
                                }
                                _tryNavigateToRideSelection(context);
                              },
                              child: ListTile(
                                leading: Container(
                                  decoration: BoxDecoration(
                                    color: cardBg.withOpacity(0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(7),
                                  child: Icon(
                                    types.contains('airport')
                                        ? Icons.flight_takeoff_rounded
                                        : types.contains('train_station')
                                            ? Icons.train
                                            : types.contains('transit_station')
                                                ? Icons.directions_transit
                                                : types.contains('bus_station')
                                                    ? Icons.directions_bus
                                                    : types.contains('subway_station')
                                                        ? Icons.subway
                                                        : types.contains('taxi_stand')
                                                            ? Icons.local_taxi
                                                            : types.contains('restaurant')
                                                                ? Icons.restaurant
                                                                : types.contains('cafe')
                                                                    ? Icons.local_cafe
                                                                    : types.contains('hotel')
                                                                        ? Icons.hotel
                                                                        : types.contains('shopping_mall')
                                                                            ? Icons.shopping_bag
                                                                            : types.contains('parking')
                                                                                ? Icons.local_parking
                                                                                : types.contains('school')
                                                                                    ? Icons.school
                                                                                    : types.contains('university')
                                                                                        ? Icons.account_balance
                                                                                        : types.contains('hospital')
                                                                                            ? Icons.local_hospital
                                                                                            : types.contains('atm')
                                                                                                ? Icons.atm
                                                                                                : types.contains('bank')
                                                                                                    ? Icons.account_balance_wallet
                                                                                                    : types.contains('gas_station')
                                                                                                        ? Icons.local_gas_station
                                                                                                        : types.contains('supermarket')
                                                                                                            ? Icons.local_grocery_store
                                                                                                            : types.contains('store')
                                                                                                                ? Icons.store
                                                                                                                : types.contains('museum')
                                                                                                                    ? Icons.museum
                                                                                                                    : types.contains('stadium')
                                                                                                                        ? Icons.stadium
                                                                                                                        : types.contains('church')
                                                                                                                            ? Icons.church
                                                                                                                            : types.contains('mosque')
                                                                                                                                ? Icons.mosque
                                                                                                                                : types.contains('synagogue')
                                                                                                                                    ? Icons.synagogue
                                                                                                                                    : types.contains('embassy')
                                                                                                                                        ? Icons.flag
                                                                                                                                        : types.contains('police')
                                                                                                                                            ? Icons.local_police
                                                                                                                                            : types.contains('fire_station')
                                                                                                                                                ? Icons.local_fire_department
                                                                                                                                                : types.contains('zoo')
                                                                                                                                                    ? Icons.pets
                                                                                                                                                    : types.contains('park')
                                                                                                                                                        ? Icons.park
                                                                                                                                                        : Icons.location_on_rounded,
                                    color: textColor,
                                    size: 22,
                                  ),
                                ),
                                title: Text(
                                  prediction['structured_formatting']?['main_text'] ?? prediction['description'],
                                  style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16),
                                ),
                                subtitle: Text(
                                  prediction['structured_formatting']?['secondary_text'] ?? '',
                                  style: TextStyle(color: subText, fontSize: 13),
                                ),
                                trailing: Icon(Icons.chevron_right, color: subText.withOpacity(0.18)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                tileColor: darkBg, 
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildQuickAction(Icons.star, AppLocalizations.of(context).translate('saved_places'), () async {
                    try {
                      final supabase = Supabase.instance.client;
                      final List data = await supabase
                          .from('saved_locations')
                          .select('label, address, lat, lng')
                          .order('id', ascending: false)
                          .limit(20);
                      print('Saved locations from Supabase: $data');
                      final selected = await showModalBottomSheet<Map<String, dynamic>>(
                        context: context,
                        backgroundColor: RydyColors.cardBg,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        builder: (context) {
                          if (data.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(32),
                              child: Center(
                                child: Text(AppLocalizations.of(context).translate('no_saved_locations'), style: TextStyle(color: RydyColors.subText, fontSize: 18)),
                              ),
                            );
                          }
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                child: Text(AppLocalizations.of(context).translate('select_saved_place'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: RydyColors.textColor)),
                              ),
                              Divider(color: RydyColors.subText.withOpacity(0.13), height: 1, thickness: 1),
                              ...data.map((loc) => ListTile(
                                leading: Icon(getLabelIcon(loc['label'] as String?), color: RydyColors.subText),
                                title: Text((loc['label'] ?? loc['address']) as String, style: TextStyle(color: RydyColors.textColor)),
                                subtitle: loc['label'] != null ? Text(loc['address'] as String, style: TextStyle(color: RydyColors.subText, fontSize: 13)) : null,
                                onTap: () => Navigator.pop(context, loc),
                              )),
                              const SizedBox(height: 12),
                            ],
                          );
                        },
                      );
                      if (selected != null && selected['address'] != null && selected['lat'] != null && selected['lng'] != null) {
                        setState(() {
                          if (!_isSearchingPickup && !_isSearchingDestination) {
                            _fromController.text = selected['address'] as String;
                            _fromLatLng = gm.LatLng((selected['lat'] as num).toDouble(), (selected['lng'] as num).toDouble());
                          } else if (_isSearchingPickup) {
                            _fromController.text = selected['address'] as String;
                            _fromLatLng = gm.LatLng((selected['lat'] as num).toDouble(), (selected['lng'] as num).toDouble());
                          } else {
                            _toController.text = selected['address'] as String;
                            _toLatLng = gm.LatLng((selected['lat'] as num).toDouble(), (selected['lng'] as num).toDouble());
                          }
                        });
                      }
                    } catch (e) {
                      print('Erreur Supabase: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context).translate('error_retrieving_places')), backgroundColor: Colors.red),
                      );
                    }
                  }),
                  _buildQuickAction(Icons.map, AppLocalizations.of(context).translate('set_location_on_map'), () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SetOnMapScreen(
                          initialLocation: _isSearchingPickup ? _fromLatLng : _toLatLng,
                        ),
                      ),
                    );
                    if (result != null && result is Map && result['latLng'] != null && result['address'] != null) {
                      setState(() {
                        if (_isSearchingPickup) {
                          _fromLatLng = result['latLng'];
                          _fromController.text = result['address'];
                        } else {
                          _toLatLng = result['latLng'];
                          _toController.text = result['address'];
                        }
                      });
                    }
                  }),
                  _buildQuickAction(Icons.my_location, AppLocalizations.of(context).translate('current_location'), () async {
                    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                    if (!serviceEnabled) {
                      await Geolocator.openLocationSettings();
                      return;
                    }
                    LocationPermission permission = await Geolocator.checkPermission();
                    if (permission == LocationPermission.denied) {
                      permission = await Geolocator.requestPermission();
                      if (permission == LocationPermission.denied) return;
                    }
                    if (permission == LocationPermission.deniedForever) return;
                    final position = await Geolocator.getCurrentPosition();
                    final lat = position.latitude;
                    final lng = position.longitude;
                    final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=AIzaSyDaIk1468iXr5IaRhHvYe32tnWgLqyyTg4';
                    final response = await http.get(Uri.parse(url));
                    String address = AppLocalizations.of(context).translate('current_location');
                    if (response.statusCode == 200) {
                      final data = json.decode(response.body);
                      if (data['results'] != null && data['results'].isNotEmpty) {
                        address = data['results'][0]['formatted_address'] ?? address;
                      }
                    }
                    setState(() {
                      if (!_isSearchingPickup && !_isSearchingDestination) {
                        _fromLatLng = gm.LatLng(lat, lng);
                        _fromController.text = address;
                      } else if (_isSearchingPickup) {
                        _fromLatLng = gm.LatLng(lat, lng);
                        _fromController.text = address;
                      } else {
                        _toLatLng = gm.LatLng(lat, lng);
                        _toController.text = address;
                      }
                    });
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: kDebugMode ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RideSelectionScreen(
                fromAddress: 'Test Start',
                toAddress: 'Test End',
                fromLatLng: gm.LatLng(35.8245, 10.6346),
                toLatLng: gm.LatLng(35.8250, 10.6400),
                durationMinutes: 12,
                distanceKm: 3.7,
              ),
            ),
          );
        },
        icon: const Icon(Icons.bug_report),
        label: Text(AppLocalizations.of(context).translate('test_ride_selection')),
        backgroundColor: Colors.deepPurple,
      ) : null,
    );
  }
  Widget _buildLuxuryInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onIconTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E7EF), width: 1),
                    ),
      child: GooglePlaceAutoCompleteTextField(
        textEditingController: controller,
                      googleAPIKey: kGoogleApiKey,
                      inputDecoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
            letterSpacing: 0.5,
          ),
          prefixIcon: Icon(icon, color: iconColor),
          suffixIcon: onIconTap != null
              ? IconButton(
                  icon: const Icon(Icons.my_location),
                  color: const Color(0xFF2C3E50),
                  onPressed: onIconTap,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      debounceTime: 400,
        countries: _userCountryCode != null ? [_userCountryCode!.toLowerCase()] : null,
                      isLatLngRequired: true,
                      getPlaceDetailWithLatLng: (place) {
          final latLng = gm.LatLng(
                            double.parse(place.lat!),
                            double.parse(place.lng!),
                          );
          setState(() {
            if (controller == _fromController) {
              _fromLatLng = latLng;
              _markers.removeWhere((m) => m.markerId.value == 'from');
              _markers.add(gm.Marker(
                markerId: const gm.MarkerId('from'),
                position: latLng,
                infoWindow: const gm.InfoWindow(title: 'From'),
              ));
            } else {
              _toLatLng = latLng;
                          _markers.removeWhere((m) => m.markerId.value == 'to');
                          _markers.add(gm.Marker(
                            markerId: const gm.MarkerId('to'),
                position: latLng,
                            infoWindow: const gm.InfoWindow(title: 'To'),
                          ));
            }
                        });
          if (_fromLatLng != null && _toLatLng != null) {
            _fetchRoutePolyline();
          }
                      },
                      itemClick: (prediction) {
          controller.text = prediction.description!;
          controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: prediction.description!.length),
                        );
                      },
                    ),
    );
  }
  Widget _buildLuxuryButton() {
    return Container(
                      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C3E50), Color(0xFF34495E)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
                            borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C3E50).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            if (_fromLatLng != null && _toLatLng != null) {
              final url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${_fromLatLng!.latitude},${_fromLatLng!.longitude}&destination=${_toLatLng!.latitude},${_toLatLng!.longitude}&key=AIzaSyDaIk1468iXr5IaRhHvYe32tnWgLqyyTg4';
              final response = await http.get(Uri.parse(url));
              final data = json.decode(response.body);
              if (data['routes'] != null && data['routes'].isNotEmpty) {
                final leg = data['routes'][0]['legs'][0];
                final durationMinutes = (leg['duration']['value'] as int? ?? 0) ~/ 60;
                final distanceKm = (leg['distance']['value'] as int? ?? 0) / 1000.0;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RideSelectionScreen(
                      fromAddress: _fromController.text,
                      toAddress: _toController.text,
                      fromLatLng: _fromLatLng! as dynamic,
                      toLatLng: _toLatLng! as dynamic,
                      durationMinutes: durationMinutes,
                      distanceKm: distanceKm,
                    ),
                  ),
                );
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context).translate('find_rides'),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat',
                  ),
                ),
                SizedBox(width: 12),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    final cardBg = RydyColors.cardBg;
    final textColor = RydyColors.textColor;
    final subText = RydyColors.subText;
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cardBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: subText, size: 24),
          ),
          title: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w500, fontSize: 17)),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          horizontalTitleGap: 16,
        ),
        Divider(color: subText.withOpacity(0.13), height: 1, thickness: 1, indent: 56),
      ],
    );
  }
}
IconData getLabelIcon(String? label) {
  if (label == null) return Icons.place;
  final l = label.toLowerCase();
  if (l.contains('home')) return Icons.home_rounded;
  if (l.contains('work') || l.contains('office')) return Icons.work_rounded;
  if (l.contains('gym') || l.contains('fitness')) return Icons.fitness_center_rounded;
  if (l.contains('school') || l.contains('university')) return Icons.school_rounded;
  if (l.contains('parent') || l.contains('family')) return Icons.family_restroom_rounded;
  if (l.contains('friend')) return Icons.people_alt_rounded;
  if (l.contains('shop') || l.contains('market')) return Icons.shopping_bag_rounded;
  if (l.contains('airport')) return Icons.flight_takeoff_rounded;
  if (l.contains('hotel')) return Icons.hotel_rounded;
  if (l.contains('park')) return Icons.park_rounded;
  return Icons.place;
} 
