import 'package:flutter/material.dart';
import 'passenger_messages_screen.dart';
import 'passenger_profile_screen.dart';
import 'passenger_reservation_screen.dart';
import 'passenger_home_screen.dart';
import 'ride_details_screen.dart';
import '../utils/theme_provider.dart';
import '../utils/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
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
    return phone.isoCode?.toString() ?? 'TN';
  } catch (_) {
    return 'TN';
  }
}
String getCurrencyFromPhone(String phoneNumber) {
  final countryCode = getCountryCodeFromPhone(phoneNumber);
  return countryToCurrency[countryCode] ?? 'TND';
}
class PassengerHistoryScreen extends StatefulWidget {
  const PassengerHistoryScreen({Key? key}) : super(key: key);
  @override
  State<PassengerHistoryScreen> createState() => _PassengerHistoryScreenState();
}
class _PassengerHistoryScreenState extends State<PassengerHistoryScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Completed', 'Cancelled'];
  List<Map<String, dynamic>> _rides = [];
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _fetchRides();
  }
  Future<void> _fetchRides() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      var query;
      if (_selectedFilter != 'All') {
        query = Supabase.instance.client
          .from('ride_history')
          .select('*, driver:driver_uid(name, surname, profile_image_url)')
          .eq('passenger_uid', user.id)
          .eq('status', _selectedFilter.toLowerCase())
          .order('created_at', ascending: false);
      } else {
        query = Supabase.instance.client
          .from('ride_history')
          .select('*, driver:driver_uid(name, surname, profile_image_url)')
          .eq('passenger_uid', user.id)
          .order('created_at', ascending: false);
      }
      final response = await query;
      setState(() {
        _rides = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching rides: $e');
      setState(() => _isLoading = false);
    }
  }
  List<Map<String, dynamic>> get _filteredRides {
    if (_selectedFilter == 'All') return _rides;
    return _rides.where((ride) => ride['status'] == _selectedFilter.toLowerCase()).toList();
  }
  Widget _buildFilterChip(String filter) {
    final isSelected = _selectedFilter == filter;
    String translatedFilter = filter;
    switch (filter) {
      case 'All':
        translatedFilter = AppLocalizations.of(context).translate('all');
        break;
      case 'Completed':
        translatedFilter = AppLocalizations.of(context).translate('completed');
        break;
      case 'Cancelled':
        translatedFilter = AppLocalizations.of(context).translate('cancelled');
        break;
    }
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = filter);
        _fetchRides();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? RydyColors.darkBg : RydyColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? RydyColors.darkBg : RydyColors.subText.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: RydyColors.darkBg.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Text(
          translatedFilter,
          style: TextStyle(
            color: isSelected ? Colors.white : RydyColors.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 15,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
  Widget _buildModernHistoryCard(Map<String, dynamic> ride) {
    final user = Supabase.instance.client.auth.currentUser;
    final currency = ride['currency'] ?? getCurrencyFromPhone(user?.phone ?? '');
    final isCompleted = ride['status'] == 'completed';
    final isCancelled = ride['status'] == 'cancelled';
    final statusColor = isCompleted ? Colors.greenAccent : (isCancelled ? Colors.redAccent : RydyColors.darkBg);
    final statusIcon = isCompleted ? Icons.check_circle_rounded : (isCancelled ? Icons.cancel_rounded : Icons.access_time_rounded);
    final driver = ride['driver'] as Map<String, dynamic>?;
    final driverName = driver != null ? '${driver['name']} ${driver['surname']}' : AppLocalizations.of(context).translate('unknown_driver');
    final driverImage = driver?['profile_image_url'];
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RideDetailsScreen(ride: {
              ...ride,
              'price': ride['price'] ?? 0,
              'startLocation': ride['startLocation'] ?? '',
              'endLocation': ride['endLocation'] ?? '',
              'date': ride['date'] ?? '',
              'time': ride['time'] ?? '',
              'driverName': (driverName ?? '').toString(),
              'rating': ride['rating'] ?? '',
              'duration': ride['duration'] ?? '',
              'distance': ride['distance'] ?? '',
              'status': ride['status'] ?? '',
            }),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
          border: Border.all(
            color: statusColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 18, color: statusColor),
                        const SizedBox(width: 6),
                        Text(
                          ride['status']?.toString().toUpperCase() ?? AppLocalizations.of(context).translate('n_a'),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                      ),
                      if (ride['ride_type'] != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: RydyColors.textColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _getRideTypeDisplayName(ride['ride_type']),
                            style: TextStyle(
                              color: RydyColors.textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: RydyColors.darkBg,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: RydyColors.darkBg.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${(ride['price'] as num?)?.toStringAsFixed(2) ?? '0.00'} $currency',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: RydyColors.darkBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.radio_button_checked, color: Colors.greenAccent, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            ride['from_address'] ?? AppLocalizations.of(context).translate('n_a'),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: RydyColors.textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      margin: const EdgeInsets.only(left: 15),
                      width: 2,
                      height: 20,
                      color: RydyColors.subText.withOpacity(0.3),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            ride['to_address'] ?? AppLocalizations.of(context).translate('n_a'),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: RydyColors.textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: RydyColors.darkBg,
                    backgroundImage: driverImage != null ? NetworkImage(driverImage) : null,
                    child: driverImage == null
                        ? Icon(Icons.person, color: RydyColors.subText, size: 20)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driverName ?? AppLocalizations.of(context).translate('n_a'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: RydyColors.textColor,
                          ),
                        ),
                        Text(
                          '${_formatDate(ride['created_at'])} • ${_formatTime(ride['created_at'])}',
                          style: TextStyle(
                            fontSize: 13,
                            color: RydyColors.subText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (ride['rating'] != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            ride['rating'].toString() ?? '0',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.day}/${date.month}/${date.year}';
  }
  String _formatTime(String dateStr) {
    final date = DateTime.parse(dateStr);
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: RydyColors.cardBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.history_rounded,
              size: 64,
              color: RydyColors.subText,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context).translate('no_rides_found'),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: RydyColors.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).translate('try_changing_filter'),
            style: TextStyle(
              fontSize: 16,
              color: RydyColors.subText,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  Route createFadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
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
            onPressed: () => Navigator.pushReplacement(
              context,
              createFadeRoute(const PassengerHomeScreen()),
            ),
          ),
        ),
        title: Text(
          AppLocalizations.of(context).translate('my_trips'),
          style: TextStyle(
            color: RydyColors.textColor,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        centerTitle: true,
        toolbarHeight: 60,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: _filters.map((filter) => _buildFilterChip(filter)).toList(),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: RydyColors.darkBg,
                    ),
                  )
                : _filteredRides.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _filteredRides.length,
                        itemBuilder: (context, index) {
                          return _buildModernHistoryCard(_filteredRides[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }
  String _getRideTypeDisplayName(String rideType) {
    switch (rideType.toLowerCase()) {
      case 'weego':
        return 'Weego';
      case 'comfort':
        return 'Comfort';
      case 'taxi':
        return 'Taxi';
      case 'eco':
        return 'Eco';
      case 'woman':
        return 'Woman';
      case 'weegoxl':
        return 'WeegoXL';
      default:
        return rideType;
    }
  }
} 
