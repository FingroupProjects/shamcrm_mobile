import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_bar_shell.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/region_model.dart';
import 'package:crm_task_manager/screens/lead/tabBar/manager_list.dart';
import 'package:crm_task_manager/screens/lead/tabBar/region_list.dart';
import 'package:crm_task_manager/screens/lead/tabBar/source_lead_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContactsScreen extends StatefulWidget {
  final int statusId;

  ContactsScreen({
    required this.statusId,
  });

  @override
  _ContactsScreenState createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<Contact> contacts = [];
  List<Contact> filteredContacts = [];
  Set<Contact> selectedContacts = Set();
  final apiService = ApiService();
  bool isSearching = false;
  bool isFiltersExpanded = false; // To track if filters section is expanded
  TextEditingController searchController = TextEditingController();
  bool _isLoading = true; // Добавлен флаг загрузки

  // Added state variables for the new fields
  String selectedRegion = "";
  String selectedManager = "";
  String? selectedSourceLead;
  String? currentUserId;

  Color _screenPrimaryText(BuildContext context) =>
      context.appColors.textPrimary;
  Color _screenSecondaryText(BuildContext context) =>
      context.appColors.textSecondary;
  Color _screenHintText(BuildContext context) => context.appColors.fieldHint;
  Color _screenBorder(BuildContext context) => context.appColors.borderSubtle;
  Color _screenFieldBackground(BuildContext context) =>
      context.appColors.fieldBg;
  Color _screenSurfaceBackground(BuildContext context) =>
      context.appColors.surfacePrimary;
  Color _screenSurfaceElevated(BuildContext context) =>
      context.appColors.surfaceElevated;

  BoxDecoration _cardDecoration(BuildContext context) => BoxDecoration(
        color: _screenSurfaceBackground(context).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _screenBorder(context)),
        boxShadow: [
          BoxShadow(
            color: context.appColors.shadow.withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      );

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId().then((_) {
      // После загрузки currentUserId, обновляем состояние
      if (mounted) {
        setState(() {
          _isLoading = false; // Загрузка завершена
        });
      }
    });
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
    _requestPermissionAndLoadContacts();
  }

  Future<void> _loadCurrentUserId() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String userId = prefs.getString('userID') ?? 'null';
      //print('Loaded currentUserId: $userId'); // Логируем значение
      if (mounted) {
        setState(() {
          currentUserId = userId;
          // //print(
          //     'State updated: currentUserId = $currentUserId'); // Логируем обновление состояния
        });
      }
    } catch (e) {
      //print('Error loading current user ID: $e');
    }
  }

  Future<void> _requestPermissionAndLoadContacts() async {
    if (await FlutterContacts.requestPermission()) {
      _getContacts();
    } else {
      _showSnackBar(
          AppLocalizations.of(context)!
              .translate('no_permession_to_access_contacts'),
          context.appColors.error);
    }
  }

  Future<void> _getContacts() async {
    try {
      List<Contact> fetchedContacts = await FlutterContacts.getContacts(
          withProperties: true, withPhoto: true);
      fetchedContacts = fetchedContacts.where((contact) {
        return (contact.displayName != null &&
                contact.displayName!.isNotEmpty) &&
            (contact.phones.isNotEmpty);
      }).toList();

      setState(() {
        contacts = fetchedContacts;
        filteredContacts = contacts;
      });
    } catch (e) {
      //print("Ошибка при загрузке контактов: $e");
    }
  }

  void _showContactDetails(Contact contact) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _screenSurfaceBackground(context),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: _screenBorder(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              Center(
                child: CircleAvatar(
                  backgroundColor: _screenSurfaceElevated(context),
                  radius: 50,
                  backgroundImage: contact.photo != null
                      ? MemoryImage(contact.photo!)
                      : null,
                  child: contact.photo == null
                      ? Icon(
                          Icons.person,
                          size: 50,
                          color: _screenPrimaryText(context),
                        )
                      : null,
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: Text(
                  contact.displayName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Gilroy',
                    color: _screenPrimaryText(context),
                  ),
                ),
              ),
              Divider(color: _screenBorder(context)),
              SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.translate('phones'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Gilroy',
                  color: _screenPrimaryText(context),
                ),
              ),
              ...contact.phones.map((phone) {
                final uniquePhone = phone.number.replaceAll(RegExp(r'\s+'), '');
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.phone,
                        color: context.appColors.buttonPrimaryBg,
                      ),
                      SizedBox(width: 8),
                      Text(
                        uniquePhone,
                        style: TextStyle(color: _screenSecondaryText(context)),
                      ),
                    ],
                  ),
                );
              }).toSet(),
              SizedBox(height: 16),
              Text(
                'Emails:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Gilroy',
                  color: _screenPrimaryText(context),
                ),
              ),
              ...contact.emails.map((email) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.email,
                        color: context.appColors.buttonPrimaryBg,
                      ),
                      SizedBox(width: 8),
                      Text(
                        email.address,
                        style: TextStyle(color: _screenSecondaryText(context)),
                      ),
                    ],
                  ),
                );
              }).toList(),
              SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.translate('address'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Gilroy',
                  color: _screenPrimaryText(context),
                ),
              ),
              ...contact.addresses.map((address) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: context.appColors.buttonPrimaryBg,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          address.street,
                          style: TextStyle(color: _screenSecondaryText(context)),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        );
      },
    );
  }

  void _filterContacts(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredContacts = contacts;
      } else {
        filteredContacts = contacts.where((contact) {
          return contact.displayName
                  ?.toLowerCase()
                  .contains(query.toLowerCase()) ??
              false;
        }).toList();
      }
    });
  }

  void _toggleContactSelection(Contact contact) {
    setState(() {
      if (selectedContacts.contains(contact)) {
        selectedContacts.remove(contact);
      } else {
        selectedContacts.add(contact);
      }
    });
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: context.appColors.textInverse,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: backgroundColor,
        elevation: 3,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }

void _showFailedContactsDialog(
    List<Map<String, dynamic>> failedContacts, int totalContacts) {
  int successfulContacts = totalContacts - failedContacts.length;

  showDialog(
    context: context,
    barrierColor: context.appColors.overlay.withValues(alpha: 0.45),
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          constraints:
              BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          decoration: BoxDecoration(
            color: _screenSurfaceBackground(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _screenBorder(context)),
            boxShadow: [
              BoxShadow(
                color: context.appColors.shadow.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _screenSurfaceElevated(context),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                width: double.infinity,
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.translate('failed_contacts_title') ??
                        'Failed Contacts',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _screenPrimaryText(context),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Statistics card
                      Container(
                        margin: EdgeInsets.only(bottom: 20),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _screenSurfaceElevated(context),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: context.appColors.shadow.withValues(alpha: 0.05),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildStatRow(
                              context,
                              AppLocalizations.of(context)!.translate('total_contacts') ?? 'Total contacts',
                              totalContacts.toString(),
                              _screenPrimaryText(context),
                              Icons.people_alt_rounded,
                            ),
                            Divider(height: 20, thickness: 1, color: _screenBorder(context)),
                            _buildStatRow(
                              context,
                              AppLocalizations.of(context)!.translate('successfully_added') ?? 'Successfully added',
                              successfulContacts.toString(),
                              context.appColors.success,
                              Icons.check_circle_rounded,
                            ),
                            Divider(height: 20, thickness: 1, color: _screenBorder(context)),
                            _buildStatRow(
                              context,
                              AppLocalizations.of(context)!.translate('failed_to_add') ?? 'Failed to add',
                              failedContacts.length.toString(),
                              context.appColors.error,
                              Icons.error_rounded,
                            ),
                          ],
                        ),
                      ),

                      // Failed contacts section
                      if (failedContacts.isNotEmpty) ...[
                        Padding(
                          padding: EdgeInsets.only(bottom: 12, left: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: context.appColors.warning,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)!.translate('contacts_with_errors') ??
                                    'Contacts with errors:',
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w700,
                                  color: _screenPrimaryText(context),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Failed contacts list
                        ListView.separated(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: failedContacts.length,
                          separatorBuilder: (context, index) => SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final contact = failedContacts[index];
                            final name = contact['name'] ?? '';
                            final errors = (contact['errors'] as List);

                            return Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _screenFieldBackground(context),
                                border: Border.all(
                                  color: context.appColors.error.withValues(alpha: 0.24),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: _screenSurfaceElevated(context),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              fontFamily: 'Gilroy',
                                              fontWeight: FontWeight.w700,
                                              color: _screenPrimaryText(context),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: TextStyle(
                                            fontFamily: 'Gilroy',
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                            color: _screenPrimaryText(context),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  ...errors.map((error) => Padding(
                                    padding: EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.error_outline_rounded,
                                          color: context.appColors.error,
                                          size: 16,
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            error.toString(),
                                            style: TextStyle(
                                              color: context.appColors.error,
                                              fontFamily: 'Gilroy',
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )).toList(),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Action buttons
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: _screenSurfaceBackground(context),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.appColors.shadow.withValues(alpha: 0.05),
                      spreadRadius: 0,
                      blurRadius: 10,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // If at least one contact was added successfully, close the contacts screen
                          if (successfulContacts > 0) {
                            Navigator.of(context).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.appColors.buttonPrimaryBg,
                          foregroundColor: context.appColors.buttonPrimaryFg,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.translate('ok') ?? 'OK',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
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
}

// Helper method to create statistic rows
Widget _buildStatRow(BuildContext context, String label, String value, Color color, IconData icon) {
  return Row(
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
      ),
      SizedBox(width: 12),
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 14,
            color: context.appColors.textSecondary,
          ),
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: color,
        ),
      ),
    ],
  );
}

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final primaryText = _screenPrimaryText(context);
    final border = _screenBorder(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            const AppBackgroundOverlay(
              preset: AppBackgroundPreset.aurora,
            ),
            Center(
              child: CircularProgressIndicator(
                color: colors.buttonPrimaryBg,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 96,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: AppBarShell(
            leading: AppBarShell.capsule(
              context,
              width: AppBarShell.orbSize,
              child: IconButton(
                padding: EdgeInsets.zero,
                alignment: Alignment.center,
                splashRadius: 22,
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 22,
                  color: primaryText,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            center: AppBarShell.capsule(
              context,
              child: isSearching
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: TextField(
                        controller: searchController,
                        autofocus: true,
                        cursorColor: colors.buttonPrimaryBg,
                        style: TextStyle(
                          color: primaryText,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                        ),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!
                              .translate('search_appbar'),
                          hintStyle: TextStyle(
                            color: _screenHintText(context),
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            fontSize: 17,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                        onChanged: _filterContacts,
                      ),
                    )
                  : Center(
                      child: Text(
                        AppLocalizations.of(context)!.translate('phone_contacts'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: primaryText,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                        ),
                      ),
                    ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBarShell.capsule(
                  context,
                  width: AppBarShell.orbSize,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.center,
                    splashRadius: 22,
                    icon: Icon(
                      isSearching ? Icons.close_rounded : Icons.search_rounded,
                      color: primaryText,
                    ),
                    onPressed: () {
                      setState(() {
                        if (isSearching) {
                          isSearching = false;
                          searchController.clear();
                          _filterContacts('');
                        } else {
                          isSearching = true;
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                AppBarShell.capsule(
                  context,
                  width: AppBarShell.orbSize,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.center,
                    splashRadius: 22,
                    icon: Icon(
                      selectedContacts.length == contacts.length &&
                              contacts.isNotEmpty
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      color: selectedContacts.length == contacts.length &&
                              contacts.isNotEmpty
                          ? colors.buttonPrimaryBg
                          : primaryText,
                    ),
                    onPressed: () {
                      setState(() {
                        if (selectedContacts.length == contacts.length) {
                          selectedContacts.clear();
                        } else {
                          selectedContacts.clear();
                          selectedContacts.addAll(contacts);
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          const AppBackgroundOverlay(
            preset: AppBackgroundPreset.aurora,
          ),
          SafeArea(
            child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    isFiltersExpanded = !isFiltersExpanded;
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: _cardDecoration(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)
                                ?.translate('specify_lead_data') ??
                            'Filters',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: primaryText,
                          fontSize: 16,
                        ),
                      ),
                      Icon(
                        isFiltersExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: primaryText,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              height: isFiltersExpanded ? null : 0,
              child: isFiltersExpanded
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: _cardDecoration(context),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RegionRadioGroupWidget(
                            selectedRegion: selectedRegion,
                            onSelectRegion: (RegionData selectedRegionData) {
                              setState(() {
                                selectedRegion =
                                    selectedRegionData.id.toString();
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          ManagerRadioGroupWidget(
                            selectedManager: selectedManager,
                            currentUserId:
                                currentUserId, // Передаем currentUserId
                            onSelectManager: (ManagerData selectedManagerData) {
                              setState(() {
                                selectedManager =
                                    selectedManagerData.id.toString();
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          SourceLeadWidget(
                            selectedSourceLead: selectedSourceLead,
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedSourceLead = newValue;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                      ),
                    )
                  : SizedBox(),
            ),
            Expanded(
              child: contacts.isEmpty
                  ? Center(
                      child: CircularProgressIndicator(
                        color: colors.buttonPrimaryBg,
                      ))
                  : filteredContacts.isEmpty
                      ? Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.all(24),
                            decoration: _cardDecoration(context),
                            child: Text(
                              AppLocalizations.of(context)!
                                  .translate('no_result'),
                              style: context.appTextStyles.bodyMd.copyWith(
                                color: _screenSecondaryText(context),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ))
                      : ListView.builder(
                          itemCount: filteredContacts.length,
                          itemBuilder: (context, index) {
                            Contact contact = filteredContacts[index];
                            return Container(
                              margin: EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 16),
                              decoration: _cardDecoration(context),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => _showContactDetails(contact),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor:
                                              _screenSurfaceElevated(context),
                                          backgroundImage: contact.photo != null
                                              ? MemoryImage(contact.photo!)
                                              : null,
                                          child: contact.photo == null
                                              ? Icon(
                                                  Icons.person,
                                                  color: primaryText,
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                contact.displayName,
                                                style: TextStyle(
                                                  color: primaryText,
                                                  fontFamily: 'Gilroy',
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                contact.phones.isNotEmpty
                                                    ? contact.phones.first.number
                                                    : AppLocalizations.of(context)!
                                                        .translate('no_number'),
                                                style: TextStyle(
                                                  color: _screenSecondaryText(
                                                      context),
                                                  fontFamily: 'Gilroy',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Checkbox(
                                          activeColor: colors.buttonPrimaryBg,
                                          checkColor: colors.buttonPrimaryFg,
                                          side: BorderSide(color: border),
                                          value:
                                              selectedContacts.contains(contact),
                                          onChanged: (bool? value) {
                                            _toggleContactSelection(contact);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
          ),
        ],
      ),
      floatingActionButton: selectedContacts.isNotEmpty
          ? FloatingActionButton(
              onPressed: () async {
                try {
                  List<Map<String, dynamic>> contactsToSend = [];
                  List<Contact> orderedContacts = selectedContacts.toList();

                  for (var contact in orderedContacts) {
                    if (contact.phones.isNotEmpty) {
                      contactsToSend.add({
                        'name': contact.displayName,
                        'phone': contact.phones.first.number,
                        'region_id': selectedRegion,
                        'manager_id': selectedManager,
                        'source_id': selectedSourceLead,
                        'lead_status_id': widget.statusId,
                      });
                    }
                  }

                  int totalContacts = contactsToSend.length;

                  final responseData = await apiService.addLeadsFromContacts(
                      widget.statusId, contactsToSend);

                  if (responseData.containsKey('result') &&
                      responseData['result'] is List) {
                    List<dynamic> results = responseData['result'];
                    List<Map<String, dynamic>> failedContacts = [];

                    for (var item in results) {
                      if (item is Map<String, dynamic> &&
                          item.containsKey('errors') &&
                          item['errors'] is List &&
                          (item['errors'] as List).isNotEmpty) {
                        failedContacts.add(item);
                      }
                    }

                    if (failedContacts.isNotEmpty) {
                      _showFailedContactsDialog(failedContacts, totalContacts);
                    } else {
                      _showSnackBar(
                          AppLocalizations.of(context)!
                              .translate('contacts_sent'),
                          colors.success);

                      Future.delayed(Duration(seconds: 1), () {
                        Navigator.of(context).pop();
                      });
                    }
                  } else {
                    _showSnackBar(
                        AppLocalizations.of(context)!
                            .translate('contacts_sent'),
                        colors.success);

                    Future.delayed(Duration(seconds: 1), () {
                      Navigator.of(context).pop();
                    });
                  }
                } catch (e) {
                  _showSnackBar(
                      AppLocalizations.of(context)!
                          .translate('error_contacts_sent'),
                      colors.error);
                }
              },
              backgroundColor: colors.buttonPrimaryBg,
              child: Icon(
                Icons.send,
                color: colors.buttonPrimaryFg,
                size: 26,
              ),
            )
          : null,
    );
  }
}
