import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_localizations.dart';
import '../utils/theme_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../passenger/passenger_home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui';
import 'signup_screen.dart';
class PersonalInfoScreen extends StatefulWidget {
  final SignupData? signupData; 
  const PersonalInfoScreen({Key? key, this.signupData}) : super(key: key);
  @override
  _PersonalInfoScreenState createState() => _PersonalInfoScreenState();
}
class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _phoneController = TextEditingController();
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  String? _pickImageError;
  bool _isLoading = false;
  bool _triedSubmit = false;
  final List<Map<String, dynamic>> countries = [
    {
      'name': 'Tunisia',
      'code': '+216',
      'flag': 'assets/flags/tunisia.png',
      'regex': r'^[2-5,7,9]\d{7}$',
      'maxLength': '8',
    },
    {
      'name': 'France',
      'code': '+33',
      'flag': 'assets/flags/flag.png',
      'regex': r'^\d{9}$',
      'maxLength': '9',
    },
    {
      'name': 'Germany',
      'code': '+49',
      'flag': 'assets/flags/germany.png',
      'regex': r'^\d{10,11}$',
      'maxLength': '11',
    },
    {
      'name': 'Netherlands',
      'code': '+31',
      'flag': 'assets/flags/netherlands.png',
      'regex': r'^\d{9}$',
      'maxLength': '9',
    },
    {
      'name': 'Estonia',
      'code': '+372',
      'flag': 'assets/flags/esthonia.png',
      'regex': r'^\d{7,8}$',
      'maxLength': '8',
    },
    {
      'name': 'Lithuania',
      'code': '+370',
      'flag': 'assets/flags/lithuania.png',
      'regex': r'^\d{8}$',
      'maxLength': '8',
    },
  ];
  int selectedCountryIndex = 0;
  bool isValidPhoneNumber(String phone) {
    final regex = RegExp(countries[selectedCountryIndex]['regex']!);
    return regex.hasMatch(phone);
  }
  bool get isFormValid {
    return _nameController.text.isNotEmpty &&
           _surnameController.text.isNotEmpty &&
           _phoneController.text.isNotEmpty &&
           isValidPhoneNumber(_phoneController.text) &&
           _profileImage != null;
  }
  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _pickImageError = null;
      });
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 50,
      );
      if (image != null) {
        final file = File(image.path);
        if (await file.exists()) {
          setState(() {
            _profileImage = file;
          });
        } else {
          setState(() {
            _pickImageError = 'Failed to load image';
          });
        }
      }
    } catch (e) {
      setState(() {
        _pickImageError = 'Error: ${e.toString()}';
      });
    }
  }
  Future<void> _submitPersonalInfo() async {
    setState(() => _triedSubmit = true);
    if (!_formKey.currentState!.validate() || _profileImage == null) return;
    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;
    try {
      if (widget.signupData != null) {
        print('DEBUG: Creating new account with email: ${widget.signupData!.email}');
        final signUpResponse = await supabase.auth.signUp(
          email: widget.signupData!.email,
          password: widget.signupData!.password,
          emailRedirectTo: null, 
        );
        if (signUpResponse.user == null) {
          throw Exception('Failed to create account');
        }
        print('DEBUG: Account created successfully. User ID: ${signUpResponse.user!.id}');
      }
      final user = supabase.auth.currentUser;
      print('DEBUG: User ID: ${user?.id}');
      print('DEBUG: User Email: ${user?.email}');
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: User not authenticated. Please sign in again.')),
        );
        setState(() => _isLoading = false);
        return;
      }
      String? imageUrl;
      if (_profileImage != null) {
        final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final fileBytes = await _profileImage!.readAsBytes();
        final storageResponse = await supabase.storage
            .from('profile-images')
            .uploadBinary(fileName, fileBytes, fileOptions: FileOptions(contentType: 'image/jpeg'));
        if (storageResponse.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).translate('failed_upload_image'))),
          );
          setState(() => _isLoading = false);
          return;
        }
        imageUrl = supabase.storage.from('profile-images').getPublicUrl(fileName);
      }
      final phoneNumber = countries[selectedCountryIndex]['code']! + _phoneController.text;
      final insertData = {
        'uid': user.id,
        'name': _nameController.text,
        'surname': _surnameController.text,
        'email': user.email,
        'phone': phoneNumber,
        'profile_image_url': imageUrl,
      };
      print('DEBUG: Attempting to insert data: $insertData');
      final response = await supabase.from('passenger').insert(insertData);
      print('DEBUG: Insert successful!');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('profile_saved'))),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PassengerHomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('failed_save_profile') + ': ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
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
              onPressed: () => Navigator.pop(context),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
            ),
          ),
        ),
        toolbarHeight: 56,
        title: Text(
          localizations.translate('personal_info'),
          style: const TextStyle(
            color: RydyColors.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: RydyColors.cardBg.withOpacity(0.7),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: RydyColors.textColor.withOpacity(0.18),
                              width: 2.2,
                            ),
                            image: _profileImage != null
                                ? DecorationImage(
                                    image: FileImage(_profileImage!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _profileImage == null
                              ? Icon(Icons.person, size: 60, color: RydyColors.textColor.withOpacity(0.25))
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: _showImageSourceSheet,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: RydyColors.cardBg,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.camera_alt, color: RydyColors.textColor, size: 22),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_pickImageError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _pickImageError!,
                      style: TextStyle(
                        color: RydyColors.textColor,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (_profileImage == null && _triedSubmit)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      localizations.translate('profile_photo_required'),
                      style: TextStyle(
                        color: RydyColors.textColor,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 32),
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: RydyColors.cardBg.withOpacity(0.85),
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
                          _buildInputField(
                            title: localizations.translate('name'),
                            controller: _nameController,
                            icon: Icons.person_outline_rounded,
                            hint: localizations.translate('enter_name'),
                          ),
                          const SizedBox(height: 18),
                          _buildInputField(
                            title: localizations.translate('surname'),
                            controller: _surnameController,
                            icon: Icons.person_outline_rounded,
                            hint: localizations.translate('enter_surname'),
                          ),
                          const SizedBox(height: 18),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 4, bottom: 8),
                                child: Text(
                                  localizations.translate('phone_number'),
                                  style: TextStyle(
                                    color: RydyColors.textColor.withOpacity(0.7),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: RydyColors.cardBg.withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () async {
                                        final int? selected = await showModalBottomSheet<int>(
                                          context: context,
                                          backgroundColor: RydyColors.cardBg,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                          ),
                                          builder: (context) {
                                            return ListView.separated(
                                              shrinkWrap: true,
                                              itemCount: countries.length,
                                              separatorBuilder: (_, __) => const Divider(height: 1, color: RydyColors.darkBg),
                                              itemBuilder: (context, index) {
                                                return ListTile(
                                                  leading: Image.asset(
                                                    countries[index]['flag']!,
                                                    width: 32,
                                                    height: 32,
                                                    fit: BoxFit.contain,
                                                  ),
                                                  title: Text(
                                                    '${countries[index]['name']} (${countries[index]['code']})',
                                                    style: const TextStyle(color: RydyColors.textColor),
                                                  ),
                                                  onTap: () => Navigator.pop(context, index),
                                                );
                                              },
                                            );
                                          },
                                        );
                                        if (selected != null) {
                                          setState(() {
                                            selectedCountryIndex = selected;
                                            _phoneController.clear();
                                          });
                                        }
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 18),
                                        child: Row(
                                          children: [
                                            Image.asset(
                                              countries[selectedCountryIndex]['flag']!,
                                              width: 28,
                                              height: 28,
                                              fit: BoxFit.contain,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              countries[selectedCountryIndex]['code']!,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: RydyColors.textColor,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(Icons.arrow_drop_down, color: RydyColors.subText, size: 20),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 32,
                                      color: RydyColors.subText.withOpacity(0.3),
                                    ),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _phoneController,
                                        keyboardType: TextInputType.number,
                                        maxLength: int.parse(countries[selectedCountryIndex]['maxLength']!),
                                        onChanged: (value) => setState(() {}),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: RydyColors.textColor,
                                          letterSpacing: 0.5,
                                        ),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                        ],
                                        decoration: InputDecoration(
                                          hintText: localizations.translate('mobile_number'),
                                          hintStyle: TextStyle(color: RydyColors.subText.withOpacity(0.7), fontSize: 16),
                                          border: InputBorder.none,
                                          counterText: '',
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return localizations.translate('please_enter_phone');
                                          }
                                          final maxLen = int.parse(countries[selectedCountryIndex]['maxLength']!);
                                          if (value.length != maxLen) {
                                            return localizations.translate('phone_must_be_digits').replaceAll('{digits}', maxLen.toString());
                                          }
                                          if (!isValidPhoneNumber(value)) {
                                            return localizations.translate('invalid_phone');
                                          }
                                          return null;
                                        },
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
                  ),
                ),
                const SizedBox(height: 28),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: isFormValid ? RydyColors.cardBg : RydyColors.cardBg.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: ElevatedButton(
                      onPressed: (isFormValid && !_isLoading) ? _submitPersonalInfo : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        disabledBackgroundColor: Colors.transparent,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                        localizations.translate('continue'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isFormValid ? RydyColors.textColor : RydyColors.textColor.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildInputField({
    required String title,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    bool showError = false,
    String? errorText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: RydyColors.textColor, fontSize: 16),
        decoration: InputDecoration(
          labelText: title,
          labelStyle: TextStyle(color: RydyColors.textColor.withOpacity(0.7)),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          hintText: hint,
          hintStyle: TextStyle(color: RydyColors.subText.withOpacity(0.7)),
          prefixIcon: Icon(icon, color: RydyColors.textColor.withOpacity(0.7), size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: RydyColors.cardBg.withOpacity(0.95),
          errorText: showError ? errorText : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.18), width: 1.5),
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }
  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: RydyColors.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: RydyColors.subText,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: RydyColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.camera_alt, color: RydyColors.textColor),
              ),
              title: Text(AppLocalizations.of(context).translate('take_photo')),
              subtitle: Text(AppLocalizations.of(context).translate('use_camera'), style: const TextStyle(color: RydyColors.subText)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: RydyColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.photo_library, color: RydyColors.textColor),
              ),
              title: Text(AppLocalizations.of(context).translate('choose_from_gallery')),
              subtitle: Text(AppLocalizations.of(context).translate('select_photo'), style: const TextStyle(color: RydyColors.subText)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
} 
