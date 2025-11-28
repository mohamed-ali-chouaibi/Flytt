import 'package:flutter/material.dart';
import '../utils/theme_provider.dart';
import '../utils/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'subscription_screen.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
class TrustedContactsScreen extends StatefulWidget {
  const TrustedContactsScreen({Key? key}) : super(key: key);
  @override
  State<TrustedContactsScreen> createState() => _TrustedContactsScreenState();
}
class _TrustedContactsScreenState extends State<TrustedContactsScreen> {
  List<Map<String, dynamic>> _trustedContacts = [];
  bool _isLoading = true;
  bool _isAddingContact = false;
  String? _currentSubscription;
  DateTime? _subscriptionEndDate;
  @override
  void initState() {
    super.initState();
    _loadCurrentSubscription();
    _loadTrustedContacts();
  }
  Future<void> _loadCurrentSubscription() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('passenger')
            .select('subscription_plan, subscription_end_date')
            .eq('id', user.id)
            .single();
        setState(() {
          _currentSubscription = response['subscription_plan'] ?? 'free';
          _subscriptionEndDate = response['subscription_end_date'] != null 
              ? DateTime.parse(response['subscription_end_date'])
              : null;
        });
      }
    } catch (e) {
      print('Error loading subscription: $e');
    }
  }
  int _getMaxContacts() {
    switch (_currentSubscription) {
      case 'free':
        return 1;
      case 'saver':
        return 3;
      case 'premium':
        return 10;
      default:
        return 1;
    }
  }
  bool _canAddMoreContacts() {
    return _trustedContacts.length < _getMaxContacts();
  }
  Future<void> _loadTrustedContacts() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('trusted_contacts')
            .select()
            .eq('passenger_uid', user.id)
            .order('created_at', ascending: false);
        setState(() {
          _trustedContacts = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading trusted contacts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  Future<void> _addTrustedContact(Map<String, dynamic> contact) async {
    setState(() {
      _isAddingContact = true;
    });
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('trusted_contacts')
            .insert({
              'passenger_uid': user.id,
              'name': contact['name'],
              'phone': contact['phone'],
              'email': contact['email'],
              'created_at': DateTime.now().toIso8601String(),
            });
        await _loadTrustedContacts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('contact_added_successfully')),
            backgroundColor: RydyColors.textColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error adding trusted contact: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('error_adding_contact')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        _isAddingContact = false;
      });
    }
  }
  Future<void> _deleteTrustedContact(String contactId) async {
    try {
      await Supabase.instance.client
          .from('trusted_contacts')
          .delete()
          .eq('id', contactId);
      await _loadTrustedContacts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('contact_deleted_successfully')),
          backgroundColor: RydyColors.textColor,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error deleting trusted contact: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('error_deleting_contact')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  Future<void> _showContactPicker() async {
    if (!_canAddMoreContacts()) {
      _showSubscriptionUpgradeDialog();
      return;
    }
    if (!await FlutterContacts.requestPermission(readonly: true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('contacts_permission_required')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    try {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
      final contact = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ContactPickerScreen(contacts: contacts),
        ),
      );
      if (contact != null) {
        await _addTrustedContact(contact);
      }
    } catch (e) {
      print('Error picking contact: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('error_accessing_contacts')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  void _showSubscriptionUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RydyColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppLocalizations.of(context).translate('upgrade_your_plan'),
          style: TextStyle(
            color: RydyColors.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              color: RydyColors.textColor,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).translate('free_plan_limit_reached'),
              style: TextStyle(
                color: RydyColors.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).translate('free_plan_limit_description'),
              style: TextStyle(
                color: RydyColors.subText,
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context).translate('cancel'),
              style: TextStyle(color: RydyColors.subText),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToSubscription();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RydyColors.textColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              AppLocalizations.of(context).translate('upgrade_now'),
              style: TextStyle(color: RydyColors.darkBg),
            ),
          ),
        ],
      ),
    );
  }
  void _navigateToSubscription() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SubscriptionScreen(),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final maxContacts = _getMaxContacts();
    final currentCount = _trustedContacts.length;
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
          AppLocalizations.of(context).translate('trusted_contacts'),
          style: TextStyle(
            color: RydyColors.textColor,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        centerTitle: true,
        toolbarHeight: 60,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(RydyColors.textColor),
              ),
            )
          : ListView(
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
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: RydyColors.textColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.people_outline,
                          color: RydyColors.textColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context).translate('contact_limit'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: RydyColors.textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$currentCount/$maxContacts ${AppLocalizations.of(context).translate('contacts')}',
                              style: TextStyle(
                                fontSize: 16,
                                color: RydyColors.subText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_currentSubscription == 'free' && currentCount >= maxContacts)
                              Text(
                                  AppLocalizations.of(context).translate('upgrade_to_add_more'),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (_currentSubscription == 'free')
                        IconButton(
                          onPressed: _navigateToSubscription,
                          icon: Icon(
                            Icons.star_rounded,
                            color: RydyColors.textColor,
                            size: 24,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSection(
                  AppLocalizations.of(context).translate('share_your_trip_status'),
                  AppLocalizations.of(context).translate('trip_status_description'),
                  Icons.location_on_outlined,
                ),
                const SizedBox(height: 16),
                _buildSection(
                  AppLocalizations.of(context).translate('set_emergency_contacts'),
                  AppLocalizations.of(context).translate('emergency_contacts_description'),
                  Icons.emergency_outlined,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _canAddMoreContacts() ? _showContactPicker : _showSubscriptionUpgradeDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canAddMoreContacts() 
                          ? RydyColors.textColor 
                          : RydyColors.subText.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: _canAddMoreContacts() ? 4 : 0,
                      shadowColor: Colors.black.withOpacity(0.2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add,
                          color: _canAddMoreContacts() ? RydyColors.darkBg : RydyColors.subText,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context).translate('add_contact'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _canAddMoreContacts() ? RydyColors.darkBg : RydyColors.subText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (_trustedContacts.isNotEmpty) ...[
                  Text(
                    AppLocalizations.of(context).translate('your_trusted_contacts'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: RydyColors.textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._trustedContacts.map((contact) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: RydyColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: RydyColors.textColor.withOpacity(0.1),
                          child: Text(
                            contact['name'][0].toUpperCase(),
                            style: TextStyle(
                              color: RydyColors.textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contact['name'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: RydyColors.textColor,
                                ),
                              ),
                              Text(
                                contact['phone'],
                                style: TextStyle(
                                  color: RydyColors.subText,
                                  fontSize: 14,
                                ),
                              ),
                              if (contact['email'] != null)
                                Text(
                                  contact['email'],
                                  style: TextStyle(
                                    color: RydyColors.subText,
                                    fontSize: 14,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: RydyColors.subText),
                          onSelected: (value) {
                            if (value == 'delete') {
                              _showDeleteConfirmation(contact);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppLocalizations.of(context).translate('delete'),
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )).toList(),
                ],
                const SizedBox(height: 32),
              ],
            ),
    );
  }
  Widget _buildSection(String title, String description, IconData icon) {
    return Container(
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: RydyColors.textColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
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
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: RydyColors.textColor,
                  ),
                ),
                const SizedBox(height: 4),
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
        ],
      ),
    );
  }
  void _showDeleteConfirmation(Map<String, dynamic> contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RydyColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppLocalizations.of(context).translate('delete_contact'),
          style: TextStyle(
            color: RydyColors.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          AppLocalizations.of(context).translate('delete_contact_confirm').replaceAll('{name}', contact['name']),
          style: TextStyle(
            color: RydyColors.subText,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context).translate('cancel'),
              style: TextStyle(color: RydyColors.subText),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTrustedContact(contact['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              AppLocalizations.of(context).translate('delete'),
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
class ContactPickerScreen extends StatefulWidget {
  final List<Contact> contacts;
  const ContactPickerScreen({Key? key, required this.contacts}) : super(key: key);
  @override
  State<ContactPickerScreen> createState() => _ContactPickerScreenState();
}
class _ContactPickerScreenState extends State<ContactPickerScreen> {
  List<Contact> _filteredContacts = [];
  final TextEditingController _searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _filteredContacts = widget.contacts;
  }
  void _filterContacts(String query) {
    setState(() {
      _filteredContacts = widget.contacts
          .where((contact) =>
              contact.displayName.toLowerCase().contains(query.toLowerCase()) ||
              contact.phones.any((phone) => phone.number.contains(query)))
          .toList();
    });
  }
  Map<String, dynamic> _contactToMap(Contact contact) {
    return {
      'name': contact.displayName,
      'phone': contact.phones.isNotEmpty ? contact.phones.first.number : '',
      'email': contact.emails.isNotEmpty ? contact.emails.first.address : null,
    };
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
          AppLocalizations.of(context).translate('select_contact'),
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
          Container(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _searchController,
              onChanged: _filterContacts,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).translate('search_contacts'),
                hintStyle: TextStyle(color: RydyColors.subText),
                prefixIcon: Icon(Icons.search, color: RydyColors.subText),
                filled: true,
                fillColor: RydyColors.cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: TextStyle(color: RydyColors.textColor),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filteredContacts.length,
              itemBuilder: (context, index) {
                final contact = _filteredContacts[index];
                final contactMap = _contactToMap(contact);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      backgroundColor: RydyColors.textColor.withOpacity(0.1),
                      child: Text(
                        contactMap['name'][0].toUpperCase(),
                        style: TextStyle(
                          color: RydyColors.textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      contactMap['name'],
                      style: TextStyle(
                        color: RydyColors.textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      contactMap['phone'],
                      style: TextStyle(
                        color: RydyColors.subText,
                      ),
                    ),
                    trailing: Icon(
                      Icons.add_circle_outline,
                      color: RydyColors.textColor,
                    ),
                    onTap: () => Navigator.pop(context, contactMap),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: RydyColors.cardBg,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 
