import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_localizations.dart';
import '../utils/theme_provider.dart';
import 'set_on_map_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
class SavedLocationScreen extends StatefulWidget {
  final String title;
  final String locationType;
  const SavedLocationScreen({Key? key, required this.title, required this.locationType}) : super(key: key);
  @override
  State<SavedLocationScreen> createState() => _SavedLocationScreenState();
}
class _SavedLocationScreenState extends State<SavedLocationScreen> {
  List<Map<String, dynamic>> _savedLocations = [];
  bool _isLoading = true;
  final TextEditingController _addressController = TextEditingController();
  List<dynamic> _predictions = [];
  static const String kGoogleApiKey = 'AIzaSyDaIk1468iXr5IaRhHvYe32tnWgLqyyTg4';
  String _selectedLabel = 'Home';
  String? _editingId;
  String? _customName;
  IconData? _customIcon;
  double? _selectedLat;
  double? _selectedLng;
  final List<String> _labels = ['home', 'work', 'other'];
  final List<IconData> _customIcons = [
    Icons.place,
    Icons.star,
    Icons.coffee,
    Icons.local_dining,
    Icons.shopping_bag,
    Icons.school,
    Icons.sports_soccer,
    Icons.park,
    Icons.local_hospital,
    Icons.local_gas_station,
    Icons.airport_shuttle,
    Icons.hotel,
    Icons.fitness_center,
  ];
  @override
  void initState() {
    super.initState();
    _fetchSavedLocations();
  }
  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }
  Future<void> _fetchSavedLocations() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final locations = await Supabase.instance.client
          .from('saved_locations')
          .select()
          .eq('passenger_uid', user.id);
      setState(() {
        _savedLocations = List<Map<String, dynamic>>.from(locations);
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching saved locations: $e');
      setState(() => _isLoading = false);
    }
  }
  Future<void> _addOrUpdateSavedLocation() async {
    print('Address to save: ${_addressController.text}');
    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('please_enter_address'))),
      );
      return;
    }
    if (_selectedLat == null || _selectedLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('please_select_location'))),
      );
      return;
    }
    if (_selectedLabel == 'Other' && (_customName == null || _customName!.isEmpty || _customIcon == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('please_enter_name_icon'))),
      );
      return;
    }
    try {
      final user = Supabase.instance.client.auth.currentUser;
      print('Current user: ${user?.id}');
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).translate('must_be_logged_in'))),
        );
        return;
      }
      String labelToSave = _selectedLabel == 'other' ? 'custom' : _selectedLabel;
      final data = {
        'passenger_uid': user.id,
        'label': labelToSave,
        'address': _addressController.text,
        'lat': _selectedLat,
        'lng': _selectedLng,
      };
      if (_selectedLabel == 'other') {
        data['custom_name'] = _customName ?? '';
        data['custom_icon'] = _customIcon != null ? _customIcon!.codePoint.toString() : '';
      }
      print('Saving data: $data');
      dynamic response;
      if (_editingId == null) {
        response = await Supabase.instance.client.from('saved_locations').insert(data);
      } else {
        response = await Supabase.instance.client
            .from('saved_locations')
            .update(data)
            .eq('id', _editingId!);
      }
      print('Supabase response: $response');
      _addressController.clear();
      _selectedLabel = 'home';
      _editingId = null;
      _customName = null;
      _customIcon = null;
      _selectedLat = null;
      _selectedLng = null;
      _fetchSavedLocations();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('location_saved'))),
      );
    } catch (e) {
      print('Error saving location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('error_saving_location').replaceAll('{error}', e.toString()))),
      );
    }
  }
  Future<void> _deleteSavedLocation(String id) async {
    try {
      await Supabase.instance.client
          .from('saved_locations')
          .delete()
          .eq('id', id);
      _fetchSavedLocations();
    } catch (e) {
      print('Error deleting saved location: $e');
    }
  }
  void _startEditLocation(Map<String, dynamic> location) {
    setState(() {
      _editingId = location['id'].toString();
      _addressController.text = location['address'] ?? '';
      _selectedLabel = location['label'] ?? 'home';
    });
  }
  void _cancelEdit() {
    setState(() {
      _editingId = null;
      _addressController.clear();
      _selectedLabel = 'home';
    });
  }
  void _onConfirmLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SetOnMapScreen(),
      ),
    );
    if (result != null && result['address'] != null && result['latLng'] != null) {
      setState(() {
        _addressController.text = result['address'];
        _selectedLat = result['latLng'].latitude;
        _selectedLng = result['latLng'].longitude;
      });
    }
  }
  void _getPlacePredictions(String input) async {
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
  Future<void> _onPredictionTap(dynamic prediction) async {
    final placeId = prediction['place_id'];
    final detailsUrl = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=AIzaSyDaIk1468iXr5IaRhHvYe32tnWgLqyyTg4';
    final detailsResponse = await http.get(Uri.parse(detailsUrl));
    final detailsData = json.decode(detailsResponse.body);
    final location = detailsData['result']['geometry']['location'];
    setState(() {
      _addressController.text = prediction['description'];
      _selectedLat = location['lat'];
      _selectedLng = location['lng'];
      _predictions = [];
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RydyColors.darkBg,
      appBar: AppBar(
        backgroundColor: RydyColors.darkBg,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
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
          widget.title,
          style: const TextStyle(
            color: RydyColors.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            color: RydyColors.darkBg,
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: RydyColors.cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                      boxShadow: [
                        BoxShadow(
                          color: RydyColors.textColor.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: RydyColors.cardBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.all(6),
                              child: const Icon(Icons.search, color: RydyColors.textColor, size: 22),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _addressController,
                                decoration: InputDecoration(
                                  hintText: AppLocalizations.of(context).translate('search_location'),
                                  hintStyle: TextStyle(color: RydyColors.textColor),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                                ),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: RydyColors.textColor),
                                onChanged: (value) => _getPlacePredictions(value),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: RydyColors.cardBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.location_on, color: RydyColors.textColor, size: 24),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SetOnMapScreen(),
                                    ),
                                  );
                                  if (result != null && result['address'] != null && result['latLng'] != null) {
                                    setState(() {
                                      _addressController.text = result['address'];
                                      _selectedLat = result['latLng'].latitude;
                                      _selectedLng = result['latLng'].longitude;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        if (_predictions.isNotEmpty)
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Container(
                              decoration: BoxDecoration(
                                color: RydyColors.darkBg,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: ListView.separated(
                                key: ValueKey(_predictions.length),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _predictions.length,
                                separatorBuilder: (_, __) => Divider(height: 1, color: RydyColors.subText.withOpacity(0.10)),
                                itemBuilder: (context, i) {
                                  final prediction = _predictions[i];
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () => _onPredictionTap(prediction),
                                    child: ListTile(
                                      leading: Icon(Icons.location_on, color: RydyColors.textColor, size: 22),
                                      title: Text(
                                        prediction['structured_formatting']?['main_text'] ?? prediction['description'],
                                        style: TextStyle(fontWeight: FontWeight.bold, color: RydyColors.textColor, fontSize: 16),
                                      ),
                                      subtitle: Text(
                                        prediction['structured_formatting']?['secondary_text'] ?? '',
                                        style: TextStyle(color: RydyColors.subText, fontSize: 13),
                                      ),
                                      trailing: Icon(Icons.chevron_right, color: RydyColors.subText.withOpacity(0.18)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      tileColor: RydyColors.darkBg,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        if (_selectedLabel == 'Other') ...[
                          const SizedBox(height: 16),
                          TextField(
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context).translate('place_name'),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) => setState(() => _customName = val),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 48,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _customIcons.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (context, idx) {
                                final icon = _customIcons[idx];
                                return GestureDetector(
                                  onTap: () => setState(() => _customIcon = icon),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _customIcon == icon ? RydyColors.textColor.withOpacity(0.2) : RydyColors.darkBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _customIcon == icon ? RydyColors.textColor : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(icon, color: RydyColors.textColor, size: 28),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _addOrUpdateSavedLocation,
            style: ElevatedButton.styleFrom(
              backgroundColor: RydyColors.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              padding: const EdgeInsets.symmetric(vertical: 18),
              elevation: 0,
            ),
            child: Text(
              AppLocalizations.of(context).translate('confirm_location'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: RydyColors.textColor),
            ),
          ),
        ),
      ),
    );
  }
} 
