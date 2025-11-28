import 'package:flutter/material.dart';
import '../utils/theme_provider.dart';
import '../utils/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
class SafetyScreen extends StatefulWidget {
  const SafetyScreen({Key? key}) : super(key: key);
  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}
class _SafetyScreenState extends State<SafetyScreen> {
  bool _safetyCheckIns = false;
  bool _shareTripStatus = false;
  String _selectedSchedule = 'all_rides'; 
  Set<String> _selectedRideTypes = {}; 
  @override
  void initState() {
    super.initState();
    _loadSafetyPreferences();
  }
  Future<void> _loadSafetyPreferences() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('passenger')
            .select('safety_check_ins, share_trip_status, safety_schedule, selected_ride_types')
            .eq('id', user.id)
            .single();
        setState(() {
          _safetyCheckIns = response['safety_check_ins'] ?? false;
          _shareTripStatus = response['share_trip_status'] ?? false;
          _selectedSchedule = response['safety_schedule'] ?? 'all_rides';
          _selectedRideTypes = Set<String>.from(response['selected_ride_types'] ?? []);
        });
      }
    } catch (e) {
      print('Error loading safety preferences: $e');
    }
  }
  Future<void> _updateSafetyPreference(String field, dynamic value) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('passenger')
            .update({field: value})
            .eq('id', user.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('safety_preference_updated')),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error updating safety preference: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('error_updating_preference')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  Future<void> _updateSelectedRideTypes() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('passenger')
            .update({'selected_ride_types': _selectedRideTypes.toList()})
            .eq('id', user.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('safety_preference_updated')),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error updating selected ride types: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('error_updating_preference')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RydyColors.darkBg,
      appBar: AppBar(
        backgroundColor: RydyColors.darkBg,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: RydyColors.darkBg,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: RydyColors.textColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          AppLocalizations.of(context).translate('safety_features'),
          style: TextStyle(
            color: RydyColors.textColor,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        centerTitle: true,
        toolbarHeight: 60,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: RydyColors.cardBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                                         Container(
                       width: 50,
                       height: 50,
                       decoration: BoxDecoration(
                         color: RydyColors.textColor.withOpacity(0.1),
                         borderRadius: BorderRadius.circular(15),
                       ),
                       child: Icon(
                         Icons.security,
                         color: RydyColors.textColor,
                         size: 28,
                       ),
                     ),
                    const SizedBox(width: 16),
                    Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                          Text(
                            AppLocalizations.of(context).translate('safety_features'),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: RydyColors.textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context).translate('preferences_turn_on'),
                style: TextStyle(
                              fontSize: 14,
                  color: RydyColors.subText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
                ),
              ),
          const SizedBox(height: 24),
              _buildSafetyFeature(
                icon: Icons.directions_car,
                title: AppLocalizations.of(context).translate('get_safety_checkins'),
                description: AppLocalizations.of(context).translate('safety_checkins_desc'),
                value: _safetyCheckIns,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _safetyCheckIns = value;
                    });
                    _updateSafetyPreference('safety_check_ins', value);
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildSafetyFeature(
                icon: Icons.share_location,
                title: AppLocalizations.of(context).translate('share_trip_status'),
                description: AppLocalizations.of(context).translate('share_trip_desc'),
                value: _shareTripStatus,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _shareTripStatus = value;
                    });
                    _updateSafetyPreference('share_trip_status', value);
                  }
                },
              ),
              const SizedBox(height: 24),
              _buildSection(
                AppLocalizations.of(context).translate('schedule'),
                'This is how and when your preferences will turn on.',
              ),
              _buildScheduleOption(
                icon: Icons.directions_car,
                title: 'All rides',
                subtitle: 'On during every ride',
                value: 'all_rides',
                hasArrow: false,
              ),
              const SizedBox(height: 12),
              _buildScheduleOption(
                icon: Icons.tune,
                title: 'Some rides',
                subtitle: _selectedRideTypes.isEmpty 
                    ? 'Choose ride types' 
                    : '${_selectedRideTypes.length} ride type${_selectedRideTypes.length == 1 ? '' : 's'} selected',
                value: 'some_rides',
                hasArrow: true,
                onTap: () => _showRideTypeSelection(),
              ),
              const SizedBox(height: 12),
              _buildScheduleOption(
                icon: Icons.block,
                title: 'No rides',
                subtitle: 'Only turn on manually',
                value: 'no_rides',
                hasArrow: false,
              ),
              const SizedBox(height: 32),
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
                child: SizedBox(
                  height: 52,
                child: ElevatedButton(
                  onPressed: () {
                      Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: RydyColors.cardBg,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                    AppLocalizations.of(context).translate('done'),
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: RydyColors.textColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
      ),
    );
  }
  Widget _buildSafetyFeature({
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RydyColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
        ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: RydyColors.textColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: RydyColors.textColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: RydyColors.textColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.info_outline,
                      color: RydyColors.subText,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: RydyColors.subText,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
             value: value,
             onChanged: (newValue) {
                 onChanged(newValue);
             },
             activeColor: RydyColors.textColor,
            activeTrackColor: RydyColors.textColor.withOpacity(0.3),
            inactiveThumbColor: RydyColors.subText,
            inactiveTrackColor: RydyColors.subText.withOpacity(0.2),
           ),
        ],
      ),
    );
  }
  Widget _buildScheduleOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required bool hasArrow,
    VoidCallback? onTap,
  }) {
    final isSelected = _selectedSchedule == value;
    return GestureDetector(
      onTap: onTap ?? () {
        setState(() {
          _selectedSchedule = value;
        });
        _updateSafetyPreference('safety_schedule', value);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: RydyColors.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? RydyColors.textColor : RydyColors.subText.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected ? RydyColors.textColor.withOpacity(0.1) : RydyColors.subText.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: isSelected ? RydyColors.textColor : RydyColors.textColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: RydyColors.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: RydyColors.subText,
                    ),
                  ),
                ],
              ),
            ),
            if (hasArrow)
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: RydyColors.subText,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
  void _showRideTypeSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildRideTypeSelectionModal(),
    );
  }
  Widget _buildRideTypeSelectionModal() {
    final rideTypes = [
      {'id': 'flytt', 'name': 'Flytt', 'icon': Icons.directions_car},
      {'id': 'comfort', 'name': 'Comfort', 'icon': Icons.directions_car},
      {'id': 'taxi', 'name': 'Taxi', 'icon': Icons.local_taxi},
      {'id': 'eco', 'name': 'Eco', 'icon': Icons.eco},
      {'id': 'woman', 'name': 'Woman', 'icon': Icons.person},
      {'id': 'weegoxl', 'name': 'WeegoXL', 'icon': Icons.airport_shuttle},
      {'id': 'scooter', 'name': 'Scooter', 'icon': Icons.motorcycle},
      {'id': 'bike', 'name': 'Bike', 'icon': Icons.pedal_bike},
    ];
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: RydyColors.darkBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: RydyColors.subText.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Text(
                  'Choose Ride Types',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: RydyColors.textColor,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedRideTypes.clear();
                    });
                    _updateSelectedRideTypes();
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Clear All',
                    style: TextStyle(
                      color: RydyColors.subText,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: rideTypes.length,
              itemBuilder: (context, index) {
                final rideType = rideTypes[index];
                final isSelected = _selectedRideTypes.contains(rideType['id']);
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedRideTypes.remove(rideType['id'] as String);
                        } else {
                          _selectedRideTypes.add(rideType['id'] as String);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: RydyColors.cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? RydyColors.textColor : RydyColors.subText.withOpacity(0.2),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isSelected ? RydyColors.textColor.withOpacity(0.1) : RydyColors.subText.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              rideType['icon'] as IconData,
                              color: RydyColors.textColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              rideType['name'] as String,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: RydyColors.textColor,
                              ),
                            ),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isSelected ? RydyColors.textColor : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? RydyColors.textColor : RydyColors.subText.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
                                    color: RydyColors.darkBg,
                                    size: 16,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  _updateSelectedRideTypes();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: RydyColors.cardBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: RydyColors.textColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSection(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: RydyColors.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: RydyColors.textColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: RydyColors.subText,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
} 
