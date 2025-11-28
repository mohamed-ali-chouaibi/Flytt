import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utils/theme_provider.dart';
import '../utils/app_localizations.dart';
import '../utils/surge_pricing_service.dart';
import 'package:provider/provider.dart';
class SurgeManagementScreen extends StatefulWidget {
  const SurgeManagementScreen({Key? key}) : super(key: key);
  @override
  State<SurgeManagementScreen> createState() => _SurgeManagementScreenState();
}
class _SurgeManagementScreenState extends State<SurgeManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryCodeController = TextEditingController();
  final _radiusController = TextEditingController();
  final _eventNameController = TextEditingController();
  final _baseMultiplierController = TextEditingController();
  final _driverBonusController = TextEditingController();
  final _maxMultiplierController = TextEditingController();
  String _selectedEventType = 'demand_high';
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(hours: 2));
  List<SurgeZone> _surgeZones = [];
  List<SurgeEvent> _surgeEvents = [];
  bool _isLoading = true;
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(48.8566, 2.3522); 
  @override
  void initState() {
    super.initState();
    _loadSurgeZones();
    _loadSurgeEvents();
  }
  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _countryCodeController.dispose();
    _radiusController.dispose();
    _eventNameController.dispose();
    _baseMultiplierController.dispose();
    _driverBonusController.dispose();
    _maxMultiplierController.dispose();
    super.dispose();
  }
  Future<void> _loadSurgeZones() async {
    try {
      final zones = await SurgePricingService.getActiveSurgeZones('FR');
      setState(() {
        _surgeZones = zones;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading surge zones: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  Future<void> _loadSurgeEvents() async {
    try {
      final events = await SurgePricingService.getActiveSurgeEvents(
        lat: _selectedLocation.latitude,
        lng: _selectedLocation.longitude,
        countryCode: 'FR',
      );
      setState(() {
        _surgeEvents = events;
      });
    } catch (e) {
      print('Error loading surge events: $e');
    }
  }
  Future<void> _createSurgeZone() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final response = await Supabase.instance.client
          .from('surge_zones')
          .insert({
            'name': _nameController.text,
            'country_code': _countryCodeController.text.toUpperCase(),
            'city': _cityController.text,
            'center_lat': _selectedLocation.latitude,
            'center_lng': _selectedLocation.longitude,
            'radius_meters': int.parse(_radiusController.text),
            'is_active': true,
          })
          .select()
          .single();
      final zoneId = response['id'];
      await Supabase.instance.client
          .from('surge_events')
          .insert({
            'surge_zone_id': zoneId,
            'event_type': _selectedEventType,
            'event_name': _eventNameController.text.isNotEmpty ? _eventNameController.text : null,
            'base_multiplier': double.parse(_baseMultiplierController.text),
            'driver_bonus_per_ride': double.parse(_driverBonusController.text),
            'max_multiplier': double.parse(_maxMultiplierController.text),
            'start_time': _startTime.toIso8601String(),
            'end_time': _endTime.toIso8601String(),
            'is_active': true,
          });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Surge zone created successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _clearForm();
      _loadSurgeZones();
      _loadSurgeEvents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating surge zone: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  void _clearForm() {
    _nameController.clear();
    _cityController.clear();
    _countryCodeController.clear();
    _radiusController.clear();
    _eventNameController.clear();
    _baseMultiplierController.clear();
    _driverBonusController.clear();
    _maxMultiplierController.clear();
    _selectedEventType = 'demand_high';
    _startTime = DateTime.now();
    _endTime = DateTime.now().add(const Duration(hours: 2));
  }
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: RydyColors.darkBg,
      appBar: AppBar(
        title: const Text('Surge Management'),
        backgroundColor: RydyColors.cardBg,
        foregroundColor: RydyColors.textColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: RydyColors.subText.withOpacity(0.2)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _selectedLocation,
                          zoom: 12,
                        ),
                        onMapCreated: (controller) => _mapController = controller,
                        onTap: (latLng) {
                          setState(() {
                            _selectedLocation = latLng;
                          });
                        },
                        markers: {
                          Marker(
                            markerId: const MarkerId('selected_location'),
                            position: _selectedLocation,
                            infoWindow: const InfoWindow(title: 'Selected Location'),
                          ),
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: RydyColors.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: RydyColors.subText.withOpacity(0.2)),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Surge Zone',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: RydyColors.textColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Zone Name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter zone name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _cityController,
                                  decoration: InputDecoration(
                                    labelText: 'City',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter city';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _countryCodeController,
                                  decoration: InputDecoration(
                                    labelText: 'Country Code (e.g., FR)',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter country code';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _radiusController,
                            decoration: InputDecoration(
                              labelText: 'Radius (meters)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter radius';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Event Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: RydyColors.textColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedEventType,
                            decoration: InputDecoration(
                              labelText: 'Event Type',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'demand_high', child: Text('High Demand')),
                              DropdownMenuItem(value: 'weather', child: Text('Weather')),
                              DropdownMenuItem(value: 'event', child: Text('Special Event')),
                              DropdownMenuItem(value: 'traffic', child: Text('Heavy Traffic')),
                              DropdownMenuItem(value: 'night', child: Text('Night Time')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedEventType = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _eventNameController,
                            decoration: InputDecoration(
                              labelText: 'Event Name (optional)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _baseMultiplierController,
                                  decoration: InputDecoration(
                                    labelText: 'Base Multiplier',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter base multiplier';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Please enter a valid number';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _driverBonusController,
                                  decoration: InputDecoration(
                                    labelText: 'Driver Bonus (€)',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter driver bonus';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Please enter a valid number';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _maxMultiplierController,
                            decoration: InputDecoration(
                              labelText: 'Max Multiplier',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter max multiplier';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Event Duration',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: RydyColors.textColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ListTile(
                                  title: Text('Start: ${_startTime.toString().substring(0, 16)}'),
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: _startTime,
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(const Duration(days: 30)),
                                    );
                                    if (date != null) {
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.fromDateTime(_startTime),
                                      );
                                      if (time != null) {
                                        setState(() {
                                          _startTime = DateTime(
                                            date.year,
                                            date.month,
                                            date.day,
                                            time.hour,
                                            time.minute,
                                          );
                                        });
                                      }
                                    }
                                  },
                                ),
                              ),
                              Expanded(
                                child: ListTile(
                                  title: Text('End: ${_endTime.toString().substring(0, 16)}'),
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: _endTime,
                                      firstDate: _startTime,
                                      lastDate: DateTime.now().add(const Duration(days: 30)),
                                    );
                                    if (date != null) {
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.fromDateTime(_endTime),
                                      );
                                      if (time != null) {
                                        setState(() {
                                          _endTime = DateTime(
                                            date.year,
                                            date.month,
                                            date.day,
                                            time.hour,
                                            time.minute,
                                          );
                                        });
                                      }
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _createSurgeZone,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Create Surge Zone',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: RydyColors.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: RydyColors.subText.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active Surge Zones',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: RydyColors.textColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_surgeZones.isEmpty)
                          Text(
                            'No active surge zones',
                            style: TextStyle(color: RydyColors.subText),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _surgeZones.length,
                            itemBuilder: (context, index) {
                              final zone = _surgeZones[index];
                              return ListTile(
                                title: Text(
                                  zone.name,
                                  style: TextStyle(color: RydyColors.textColor),
                                ),
                                subtitle: Text(
                                  '${zone.city}, ${zone.countryCode} • ${zone.radiusMeters}m radius',
                                  style: TextStyle(color: RydyColors.subText),
                                ),
                                trailing: Icon(
                                  Icons.location_on,
                                  color: Colors.orange,
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: RydyColors.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: RydyColors.subText.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active Surge Events',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: RydyColors.textColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_surgeEvents.isEmpty)
                          Text(
                            'No active surge events',
                            style: TextStyle(color: RydyColors.subText),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _surgeEvents.length,
                            itemBuilder: (context, index) {
                              final event = _surgeEvents[index];
                              return ListTile(
                                title: Text(
                                  event.eventName ?? event.eventType,
                                  style: TextStyle(color: RydyColors.textColor),
                                ),
                                subtitle: Text(
                                  '${event.baseMultiplier}x multiplier • €${event.driverBonusPerRide} bonus',
                                  style: TextStyle(color: RydyColors.subText),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    event.eventType,
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 
