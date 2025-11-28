import 'package:flutter/material.dart';
import '../utils/app_localizations.dart';
import 'passenger_history_screen.dart';
import 'passenger_profile_screen.dart';
import 'find_rides_screen.dart';
import 'new_reservation_screen.dart';
import '../settings/support_screen.dart';
import '../settings/about_screen.dart';
import '../settings/personal_info_screen.dart';
import '../settings/subscription_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'payment_screen.dart';
import 'promotions_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import '../utils/theme_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Package/package_delivery_screen.dart';
class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({Key? key}) : super(key: key);
  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}
class _PassengerHomeScreenState extends State<PassengerHomeScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _popularPlaces = [];
  Map<String, dynamic>? _userData;
  @override
  void initState() {
    super.initState();
    _fetchPopularPlaces();
    _fetchUserData();
  }
  Future<void> _fetchUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    dynamic response;
    if (user.id.isNotEmpty) {
      response = await Supabase.instance.client
          .from('passenger')
          .select()
          .eq('uid', user.id)
          .single();
    } else if (user.phone != null && user.phone!.isNotEmpty) {
      response = await Supabase.instance.client
          .from('passenger')
          .select()
          .eq('phone', user.phone!)
          .single();
    } else {
      return;
    }
    setState(() {
      _userData = response;
    });
  }
  Future<void> _fetchPopularPlaces() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final apiKey = 'AIzaSyDaIk1468iXr5IaRhHvYe32tnWgLqyyTg4';
      final geocodeUrl = 'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=${position.latitude},${position.longitude}'
          '&key=$apiKey';
      final geocodeResponse = await http.get(Uri.parse(geocodeUrl));
      String countryCode = '';
      String countryName = '';
      if (geocodeResponse.statusCode == 200) {
        final geocodeData = json.decode(geocodeResponse.body);
        final results = geocodeData['results'] as List;
        for (var result in results) {
          final components = result['address_components'] as List;
          for (var component in components) {
            if (component['types'].contains('country')) {
              countryCode = component['short_name']?.toString() ?? '';
              countryName = component['long_name']?.toString() ?? '';
              break;
            }
          }
          if (countryCode.isNotEmpty) break;
        }
      }
      if (countryCode.isEmpty) {
        throw Exception('Could not determine country');
      }
      final placesUrl = 'https://maps.googleapis.com/maps/api/place/textsearch/json'
          '?query=top rated tourist attractions in $countryName'
          '&type=tourist_attraction'
          '&key=$apiKey';
      final placesResponse = await http.get(Uri.parse(placesUrl));
      if (placesResponse.statusCode == 200) {
        final data = json.decode(placesResponse.body);
        final results = data['results'] as List;
        setState(() {
          _popularPlaces = results.take(3).map((place) {
            final location = place['geometry']?['location'];
            double distance = 0;
            if (location != null) {
              final lat = location['lat'] as num?;
              final lng = location['lng'] as num?;
              if (lat != null && lng != null) {
                distance = Geolocator.distanceBetween(
                  position.latitude,
                  position.longitude,
                  lat.toDouble(),
                  lng.toDouble(),
                );
              }
            }
            String formattedDistance = distance < 1000 
                ? '${distance.round()}m away'
                : '${(distance / 1000).toStringAsFixed(1)}km away';
            Map<String, dynamic> getPlaceDetails(List<dynamic>? types) {
              if (types == null) {
                return {
                  'icon': Icons.place_rounded,
                  'category': AppLocalizations.of(context).translate('attraction'),
                };
              }
              if (types.contains('airport')) {
                return {
                  'icon': Icons.flight_rounded,
                  'category': AppLocalizations.of(context).translate('airport'),
                };
              }
              if (types.contains('shopping_mall')) {
                return {
                  'icon': Icons.shopping_bag_rounded,
                  'category': AppLocalizations.of(context).translate('shopping'),
                };
              }
              if (types.contains('museum')) {
                return {
                  'icon': Icons.museum_rounded,
                  'category': AppLocalizations.of(context).translate('museum'),
                };
              }
              if (types.contains('beach')) {
                return {
                  'icon': Icons.beach_access_rounded,
                  'category': AppLocalizations.of(context).translate('beach'),
                };
              }
              if (types.contains('park')) {
                return {
                  'icon': Icons.park_rounded,
                  'category': AppLocalizations.of(context).translate('park'),
                };
              }
              if (types.contains('church')) {
                return {
                  'icon': Icons.church_rounded,
                  'category': AppLocalizations.of(context).translate('church'),
                };
              }
              if (types.contains('mosque')) {
                return {
                  'icon': Icons.mosque_rounded,
                  'category': AppLocalizations.of(context).translate('mosque'),
                };
              }
              if (types.contains('castle')) {
                return {
                  'icon': Icons.castle_rounded,
                  'category': AppLocalizations.of(context).translate('historic_site'),
                };
              }
              return {
                'icon': Icons.place_rounded,
                'category': AppLocalizations.of(context).translate('attraction'),
              };
            }
            final placeDetails = getPlaceDetails(place['types'] as List<dynamic>?);
            final rating = (place['rating'] as num?)?.toDouble() ?? 0.0;
            final userRatingsTotal = (place['user_ratings_total'] as num?)?.toInt() ?? 0;
            return {
              'name': place['name']?.toString() ?? AppLocalizations.of(context).translate('unknown_place'),
              'description': place['formatted_address']?.toString() ?? AppLocalizations.of(context).translate('popular_destination'),
              'icon': placeDetails['icon'] as IconData,
              'category': placeDetails['category'] as String,
              'distance': formattedDistance,
              'rating': rating,
              'ratingsCount': userRatingsTotal,
            };
          }).toList();
        });
      }
    } catch (e) {
      print('Error fetching popular places: $e');
      setState(() {
        _popularPlaces = [
          {
            'name': AppLocalizations.of(context).translate('tunis_carthage_airport'),
            'description': AppLocalizations.of(context).translate('international_airport'),
            'icon': Icons.flight_rounded,
            'category': AppLocalizations.of(context).translate('airport'),
            'distance': AppLocalizations.of(context).translate('unknown'),
            'rating': 4.5,
            'ratingsCount': 1000,
          },
          {
            'name': AppLocalizations.of(context).translate('tunisia_mall'),
            'description': AppLocalizations.of(context).translate('shopping_center'),
            'icon': Icons.shopping_bag_rounded,
            'category': AppLocalizations.of(context).translate('shopping'),
            'distance': AppLocalizations.of(context).translate('unknown'),
            'rating': 4.3,
            'ratingsCount': 800,
          },
          {
            'name': AppLocalizations.of(context).translate('sidi_bou_said'),
            'description': AppLocalizations.of(context).translate('historic_town'),
            'icon': Icons.landscape_rounded,
            'category': AppLocalizations.of(context).translate('historic_site'),
            'distance': AppLocalizations.of(context).translate('unknown'),
            'rating': 4.7,
            'ratingsCount': 1200,
          },
        ];
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    if (_userData == null) {
      _fetchUserData();
    }
    return Scaffold(
      backgroundColor: RydyColors.darkBg,
      drawer: Drawer(
        backgroundColor: RydyColors.darkBg,
        elevation: 16,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 36, left: 20, right: 20, bottom: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: RydyColors.cardBg,
                    backgroundImage: _userData != null && _userData!['profile_image_url'] != null && (_userData!['profile_image_url'] as String).isNotEmpty
                      ? NetworkImage(_userData!['profile_image_url'])
                      : null,
                    child: (_userData == null || _userData!['profile_image_url'] == null || (_userData!['profile_image_url'] as String).isEmpty)
                      ? Icon(Icons.person, color: RydyColors.subText, size: 36)
                      : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userData != null
                            ? (_userData!['name'] ?? _userData!['full_name'] ?? AppLocalizations.of(context).translate('mr'))
                            : AppLocalizations.of(context).translate('mr'),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: RydyColors.textColor, ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _userData != null && (_userData!['email'] ?? '').toString().isNotEmpty
                            ? _userData!['email']
                            : AppLocalizations.of(context).translate('my_account'),
                          style: TextStyle(
                            color: _userData != null && (_userData!['email'] ?? '').toString().isNotEmpty ? RydyColors.subText : RydyColors.textColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: RydyColors.dividerColor, thickness: 1, height: 0),
            _drawerItem(icon: Icons.person_outline_rounded, label: AppLocalizations.of(context).translate('profile'), onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => PersonalInfoScreen()));
            }),
            _drawerItem(icon: Icons.credit_card_rounded, label: AppLocalizations.of(context).translate('payment'), onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentScreen()));
            }),
            _drawerItem(icon: Icons.local_offer_outlined, label: AppLocalizations.of(context).translate('promotions'), subtitle: AppLocalizations.of(context).translate('enter_promo_code'), onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => PromotionsScreen()));
            }),
            _drawerItem(icon: Icons.star_rounded, label: AppLocalizations.of(context).translate('subscriptions'), subtitle: AppLocalizations.of(context).translate('choose_your_plan_and_save'), onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SubscriptionScreen()));
            }),
            _drawerItem(icon: Icons.calendar_today_rounded, label: AppLocalizations.of(context).translate('my_trips'), onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => PassengerHistoryScreen()));
            }),
            _drawerItem(icon: Icons.settings_outlined, label: AppLocalizations.of(context).translate('settings'), onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => PassengerProfileScreen()));
            }),
            _drawerItem(icon: Icons.help_outline_rounded, label: AppLocalizations.of(context).translate('support'), onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => SupportScreen()));
            }),
            _drawerItem(icon: Icons.info_outline_rounded, label: AppLocalizations.of(context).translate('about'), onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => AboutScreen()));
            }),
            const SizedBox(height: 18),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Builder(
                    builder: (context) => IconButton(
                        icon: const Icon(Icons.menu, color: RydyColors.textColor, size: 28),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        'assets/icon/logo.png',
                        height: 32,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Text(AppLocalizations.of(context).translate('weego'),
                          style: TextStyle(
                          color: RydyColors.textColor,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat',
                        ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: 48), 
                            ],
                          ),
                        ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                          color: RydyColors.cardBg,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.10),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      child: Row(
              children: [
                            const Icon(Icons.search, color: RydyColors.subText, size: 26),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => FindRidesScreen()),
                                );
                              },
                              child: Text(
                                  AppLocalizations.of(context).translate('where_going'),
                                style: TextStyle(
                                    color: RydyColors.subText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                        ),
                      ),
                    ),
                          Container(
                        decoration: BoxDecoration(
                                color: RydyColors.cardBg,
                              borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => NewReservationScreen()),
                                );
                              },
                              child: Row(
                                                                  children: [
                                    Icon(Icons.calendar_today, color: RydyColors.subText, size: 20),
                                  SizedBox(width: 6),
                                    Text(AppLocalizations.of(context).translate('later'), style: TextStyle(color: RydyColors.textColor)),
                                ],
                            ),
                          ),
                        ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    Text(AppLocalizations.of(context).translate('great_to_see_you'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: RydyColors.textColor, )),
                ],
              ),
            ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.3,
                children: [
                          _SuggestionCard(
                          imagePath: 'assets/images/flytt.png',
                      label: AppLocalizations.of(context).translate('rides'),
                      subtitle: AppLocalizations.of(context).translate('lets_get_moving'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => FindRidesScreen()),
                            );
                          },
                        ),
                        _SuggestionCard(
                      imagePath: 'assets/images/calendar.png', 
                      label: AppLocalizations.of(context).translate('schedule'), 
                      subtitle: AppLocalizations.of(context).translate('book_ahead'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => NewReservationScreen()),
                        );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                height: 106,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PackageDeliveryScreen()),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: RydyColors.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 72,
                          height: 72,
                          child: Image.asset(
                            'assets/images/package.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stack) => Icon(Icons.local_shipping, color: RydyColors.subText, size: 28),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Package Delivery',
                                style: TextStyle(
                                  color: RydyColors.textColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 19,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Send items fast',
                                style: TextStyle(
                                  color: RydyColors.subText,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: RydyColors.subText),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Text(AppLocalizations.of(context).translate('popular_places'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: RydyColors.textColor, )),
            ),
              ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                itemCount: _popularPlaces.length,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, i) {
                  final place = _popularPlaces[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Container(
                                        decoration: BoxDecoration(
                        color: RydyColors.cardBg,
                        borderRadius: BorderRadius.circular(18),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                      child: ListTile(
                        leading: Container(
                          decoration: BoxDecoration(
                            color: RydyColors.darkBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Icon(place['icon'], color: RydyColors.textColor, size: 30),
                        ),
                        title: Text(
                          place['name'],
                                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: RydyColors.textColor,
                          ),
                        ),
                        subtitle: Text(
                          place['description'],
                          style: TextStyle(
                            fontSize: 15,
                            color: RydyColors.subText,
                          ),
                        ),
                        onTap: () {},
                      ),
                    ),
                  );
                },
              ),
            ],
            ),
        ),
      ),
    );
  }
  Widget _drawerItem({required IconData icon, required String label, String? subtitle, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: RydyColors.subText, size: 26),
      title: Text(label, style: const TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.w600, fontSize: 17)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: RydyColors.subText, fontSize: 14)) : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      hoverColor: RydyColors.cardBg.withOpacity(0.1),
      splashColor: RydyColors.cardBg.withOpacity(0.1),
      minLeadingWidth: 32,
      selected: false,
      selectedTileColor: Colors.transparent,
      tileColor: Colors.transparent,
    );
  }
}
class _SuggestionCard extends StatelessWidget {
  final String imagePath;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
  const _SuggestionCard({
    required this.imagePath, 
    required this.label, 
    this.subtitle,
    this.onTap
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: RydyColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 56,
                width: 120,
                  child: Image.asset(
                    imagePath,
                  fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                      color: RydyColors.cardBg,
                      child: Icon(Icons.image, color: RydyColors.subText, size: 24),
                      );
                    },
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label, 
                style: TextStyle(
                  color: RydyColors.textColor, 
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: RydyColors.subText,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
