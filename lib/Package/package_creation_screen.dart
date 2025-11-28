import 'package:flutter/material.dart';
import '../utils/theme_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'delivery_confirmation_screen.dart';
const String kGoogleApiKey = 'AIzaSyDaIk1468iXr5IaRhHvYe32tnWgLqyyTg4';
class PackageCreationScreen extends StatefulWidget {
  const PackageCreationScreen({Key? key}) : super(key: key);
  @override
  State<PackageCreationScreen> createState() => _PackageCreationScreenState();
}
class _PackageCreationScreenState extends State<PackageCreationScreen> with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> _deliveryAddresses = [];
  final TextEditingController _itemDescriptionController = TextEditingController();
  String _currentLocation = 'Getting your location...';
  bool _isLoadingLocation = true;
  late final AnimationController _screenAnim;
  late final Animation<double> _fadeLoc;
  late final Animation<Offset> _slideLoc;
  late final Animation<double> _fadeAddressesTitle;
  late final Animation<Offset> _slideAddressesTitle;
  late final Animation<double> _fadeDescription;
  late final Animation<Offset> _slideDescription;
  late final Animation<double> _fadeCalc;
  late final Animation<Offset> _slideCalc;
  late final Animation<double> _fadeButton;
  late final Animation<Offset> _slideButton;
  final Map<String, double> _packagePrices = {
    'Small': 11.0,
    'Medium': 13.0,
    'Large': 15.0,
    'X-Large': 18.0,
  };
  double _volumetricWeightKg(num lengthCm, num widthCm, num heightCm) {
    if (lengthCm <= 0 || widthCm <= 0 || heightCm <= 0) return 0;
    return (lengthCm * widthCm * heightCm) / 5000.0;
  }
  String _typeForWeight(double kg) {
    if (kg <= 0) return 'Small';
    if (kg < 2) return 'Small';
    if (kg < 5) return 'Medium';
    if (kg < 10) return 'Large';
    if (kg < 20) return 'X-Large';
    return 'Oversize';
  }
  double _oversizePrice(double kg) {
    if (kg <= 20) return 25.0;
    final double extra = (kg - 20) * 2.0;
    return 25.0 + extra;
  }
  double _priceForDelivery(Map<String, dynamic> delivery) {
    final int qty = (delivery['quantity'] ?? 1) as int;
    final String mode = (delivery['pricingMode'] ?? 'weight') as String;
    if (mode == 'dimensions') {
      final num l = (delivery['lengthCm'] ?? 0) as num;
      final num w = (delivery['widthCm'] ?? 0) as num;
      final num h = (delivery['heightCm'] ?? 0) as num;
      final bool hasDims = l > 0 && w > 0 && h > 0;
      if (!hasDims) return 0.0;
      final double kg = _volumetricWeightKg(l, w, h);
      final String derivedType = _typeForWeight(kg);
      if (derivedType == 'Oversize') return _oversizePrice(kg) * qty;
      final double unit = _packagePrices[derivedType] ?? 11.0;
      return unit * qty;
    } else {
      final double weightKg = ((delivery['weightKg'] ?? 0) as num).toDouble();
      if (weightKg <= 0) {
        final String size = (delivery['packageSize'] ?? 'Small') as String;
        if (size == 'Oversize') return _oversizePrice(20) * qty;
        final double unit = _packagePrices[size] ?? 11.0;
        return unit * qty;
      }
      final String derivedType = _typeForWeight(weightKg);
      if (derivedType == 'Oversize') return _oversizePrice(weightKg) * qty;
      final double unit = _packagePrices[derivedType] ?? 11.0;
      return unit * qty;
    }
  }
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _screenAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
    _fadeLoc = CurvedAnimation(parent: _screenAnim, curve: const Interval(0.0, 0.35, curve: Curves.easeOut));
    _slideLoc = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _screenAnim, curve: const Interval(0.0, 0.35, curve: Curves.easeOut)));
    _fadeAddressesTitle = CurvedAnimation(parent: _screenAnim, curve: const Interval(0.15, 0.45, curve: Curves.easeOut));
    _slideAddressesTitle = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _screenAnim, curve: const Interval(0.15, 0.45, curve: Curves.easeOut)));
    _fadeDescription = CurvedAnimation(parent: _screenAnim, curve: const Interval(0.45, 0.75, curve: Curves.easeOut));
    _slideDescription = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _screenAnim, curve: const Interval(0.45, 0.75, curve: Curves.easeOut)));
    _fadeCalc = CurvedAnimation(parent: _screenAnim, curve: const Interval(0.55, 0.85, curve: Curves.easeOut));
    _slideCalc = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _screenAnim, curve: const Interval(0.55, 0.85, curve: Curves.easeOut)));
    _fadeButton = CurvedAnimation(parent: _screenAnim, curve: const Interval(0.70, 1.0, curve: Curves.easeOut));
    _slideButton = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _screenAnim, curve: const Interval(0.70, 1.0, curve: Curves.easeOut)));
    _screenAnim.forward();
  }
  @override
  void dispose() {
    _screenAnim.dispose();
    _itemDescriptionController.dispose();
    super.dispose();
  }
  double get _totalPrice {
    double total = 0;
    for (var delivery in _deliveryAddresses) {
      total += _priceForDelivery(delivery);
    }
    return total;
  }
  bool get _isFormValid {
    if (_deliveryAddresses.isEmpty) return false;
    for (var delivery in _deliveryAddresses) {
      String address = delivery['address'] as String;
      String packageName = delivery['packageName'] as String;
      if (address.isEmpty || packageName.isEmpty) {
        return false;
      }
    }
    return true;
  }
  int get _totalPackages {
    int total = 0;
    for (var delivery in _deliveryAddresses) {
      total += delivery['quantity'] as int;
    }
    return total;
  }
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentLocation = 'Location services disabled';
          _isLoadingLocation = false;
        });
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentLocation = 'Location permission denied';
            _isLoadingLocation = false;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentLocation = 'Location permission permanently denied';
          _isLoadingLocation = false;
        });
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      String address = await _getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
      setState(() {
        _currentLocation = address;
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _currentLocation = 'Error getting location';
        _isLoadingLocation = false;
      });
    }
  }
  Future<String> _getAddressFromCoordinates(double lat, double lng) async {
    try {
      final apiKey = 'AIzaSyDaIk1468iXr5IaRhHvYe32tnWgLqyyTg4';
      final url = 'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=$lat,$lng'
          '&key=$apiKey';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        if (results.isNotEmpty) {
          final formattedAddress = results[0]['formatted_address'] as String;
          return formattedAddress;
        }
      }
      return 'Unable to get address';
    } catch (e) {
      return 'Error getting address';
    }
  }
  void _addDeliveryAddress() {
    setState(() {
      _deliveryAddresses.add({
        'address': '',
        'packageSize': 'Small',
        'quantity': 1,
        'packageName': '',
        'pricingMode': 'weight', 
        'weightKg': 0.0,
        'lengthCm': 0,
        'widthCm': 0,
        'heightCm': 0,
      });
    });
  }
  void _removeDeliveryAddress(int index) {
    setState(() {
      _deliveryAddresses[index]['isRemoving'] = true;
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _deliveryAddresses.removeAt(index);
        });
      }
    });
  }
  void _updatePackageSize(int index, String packageSize) {
    setState(() {
      _deliveryAddresses[index]['packageSize'] = packageSize;
    });
  }
  void _updateQuantity(int index, int quantity) {
    setState(() {
      _deliveryAddresses[index]['quantity'] = quantity;
    });
  }
  void _updatePackageName(int index, String packageName) {
    setState(() {
      _deliveryAddresses[index]['packageName'] = packageName;
    });
  }
  Future<List<Map<String, dynamic>>> _getPlacePredictions(String input) async {
    if (input.isEmpty) return [];
    try {
      final url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=AIzaSyDaIk1468iXr5IaRhHvYe32tnWgLqyyTg4';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return List<Map<String, dynamic>>.from(data['predictions']);
        }
      }
    } catch (e) {
      print('Error getting place predictions: $e');
    }
    return [];
  }
  Future<Map<String, dynamic>?> _getPlaceDetails(String placeId) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=AIzaSyDaIk1468iXr5IaRhHvYe32tnWgLqyyTg4';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data['result'];
        }
      }
    } catch (e) {
      print('Error getting place details: $e');
    }
    return null;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RydyColors.darkBg,
      appBar: AppBar(
        backgroundColor: RydyColors.darkBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: RydyColors.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Send Packages',
          style: TextStyle(
            color: RydyColors.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeTransition(
                      opacity: _fadeLoc,
                      child: SlideTransition(
                        position: _slideLoc,
                        child: _buildSectionTitle('From: My Location'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeTransition(
                      opacity: _fadeLoc,
                      child: SlideTransition(
                        position: _slideLoc,
                        child: _buildLocationCard(
                      icon: Icons.location_on,
                      title: _isLoadingLocation ? 'Getting location...' : 'Current Location',
                      subtitle: _currentLocation,
                      onTap: () {
                        if (_isLoadingLocation) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Please wait while we get your location'),
                              backgroundColor: RydyColors.cardBg,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } else {
                          _getCurrentLocation();
                        }
                      },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeTransition(
                      opacity: _fadeAddressesTitle,
                      child: SlideTransition(
                        position: _slideAddressesTitle,
                        child: _buildSectionTitle('Delivery Addresses:'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._deliveryAddresses.asMap().entries.map((entry) {
                      int index = entry.key;
                      Map<String, dynamic> delivery = entry.value;
                      bool isRemoving = delivery['isRemoving'] == true;
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: isRemoving ? 1.0 : 0.0, end: isRemoving ? 0.0 : 1.0),
                        duration: Duration(milliseconds: isRemoving ? 300 : 250),
                        curve: isRemoving ? Curves.easeIn : Curves.easeOut,
                        builder: (context, value, child) => Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, isRemoving ? (1 - value) * -20 : (1 - value) * 8),
                            child: Transform.scale(
                              scale: isRemoving ? 0.95 + (value * 0.05) : 1.0,
                              child: child,
                            ),
                          ),
                        ),
                        child: _buildAddressCard(
                        address: delivery['address'] as String,
                        quantity: delivery['quantity'] as int,
                        packageName: delivery['packageName'] as String,
                        deliveryIndex: index,
                        onEdit: () {
                          _editAddress(index);
                        },
                        onRemove: () {
                          _removeDeliveryAddress(index);
                        },
                        onPackageSizeChange: (String size) {
                          _updatePackageSize(index, size);
                        },
                        onQuantityChange: (int quantity) {
                          _updateQuantity(index, quantity);
                        },
                        onPackageNameChange: (String name) {
                          _updatePackageName(index, name);
                        },
                        ),
                      );
                    }).toList(),
                    _buildAddAddressButton(),
                    const SizedBox(height: 24),
                    FadeTransition(
                      opacity: _fadeDescription,
                      child: SlideTransition(
                        position: _slideDescription,
                        child: _buildSectionTitle('Item Description:'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeTransition(opacity: _fadeDescription, child: SlideTransition(position: _slideDescription, child: _buildDescriptionField())),
                    const SizedBox(height: 24),
                    FadeTransition(opacity: _fadeCalc, child: SlideTransition(position: _slideCalc, child: _buildCalculationSection())),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            FadeTransition(
              opacity: _fadeButton,
              child: SlideTransition(
                position: _slideButton,
                child: _buildContinueButton(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: RydyColors.textColor,
      ),
    );
  }
  Widget _buildLocationCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            _isLoadingLocation 
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: RydyColors.textColor,
                    strokeWidth: 2,
                  ),
                )
              : Icon(icon, color: RydyColors.textColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: RydyColors.textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: RydyColors.subText,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              _isLoadingLocation ? 'Loading...' : 'Refresh',
              style: TextStyle(
                color: RydyColors.subText,
                fontSize: 14,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildAddressCard({
    required String address,
    required int quantity,
    required String packageName,
    required int deliveryIndex,
    required VoidCallback onEdit,
    required VoidCallback onRemove,
    required Function(String) onPackageSizeChange,
    required Function(int) onQuantityChange,
    required Function(String) onPackageNameChange,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RydyColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: RydyColors.dividerColor.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: RydyColors.cardBg,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
            color: RydyColors.subText.withOpacity(0.3),
            width: 1,
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: RydyColors.subText, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: onEdit,
                    child: Text(
                      address.isEmpty ? 'Tap to add address' : address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: address.isEmpty ? RydyColors.subText : RydyColors.textColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: RydyColors.subText, size: 18),
                  onPressed: onEdit,
                  tooltip: 'Edit address',
                  splashRadius: 18,
                ),
                IconButton(
                  icon: Icon(Icons.close, color: RydyColors.subText, size: 18),
                  onPressed: onRemove,
                  tooltip: 'Remove',
                  splashRadius: 18,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Package Name',
                style: TextStyle(
                  color: RydyColors.subText,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: RydyColors.cardBg,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
            color: RydyColors.subText.withOpacity(0.3),
            width: 1,
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
                ),
                child: TextFormField(
                  initialValue: packageName,
                  cursorColor: Colors.white,
                  style: TextStyle(
                    color: RydyColors.textColor,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g., Documents for John',
                    hintStyle: TextStyle(
                      color: RydyColors.subText,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: onPackageNameChange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Pricing:', style: TextStyle(color: RydyColors.subText, fontSize: 12)),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text('By weight'),
                selected: (this._deliveryAddresses[deliveryIndex]['pricingMode'] ?? 'weight') == 'weight',
                onSelected: (_) { this.setState(() { this._deliveryAddresses[deliveryIndex]['pricingMode'] = 'weight'; }); },
                selectedColor: RydyColors.cardBg,
                backgroundColor: RydyColors.darkBg,
                labelStyle: TextStyle(color: RydyColors.textColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text('By dimensions'),
                selected: (this._deliveryAddresses[deliveryIndex]['pricingMode'] ?? 'weight') == 'dimensions',
                onSelected: (_) { this.setState(() { this._deliveryAddresses[deliveryIndex]['pricingMode'] = 'dimensions'; }); },
                selectedColor: RydyColors.cardBg,
                backgroundColor: RydyColors.darkBg,
                labelStyle: TextStyle(color: RydyColors.textColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quantity',
                    style: TextStyle(
                      color: RydyColors.subText,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: quantity > 1 ? () => onQuantityChange(quantity - 1) : null,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: quantity > 1 ? RydyColors.cardBg : RydyColors.darkBg,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: quantity > 1 ? RydyColors.subText.withOpacity(0.3) : RydyColors.darkBg,
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.remove,
                            color: quantity > 1 ? RydyColors.textColor : RydyColors.subText,
                            size: 18,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: RydyColors.cardBg,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
            color: RydyColors.subText.withOpacity(0.3),
            width: 1,
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
                        ),
                        child: Text(
                          quantity.toString(),
                          style: TextStyle(
                            color: RydyColors.textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => onQuantityChange(quantity + 1),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: RydyColors.cardBg,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
            color: RydyColors.subText.withOpacity(0.3),
            width: 1,
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
                          ),
                          child: Icon(
                            Icons.add,
                            color: RydyColors.textColor,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if ((this._deliveryAddresses[deliveryIndex]['pricingMode'] ?? 'weight') == 'dimensions') Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dimensions (cm)', style: TextStyle(color: RydyColors.subText, fontSize: 12)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _dimField(label: 'L', value: (this._deliveryAddresses[deliveryIndex]['lengthCm'] ?? 0).toString(), onChanged: (v) {
                    int val = int.tryParse(v) ?? 0; this.setState(() { this._deliveryAddresses[deliveryIndex]['lengthCm'] = val; });
                  }),
                  const SizedBox(width: 8),
                  _dimField(label: 'W', value: (this._deliveryAddresses[deliveryIndex]['widthCm'] ?? 0).toString(), onChanged: (v) {
                    int val = int.tryParse(v) ?? 0; this.setState(() { this._deliveryAddresses[deliveryIndex]['widthCm'] = val; });
                  }),
                  const SizedBox(width: 8),
                  _dimField(label: 'H', value: (this._deliveryAddresses[deliveryIndex]['heightCm'] ?? 0).toString(), onChanged: (v) {
                    int val = int.tryParse(v) ?? 0; this.setState(() { this._deliveryAddresses[deliveryIndex]['heightCm'] = val; });
                  }),
                ],
              ),
              const SizedBox(height: 6),
              Builder(builder: (_) {
                final map = this._deliveryAddresses[deliveryIndex];
                final double kg = _volumetricWeightKg((map['lengthCm'] ?? 0) as num, (map['widthCm'] ?? 0) as num, (map['heightCm'] ?? 0) as num);
                final String auto = _typeForWeight(kg);
                return Text('Est. weight: ${kg.toStringAsFixed(2)} kg • Type: $auto', style: TextStyle(color: RydyColors.subText, fontSize: 12));
              }),
            ],
          ),
          const SizedBox(height: 12),
          if ((this._deliveryAddresses[deliveryIndex]['pricingMode'] ?? 'weight') == 'weight') Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Weight (kg)', style: TextStyle(color: RydyColors.subText, fontSize: 12)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: RydyColors.cardBg,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: RydyColors.subText.withOpacity(0.3),
                    width: 1,
                    style: BorderStyle.solid,
                  ),
                ),
                child: TextFormField(
                  initialValue: (this._deliveryAddresses[deliveryIndex]['weightKg'] ?? 0).toString(),
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: RydyColors.textColor, fontSize: 14),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: '0.0',
                  ),
                  onChanged: (v) {
                    final double val = double.tryParse(v) ?? 0.0;
                    this.setState(() { this._deliveryAddresses[deliveryIndex]['weightKg'] = val; });
                  },
                ),
              ),
              const SizedBox(height: 6),
              Builder(builder: (_) {
                final double weight = ((this._deliveryAddresses[deliveryIndex]['weightKg'] ?? 0) as num).toDouble();
                final String auto = _typeForWeight(weight);
                return Text('Type by weight: $auto', style: TextStyle(color: RydyColors.subText, fontSize: 12));
              }),
            ],
          ),
        ],
      ),
    );
  }
  Widget _dimField({required String label, required String value, required Function(String) onChanged}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: RydyColors.cardBg,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: RydyColors.subText.withOpacity(0.3),
            width: 1,
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(label, style: TextStyle(color: RydyColors.subText, fontSize: 12)),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: value,
                keyboardType: TextInputType.number,
                style: TextStyle(color: RydyColors.textColor, fontSize: 14),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: '0',
                ),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildAddAddressButton() {
    return GestureDetector(
      onTap: _addDeliveryAddress,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: RydyColors.cardBg,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: RydyColors.subText.withOpacity(0.3),
            width: 1,
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.add, color: RydyColors.subText, size: 20),
            const SizedBox(width: 12),
            Text(
              'Add Another Address',
              style: TextStyle(
                color: RydyColors.subText,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildDescriptionField() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: TextField(
        controller: _itemDescriptionController,
        style: TextStyle(
          color: RydyColors.textColor,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: 'Documents, electronics...',
          hintStyle: TextStyle(
            color: RydyColors.subText,
            fontSize: 15,
          ),
          border: InputBorder.none,
        ),
        maxLines: 3,
      ),
    );
  }
  Widget _buildCalculationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live Calculation:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: RydyColors.textColor,
            ),
          ),
          const SizedBox(height: 8),
          ..._deliveryAddresses.map((delivery) {
            String packageSize = (delivery['packageSize'] ?? 'Small') as String;
            int quantity = (delivery['quantity'] ?? 1) as int;
            String packageName = (delivery['packageName'] ?? '') as String;
            double subtotal = _priceForDelivery(delivery);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '"$packageName"',
                    style: TextStyle(
                      color: RydyColors.textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    packageSize == 'Oversize'
                        ? '${quantity}x $packageSize = €${subtotal.toStringAsFixed(2)}'
                        : '${quantity}x $packageSize (€${(_packagePrices[packageSize] ?? 0).toInt()}) = €${subtotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: RydyColors.subText,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 8),
          const Divider(color: RydyColors.dividerColor, height: 1),
          const SizedBox(height: 8),
          Text(
            'Total: ${_totalPackages} packages = €${_totalPrice.toStringAsFixed(2)}',
            style: TextStyle(
              color: RydyColors.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildContinueButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: Container(
          decoration: BoxDecoration(
            color: _isFormValid ? RydyColors.cardBg : RydyColors.darkBg,
            borderRadius: BorderRadius.circular(28),
          ),
          child: ElevatedButton(
            onPressed: _isFormValid ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DeliveryConfirmationScreen(
                    deliveryAddresses: _deliveryAddresses,
                    itemDescription: _itemDescriptionController.text,
                  ),
                ),
              );
            } : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continue',
                  style: TextStyle(
                    color: _isFormValid ? RydyColors.textColor : RydyColors.subText,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '€${_totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: _isFormValid ? RydyColors.textColor : RydyColors.subText,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward, 
                  color: _isFormValid ? RydyColors.textColor : RydyColors.subText, 
                  size: 22
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  void _editAddress(int index) {
    final TextEditingController controller = TextEditingController(text: _deliveryAddresses[index]['address'] as String);
    List<Map<String, dynamic>> predictions = [];
    bool isLoading = false;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                decoration: BoxDecoration(
                  color: RydyColors.cardBg,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: RydyColors.cardBg,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Edit Address',
                          style: TextStyle(
                            color: RydyColors.textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: RydyColors.cardBg,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
            color: RydyColors.subText.withOpacity(0.3),
            width: 1,
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
                            ),
                            child: TextField(
                              controller: controller,
                              cursorColor: Colors.white,
                              style: TextStyle(
                                color: RydyColors.textColor,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Tap to add address...',
                                hintStyle: TextStyle(
                                  color: RydyColors.subText,
                                  fontSize: 16,
                              ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: RydyColors.subText,
                                  size: 20,
                                ),
                              suffixIcon: (controller.text.isNotEmpty)
                                  ? IconButton(
                                      tooltip: 'Clear',
                                      icon: Icon(Icons.clear, color: RydyColors.subText, size: 18),
                                      onPressed: () {
                                        controller.clear();
                                        setState(() => predictions = []);
                                      },
                                    )
                                  : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              onChanged: (value) async {
                                if (value.length > 2) {
                                  setState(() {
                                    isLoading = true;
                                  });
                                  final newPredictions = await _getPlacePredictions(value);
                                  setState(() {
                                    predictions = newPredictions;
                                    isLoading = false;
                                  });
                                } else {
                                  setState(() {
                                    predictions = [];
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (isLoading)
                            Container(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: RydyColors.textColor,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Searching...',
                                    style: TextStyle(
                                      color: RydyColors.subText,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (predictions.isNotEmpty)
                            Container(
                              constraints: BoxConstraints(
                                maxHeight: 250,
                              ),
                              decoration: BoxDecoration(
                                color: RydyColors.cardBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: RydyColors.subText.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: predictions.length,
                                itemBuilder: (context, idx) {
                                  final prediction = predictions[idx];
                                  return Container(
                                    decoration: BoxDecoration(
                                      border: idx < predictions.length - 1
                                          ? Border(
                                              bottom: BorderSide(
                                                color: RydyColors.dividerColor.withOpacity(0.2),
                                                width: 1,
                                              ),
                                            )
                                          : null,
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      leading: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: RydyColors.cardBg,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.location_on,
                                          color: RydyColors.textColor,
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(
                                        prediction['description'] ?? '',
                                        style: TextStyle(
                                          color: RydyColors.textColor,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onTap: () async {
                                        final placeId = prediction['place_id'];
                                        if (placeId != null) {
                                          final details = await _getPlaceDetails(placeId);
                                          if (details != null) {
                                            final formattedAddress = details['formatted_address'] ?? prediction['description'];
                                            controller.text = formattedAddress ?? '';
                                            setState(() { predictions = []; });
                                            this.setState(() {
                                              _deliveryAddresses[index]['address'] = controller.text;
                                            });
                                            Navigator.pop(context);
                                          }
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: RydyColors.darkBg,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: RydyColors.dividerColor,
                                  width: 1,
                                ),
                              ),
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: RydyColors.subText,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: RydyColors.textColor,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _deliveryAddresses[index]['address'] = controller.text;
                                  });
                                  Navigator.pop(context);
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: Text(
                                  'Save',
                                  style: TextStyle(
                                    color: RydyColors.darkBg,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
