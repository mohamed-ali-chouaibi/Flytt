import 'package:flutter/material.dart';
import '../utils/theme_provider.dart';
import '../utils/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import '../utils/shared_preferences_util.dart';
import '../main.dart';
class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({Key? key}) : super(key: key);
  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}
class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  int _selectedTab = 0;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  int selectedCountryIndex = 0;
  final List<Map<String, dynamic>> countries = [
    {
      'name': 'Tunisia',
      'code': '+216',
      'flag': 'assets/flags/tunisia.png',
      'regex': r'^[2-5,7,9]\d{7}',
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
  final List<Map<String, dynamic>> supportedLanguages = [
    {
      'name': 'Français',
      'code': 'fr',
      'flag': 'assets/flags/flag.png',
      'country': 'France',
    },
    {
      'name': 'English',
      'code': 'en',
      'flag': 'assets/flags/flag.png',
      'country': 'United States',
    },
    {
      'name': 'العربية',
      'code': 'ar',
      'flag': 'assets/flags/tunisia.png',
      'country': 'Tunisia',
    },
    {
      'name': 'Deutsch',
      'code': 'de',
      'flag': 'assets/flags/germany.png',
      'country': 'Germany',
    },
    {
      'name': 'Eesti',
      'code': 'et',
      'flag': 'assets/flags/esthonia.png',
      'country': 'Estonia',
    },
    {
      'name': 'Lietuvių',
      'code': 'lt',
      'flag': 'assets/flags/lithuania.png',
      'country': 'Lithuania',
    },
  ];
  bool isValidPhoneNumber(String phone) {
    final regex = RegExp(countries[selectedCountryIndex]['regex']!);
    return regex.hasMatch(phone);
  }
  void _showPersonalInfoSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: RydyColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      isScrollControlled: true,
      builder: (context) {
        final name = (_userData?['name'] ?? '').toString();
        final surname = (_userData?['surname'] ?? '').toString();
        final email = (_userData?['email'] ?? '').toString();
        final phone = (_userData?['phone'] ?? '').toString();
        final profileImageUrl = (_userData?['profile_image_url'] ?? '').toString();
        return Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.center,
                child: Text(
                  AppLocalizations.of(context).translate('personal_info'),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    letterSpacing: -1,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: _pickAndUploadProfileImage,
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.white24,
                  backgroundImage: (profileImageUrl.isNotEmpty)
                      ? NetworkImage(profileImageUrl)
                      : null,
                  child: (profileImageUrl.isEmpty)
                      ? Icon(Icons.person, color: Colors.white, size: 54)
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              _InfoRow(
                label: AppLocalizations.of(context).translate('name'),
                value: (name + (surname.isNotEmpty ? ' $surname' : '')).trim(),
                icon: Icons.chevron_right,
                onTap: () => _showEditNameSheet(context),
              ),
              const SizedBox(height: 18),
              _InfoRow(
                label: AppLocalizations.of(context).translate('phone_number'),
                value: phone,
                icon: Icons.chevron_right,
                trailing: Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                onTap: () => _showEditPhoneSheet(context),
              ),
              const SizedBox(height: 18),
              _InfoRow(
                label: AppLocalizations.of(context).translate('email'),
                value: email,
                icon: Icons.chevron_right,
                trailing: Icon(Icons.check_circle, color: Colors.green, size: 20),
                onTap: () => _showEditEmailSheet(context),
              ),
              const SizedBox(height: 18),
              _InfoRow(
                label: AppLocalizations.of(context).translate('language'),
                value: AppLocalizations.of(context).translate('update_device_language'),
                icon: Icons.open_in_new,
                onTap: () => _showLanguageSelectionSheet(context),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
  @override
  void initState() {
    super.initState();
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
      _isLoading = false;
    });
  }
  @override
  Widget build(BuildContext context) {
    final String? savedLanguageCode = SharedPreferencesUtil.getStringSync('languageCode');
    int selectedLanguageIndex = 0;
    for (int i = 0; i < supportedLanguages.length; i++) {
      if (supportedLanguages[i]['code'] == savedLanguageCode) {
        selectedLanguageIndex = i;
        break;
      }
    }
    return Scaffold(
      backgroundColor: RydyColors.darkBg,
      appBar: AppBar(
        backgroundColor: RydyColors.darkBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: RydyColors.textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(AppLocalizations.of(context).translate('account'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
                  const SizedBox(height: 18),
                CircleAvatar(
                  radius: 48,
                    backgroundColor: Colors.white24,
                    child: const Icon(Icons.person, color: Colors.white, size: 54),
                ),
                const SizedBox(height: 18),
                Text(
                    ((_userData?['name'] ?? '') + ' ' + (_userData?['surname'] ?? '')).trim(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 26),
                ),
                const SizedBox(height: 6),
                Text(
                    _userData?['email'] ?? '',
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w500, fontSize: 15),
          ),
          const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                      _QuickAccessCard(
                    icon: Icons.person_outline, 
                        label: AppLocalizations.of(context).translate('personal_info'),
                        onTap: () => _showPersonalInfoSheet(context),
                      ),
                      _QuickAccessCard(icon: Icons.verified_user, label: AppLocalizations.of(context).translate('security')),
                      _QuickAccessCard(icon: Icons.lock_outline, label: AppLocalizations.of(context).translate('privacy_data')),
                    ],
            ),
          const SizedBox(height: 32),
                  Align(
              alignment: Alignment.centerLeft,
                    child: Text(AppLocalizations.of(context).translate('suggestions'), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          const SizedBox(height: 12),
                  Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: RydyColors.cardBg,
                borderRadius: BorderRadius.circular(22),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context).translate('complete_account_checkup'),
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                                color: Colors.white12,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(6),
                              child: const Icon(Icons.badge, color: Colors.white, size: 28),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppLocalizations.of(context).translate('complete_account_checkup_desc'),
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 160,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white12,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                            child: Text(
                        AppLocalizations.of(context).translate('begin_checkup'),
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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
  }
  Future<void> _pickAndUploadProfileImage() async {
    _showImageSourceSheet();
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
              subtitle: Text(AppLocalizations.of(context).translate('use_camera'), style: TextStyle(color: RydyColors.subText)),
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
              subtitle: Text(AppLocalizations.of(context).translate('select_photo'), style: TextStyle(color: RydyColors.subText)),
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
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile == null) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final file = File(pickedFile.path);
    final String fileName = 'profile_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await Supabase.instance.client.storage
        .from('profile-images')
        .upload(fileName, file);
    final String imageUrl = Supabase.instance.client.storage
        .from('profile-images')
        .getPublicUrl(fileName);
    await Supabase.instance.client
        .from('passenger')
        .update({'profile_image_url': imageUrl})
        .eq('uid', user.id);
    await _fetchUserData();
    if (Navigator.of(context).mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('profile_picture_updated')), backgroundColor: Colors.green),
      );
    }
  }
  Future<void> _showEditNameSheet(BuildContext context) async {
    final nameController = TextEditingController(text: (_userData?['name'] ?? '').toString());
    final surnameController = TextEditingController(text: (_userData?['surname'] ?? '').toString());
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: RydyColors.cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
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
                Text(
                AppLocalizations.of(context).translate('modify_name'),
                  style: TextStyle(
                    color: RydyColors.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                controller: nameController,
                  autofocus: true,
                  style: TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.w600, fontSize: 18),
                  cursorColor: RydyColors.textColor,
                  decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).translate('first_name'),
                    labelStyle: TextStyle(color: RydyColors.subText, fontWeight: FontWeight.w500),
                    filled: true,
                    fillColor: RydyColors.darkBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: RydyColors.textColor, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: surnameController,
                style: TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.w600, fontSize: 18),
                cursorColor: RydyColors.textColor,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).translate('last_name'),
                  labelStyle: TextStyle(color: RydyColors.subText, fontWeight: FontWeight.w500),
                  filled: true,
                  fillColor: RydyColors.darkBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: RydyColors.textColor, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                ),
                ),
                const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        AppLocalizations.of(context).translate('cancel'),
                        style: TextStyle(color: RydyColors.subText, fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                  child: ElevatedButton(
                      onPressed: () {
                        if (nameController.text.isNotEmpty) {
                          Navigator.pop(context, {
                            'name': nameController.text.trim(),
                            'surname': surnameController.text.trim(),
                          });
                        }
                      },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RydyColors.darkBg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                      child: Text(
                        AppLocalizations.of(context).translate('save'),
                        style: TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                  ),
                ),
              ],
            ),
            ],
          ),
        ),
      ),
    );
    if (result != null) {
      await _updateNameAndSurname(result['name'] ?? '', result['surname'] ?? '');
    }
  }
  Future<void> _updateNameAndSurname(String name, String surname) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client
          .from('passenger')
          .update({
            'name': name,
            'surname': surname,
          })
          .eq('uid', user.id);
      await _fetchUserData();
      if (Navigator.of(context).mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).translate('name_updated')), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (Navigator.of(context).mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).translate('error') + ': $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  Future<void> _showEditPhoneSheet(BuildContext context) async {
    final phoneController = TextEditingController();
    bool codeSent = false;
    bool isLoading = false;
    String? errorText;
    final currentPhone = (_userData?['phone'] ?? '').toString();
    if (currentPhone.isNotEmpty) {
      for (int i = 0; i < countries.length; i++) {
        if (currentPhone.startsWith(countries[i]['code'])) {
          selectedCountryIndex = i;
          final phoneWithoutCode = currentPhone.substring(countries[i]['code'].length);
          phoneController.text = phoneWithoutCode;
          break;
        }
      }
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: RydyColors.cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.all(24),
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
                Text(
                  AppLocalizations.of(context).translate('modify_phone_number'),
                  style: TextStyle(
                    color: RydyColors.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (!codeSent) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: RydyColors.darkBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: RydyColors.darkBg, width: 1.5),
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
                                      title: Text('${countries[index]['name']} (${countries[index]['code']})', style: const TextStyle(color: RydyColors.textColor)),
                                      onTap: () => Navigator.pop(context, index),
                                    );
                                  },
                                );
                              },
                            );
                            if (selected != null) {
                              setModalState(() {
                                selectedCountryIndex = selected;
                                phoneController.clear();
                              });
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Image.asset(
                              countries[selectedCountryIndex]['flag']!,
                              width: 32,
                              height: 32,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          countries[selectedCountryIndex]['code']!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: RydyColors.textColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 1.2,
                          height: 32,
                          color: RydyColors.subText,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                    controller: phoneController,
                            keyboardType: TextInputType.number,
                            maxLength: int.parse(countries[selectedCountryIndex]['maxLength']!),
                            onChanged: (value) => setModalState(() {}),
                            style: const TextStyle(
                              fontSize: 18,
                              color: RydyColors.textColor,
                              letterSpacing: 1,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context).translate('mobile_number'),
                              hintStyle: TextStyle(color: RydyColors.subText, fontSize: 18),
                              border: InputBorder.none,
                              counterText: '',
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorText!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                    ),
                  ],
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: (phoneController.text.isNotEmpty && isValidPhoneNumber(phoneController.text) && !isLoading) ? () async {
                        setModalState(() => isLoading = true);
                        try {
                          final phoneNumber = countries[selectedCountryIndex]['code']! + phoneController.text;
                          await _sendOTP(phoneNumber);
                          setModalState(() {
                            codeSent = true;
                            isLoading = false;
                            errorText = null;
                          });
                        } catch (e) {
                          setModalState(() {
                            errorText = AppLocalizations.of(context).translate('error') + ': $e';
                            isLoading = false;
                          });
                        }
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RydyColors.darkBg,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              AppLocalizations.of(context).translate('send_code'),
                              style: TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                    ),
                  ),
                ] else ...[
                  Text(
                    AppLocalizations.of(context).translate('code_sent_to') + '${countries[selectedCountryIndex]['code']!}${phoneController.text}',
                    style: TextStyle(color: RydyColors.subText, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _OTPInputField(
                    onCompleted: (code) async {
                      setModalState(() => isLoading = true);
                      try {
                        final phoneNumber = countries[selectedCountryIndex]['code']! + phoneController.text;
                        await _verifyOTPAndUpdatePhone(phoneNumber, code);
                          Navigator.pop(context);
                        if (Navigator.of(context).mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppLocalizations.of(context).translate('phone_number_updated')), backgroundColor: Colors.green),
                          );
                        }
                      } catch (e) {
                        setModalState(() {
                          errorText = AppLocalizations.of(context).translate('incorrect_code') + ': $e';
                          isLoading = false;
                        });
                      }
                    },
                    isLoading: isLoading,
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      errorText!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setModalState(() {
                        codeSent = false;
                        errorText = null;
                      });
                    },
                    child: Text(
                      AppLocalizations.of(context).translate('change_number'),
                      style: TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      AppLocalizations.of(context).translate('cancel'),
                      style: TextStyle(color: RydyColors.subText, fontWeight: FontWeight.w600, fontSize: 16),
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
  Future<void> _sendOTP(String phoneNumber) async {
    await Future.delayed(const Duration(seconds: 2));
    print('OTP would be sent to: $phoneNumber');
  }
  Future<void> _verifyOTPAndUpdatePhone(String phoneNumber, String otpCode) async {
    if (otpCode.length != 6) {
      throw Exception(AppLocalizations.of(context).translate('invalid_otp_code'));
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    await Supabase.instance.client
        .from('passenger')
        .update({
          'phone': phoneNumber,
          'phone_verified': true,
        })
        .eq('uid', user.id);
    await _fetchUserData();
  }
  Future<void> _showEditEmailSheet(BuildContext context) async {
    final emailController = TextEditingController(text: (_userData?['email'] ?? '').toString());
    bool isLoading = false;
    String? errorText;
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
        decoration: BoxDecoration(
          color: RydyColors.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
            padding: const EdgeInsets.all(24),
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
            Text(
                  AppLocalizations.of(context).translate('modify_email'),
              style: TextStyle(
                color: RydyColors.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
                TextField(
                  controller: emailController,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.w600, fontSize: 18),
                  cursorColor: RydyColors.textColor,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).translate('email_address'),
                    labelStyle: TextStyle(color: RydyColors.subText, fontWeight: FontWeight.w500),
                    filled: true,
                    fillColor: RydyColors.darkBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: RydyColors.textColor, width: 1.5)),
                    errorText: errorText,
                    errorStyle: const TextStyle(color: Colors.redAccent),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  ),
                  onChanged: (_) => setModalState(() => errorText = null),
                ),
                const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          AppLocalizations.of(context).translate('cancel'),
                          style: TextStyle(color: RydyColors.subText, fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () async {
                          final newEmail = emailController.text.trim();
                          if (newEmail.isEmpty) {
                            setModalState(() => errorText = AppLocalizations.of(context).translate('please_enter_email'));
                            return;
                          }
                          if (!_isValidEmail(newEmail)) {
                            setModalState(() => errorText = AppLocalizations.of(context).translate('please_enter_valid_email'));
                            return;
                          }
                          setModalState(() => isLoading = true);
                          try {
                            await _updateEmail(newEmail);
                            Navigator.pop(context, newEmail);
                            if (Navigator.of(context).mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(AppLocalizations.of(context).translate('email_updated')), backgroundColor: Colors.green),
                              );
                            }
                          } catch (e) {
                            setModalState(() {
                              errorText = AppLocalizations.of(context).translate('error') + ': $e';
                              isLoading = false;
                            });
                          }
                        },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RydyColors.darkBg,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                AppLocalizations.of(context).translate('save'),
                                style: TextStyle(color: RydyColors.textColor, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null && result != (_userData?['email'] ?? '')) {
    }
  }
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');
    return emailRegex.hasMatch(email.trim());
  }
  Future<void> _updateEmail(String email) async {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
    try {
      await Supabase.instance.client
          .from('passenger')
          .update({
            'email': email,
          })
          .eq('uid', user.id);
      await _fetchUserData();
    } catch (e) {
      throw Exception(AppLocalizations.of(context).translate('error_updating') + ': $e');
    }
  }
  Future<void> _showLanguageSelectionSheet(BuildContext context) async {
    final currentLanguage = (_userData?['language'] ?? 'fr').toString();
    int selectedLanguageIndex = 0;
    for (int i = 0; i < supportedLanguages.length; i++) {
      if (supportedLanguages[i]['code'] == currentLanguage) {
        selectedLanguageIndex = i;
        break;
      }
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: RydyColors.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
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
            Text(
              AppLocalizations.of(context).translate('choose_language'),
              style: TextStyle(
                color: RydyColors.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 250),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: supportedLanguages.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: RydyColors.darkBg),
                  itemBuilder: (context, index) {
                    final language = supportedLanguages[index];
                    final isSelected = index == selectedLanguageIndex;
                    return ListTile(
                      leading: Image.asset(
                        language['flag']!,
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                      ),
                      title: Text(
                        language['name']!,
                        style: TextStyle(
                          color: RydyColors.textColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        language['country']!,
                        style: TextStyle(color: RydyColors.subText, fontSize: 12),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: Colors.green, size: 24)
                          : null,
                      onTap: () async {
                        await _updateLanguage(language['code']);
                        Navigator.pop(context);
                        if (Navigator.of(context).mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
                              content: Text(AppLocalizations.of(context).translate('language_updated')),
            backgroundColor: Colors.green,
          ),
        );
      }
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  AppLocalizations.of(context).translate('cancel'),
                  style: TextStyle(color: RydyColors.subText, fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  Future<void> _updateLanguage(String languageCode) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client
          .from('passenger')
          .update({
            'language': languageCode,
          })
          .eq('uid', user.id);
      await AppLocalizations.of(context).setLocale(Locale(languageCode));
      WayfaroApp.of(context)?.setLocale(Locale(languageCode));
      await _fetchUserData();
      if (Navigator.of(context).mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('language_updated')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (Navigator.of(context).mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('error') + ': $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _QuickAccessCard({
    required this.icon,
    required this.label,
    this.onTap,
  });
    @override
  Widget build(BuildContext context) {
    return Expanded(
              child: GestureDetector(
        onTap: onTap,
                      child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.trailing,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(color: Colors.white70, fontSize: 16)),
                ],
              ),
            ),
          if (trailing != null) ...[
            trailing!,
            const SizedBox(width: 6),
          ],
          Icon(icon, color: Colors.white38, size: 22),
        ],
      ),
    );
  }
}
class _OTPInputField extends StatefulWidget {
  final Function(String) onCompleted;
  final bool isLoading;
  const _OTPInputField({
    required this.onCompleted,
    required this.isLoading,
  });
  @override
  State<_OTPInputField> createState() => _OTPInputFieldState();
}
class _OTPInputFieldState extends State<_OTPInputField> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }
  void _onCodeChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    final code = _controllers.map((c) => c.text).join();
    if (code.length == 6) {
      widget.onCompleted(code);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) => SizedBox(
        width: 45,
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          enabled: !widget.isLoading,
          style: TextStyle(
            color: RydyColors.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          cursorColor: RydyColors.textColor,
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: RydyColors.darkBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: RydyColors.textColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onChanged: (value) => _onCodeChanged(value, index),
        ),
      )),
    );
  }
} 
