import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'passenger_home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/theme_provider.dart';
import '../utils/app_localizations.dart';
class RideRatingScreen extends StatefulWidget {
  final String rideId;
  final String driverId;
  final double price;
  final String fromAddress;
  final String toAddress;
  const RideRatingScreen({
    Key? key,
    required this.rideId,
    required this.driverId,
    required this.price,
    required this.fromAddress,
    required this.toAddress,
  }) : super(key: key);
  @override
  State<RideRatingScreen> createState() => _RideRatingScreenState();
}
class _RideRatingScreenState extends State<RideRatingScreen> {
  double _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  final List<String> _quickFeedbackOptions = [
    'great_service',
    'clean_car',
    'safe_driving',
    'on_time',
    'friendly_driver'
  ];
  final List<String> _selectedFeedback = [];
  String driverName = '...';
  String carDetails = '...';
  String driverAvatar = 'assets/images/driver_avatar.png';
  bool _isLoadingDriverInfo = true;
  @override
  void initState() {
    super.initState();
    _loadDriverInfo();
  }
  Future<void> _loadDriverInfo() async {
    try {
      final driver = await Supabase.instance.client
          .from('driver')
          .select('first_name, last_name, avatar_url, rating, phone_number')
          .eq('id', widget.driverId)
          .maybeSingle();
      if (driver != null) {
        setState(() {
          driverName = '${driver['first_name'] ?? ''} ${driver['last_name'] ?? ''}'.trim();
          if (driverName.isEmpty) {
            driverName = AppLocalizations.of(context).translate('unknown_driver');
          }
          carDetails = AppLocalizations.of(context).translate('professional_driver');
          driverAvatar = driver['avatar_url'] ?? 'assets/images/driver_avatar.png';
          _isLoadingDriverInfo = false;
        });
      } else {
        await _loadDriverFromRide();
      }
    } catch (e) {
      print('Error loading driver info: $e');
      await _loadDriverFromRide();
    }
  }
  Future<void> _loadDriverFromRide() async {
    try {
      final ride = await Supabase.instance.client
          .from('rides')
          .select('driver_uid')
          .eq('id', widget.rideId)
          .maybeSingle();
      if (ride != null && ride['driver_uid'] != null) {
        final driver = await Supabase.instance.client
            .from('driver')
            .select('first_name, last_name, avatar_url, rating')
            .eq('id', ride['driver_uid'])
            .maybeSingle();
        if (driver != null) {
          setState(() {
            driverName = '${driver['first_name'] ?? ''} ${driver['last_name'] ?? ''}'.trim();
            if (driverName.isEmpty) {
              driverName = AppLocalizations.of(context).translate('unknown_driver');
            }
            carDetails = AppLocalizations.of(context).translate('professional_driver');
            driverAvatar = driver['avatar_url'] ?? 'assets/images/driver_avatar.png';
            _isLoadingDriverInfo = false;
          });
        } else {
          _setDefaultDriverInfo();
        }
      } else {
        _setDefaultDriverInfo();
      }
    } catch (e) {
      print('Error loading driver from ride: $e');
      _setDefaultDriverInfo();
    }
  }
  void _setDefaultDriverInfo() {
    setState(() {
      driverName = AppLocalizations.of(context).translate('unknown_driver');
      carDetails = AppLocalizations.of(context).translate('professional_driver');
      driverAvatar = 'assets/images/driver_avatar.png';
      _isLoadingDriverInfo = false;
    });
  }
  Future<void> _updateDriverRating() async {
    try {
      final ratings = await Supabase.instance.client
          .from('rides')
          .select('passenger_rating')
          .eq('driver_uid', widget.driverId)
          .not('passenger_rating', 'is', null);
      if (ratings.isNotEmpty) {
        final totalRating = ratings.fold<double>(0, (sum, ride) => sum + (ride['passenger_rating'] as num).toDouble());
        final averageRating = totalRating / ratings.length;
        await Supabase.instance.client
            .from('driver')
            .update({'rating': averageRating})
            .eq('id', widget.driverId);
      }
    } catch (e) {
      print('Error updating driver rating: $e');
    }
  }
  Future<void> _createRideHistory() async {
    try {
      final ride = await Supabase.instance.client
          .from('rides')
          .select('*')
          .eq('id', widget.rideId)
          .single();
      await Supabase.instance.client
          .from('ride_history')
          .insert({
            'ride_id': widget.rideId,
            'passenger_uid': ride['passenger_uid'],
            'driver_uid': ride['driver_uid'],
            'from_address': ride['from_address'],
            'to_address': ride['to_address'],
            'price': ride['price'],
            'currency': ride['currency'],
            'distance_km': ride['distance_km'],
            'duration_minutes': ride['duration_minutes'],
            'ride_type': ride['ride_type'],
            'payment_method': ride['payment_method'],
            'rating': _rating,
            'feedback': _feedbackController.text,
            'completed_at': ride['completed_at'] ?? DateTime.now().toIso8601String(),
            'created_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      print('Error creating ride history: $e');
    }
  }
  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RydyColors.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: RydyColors.darkBg,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).translate('rate_your_ride'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: RydyColors.textColor,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                  SizedBox(width: 44), 
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 18),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: RydyColors.cardBg,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: RydyColors.textColor, width: 2),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
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
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isLoadingDriverInfo ? 'Loading...' : driverName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: RydyColors.textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          carDetails,
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
            ),
            const SizedBox(height: 28),
            RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              itemSize: 44,
              glow: false,
              unratedColor: RydyColors.cardBg,
              itemBuilder: (context, _) => const Icon(
                Icons.star_rounded,
                color: RydyColors.textColor,
              ),
              onRatingUpdate: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _quickFeedbackOptions.map((option) {
                  final isSelected = _selectedFeedback.contains(option);
                  return FilterChip(
                    label: Text(AppLocalizations.of(context).translate(option)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedFeedback.add(option);
                        } else {
                          _selectedFeedback.remove(option);
                        }
                      });
                    },
                    backgroundColor: RydyColors.cardBg,
                    selectedColor: RydyColors.textColor,
                    checkmarkColor: RydyColors.cardBg,
                    labelStyle: TextStyle(
                      color: isSelected ? RydyColors.darkBg : RydyColors.subText,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: BorderSide.none,
                    selectedShadowColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  );
                }).toList().cast<Widget>(),
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: TextField(
                controller: _feedbackController,
                maxLines: 3,
                style: const TextStyle(color: RydyColors.textColor),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).translate('additional_feedback_optional'),
                  hintStyle: TextStyle(color: RydyColors.subText),
                  filled: true,
                  fillColor: RydyColors.cardBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(18),
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(18),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _rating > 0 ? () async {
                    try {
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
                              Text(AppLocalizations.of(context).translate('submitting_rating')),
                            ],
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      await Supabase.instance.client
                          .from('rides')
                          .update({
                            'passenger_rating': _rating,
                            'passenger_feedback': _feedbackController.text,
                            'rating_submitted_at': DateTime.now().toIso8601String(),
                          })
                          .eq('id', widget.rideId);
                      await _updateDriverRating();
                      await _createRideHistory();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalizations.of(context).translate('rating_submitted_successfully')),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const PassengerHomeScreen()),
                          (route) => false,
                        );
                      }
                    } catch (e) {
                      print('Error submitting rating: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalizations.of(context).translate('error_submitting_rating').replaceAll('{error}', e.toString())),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RydyColors.cardBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    AppLocalizations.of(context).translate('submit_rating'),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: RydyColors.textColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
