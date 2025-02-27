import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/region_model.dart';
import 'package:crm_task_manager/screens/lead/tabBar/manager_list.dart';
import 'package:crm_task_manager/screens/lead/tabBar/region_list.dart';
import 'package:crm_task_manager/screens/lead/tabBar/source_lead_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

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
  
  // Added state variables for the new fields
  String selectedRegion = "";
  String selectedManager = "";
  String? selectedSourceLead;

  @override
  void initState() {
    super.initState();
    _requestPermissionAndLoadContacts();
  }

  Future<void> _requestPermissionAndLoadContacts() async {
    if (await FlutterContacts.requestPermission()) {
      _getContacts();
    } else {
      _showSnackBar(AppLocalizations.of(context)!.translate('no_permession_to_access_contacts'), Colors.red);
    }
  }

  Future<void> _getContacts() async {
    try {
      List<Contact> fetchedContacts = await FlutterContacts.getContacts(withProperties: true, withPhoto: true);
      fetchedContacts = fetchedContacts.where((contact) {
        return (contact.displayName != null && contact.displayName!.isNotEmpty) &&
            (contact.phones.isNotEmpty);
      }).toList();

      setState(() {
        contacts = fetchedContacts;
        filteredContacts = contacts;
      });
    } catch (e) {
      print("Ошибка при загрузке контактов: $e");
    }
  }

 void _showContactDetails(Contact contact) {
  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
          Center(
            child: CircleAvatar(
              backgroundColor: Colors.black,
              radius: 50,
              backgroundImage: contact.photo != null
                  ? MemoryImage(contact.photo!)
                  : null,
              child: contact.photo == null
                  ? Icon(Icons.person, size: 50, color: Colors.white) 
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
                  color: Color(0xff1E2E52),
                ),
              ),
            ),
            Divider(color: Color(0xff1E2E52)), 
            SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.translate('phones'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600, 
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            ),
            ...contact.phones.map((phone) {
              final uniquePhone = phone.number.replaceAll(RegExp(r'\s+'), '');
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Icon(Icons.phone, color: Color(0xff1E2E52),),
                    SizedBox(width: 8),
                    Text( uniquePhone,
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              );
            }).toSet(),
            SizedBox(height: 16),
            Text('Emails:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            ),
            ...contact.emails.map((email) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Icon(Icons.email, color: Color(0xff1E2E52),), 
                    SizedBox(width: 8),
                    Text(
                      email.address,
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              );
            }).toList(),
            SizedBox(height: 16),
            Text( AppLocalizations.of(context)!.translate('address'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            ),
            ...contact.addresses.map((address) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Color(0xff1E2E52),),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        address.street,
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
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
          return contact.displayName?.toLowerCase().contains(query.toLowerCase()) ?? false;
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
            color: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
        appBar: AppBar(
          forceMaterialTransparency: true,
          titleSpacing: 0, 
          title: isSearching
              ? TextField(
                  controller: searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.translate('search_appbar'),
                    border: InputBorder.none,
                  ),
                  onChanged: _filterContacts,
                )
              : Row(
                  children: [
                    Text(AppLocalizations.of(context)!.translate('phone_contacts'),
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Image.asset(
                  isSearching
                      ? 'assets/icons/AppBar/close.png'
                      : 'assets/icons/AppBar/search.png',
                  width: 24,
                  height: 24,
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
          ],
          leading: Padding(
            padding: const EdgeInsets.only(right: 0),
            child: Transform.translate(
              offset: const Offset(0, -2),
              child: IconButton(
                icon: Image.asset(
                  'assets/icons/arrow-left.png',
                  width: 24,
                  height: 24,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),
          leadingWidth: 50,
        ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Add a filter button and collapsible filter section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    isFiltersExpanded = !isFiltersExpanded;
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xffF4F7FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)?.translate('Выберите данные') ?? 'Filters',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: Color(0xff1E2E52),
                          fontSize: 16,
                        ),
                      ),
                      Icon(
                        isFiltersExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Color(0xff1E2E52),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Collapsible filters section
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              height: isFiltersExpanded ? null : 0,
              child: isFiltersExpanded ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    RegionRadioGroupWidget(
                      selectedRegion: selectedRegion,
                      onSelectRegion: (RegionData selectedRegionData) {
                        setState(() {
                          selectedRegion = selectedRegionData.id.toString();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    ManagerRadioGroupWidget(
                      selectedManager: selectedManager,
                      onSelectManager: (ManagerData selectedManagerData) {
                        setState(() {
                          selectedManager = selectedManagerData.id.toString();
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
              ) : SizedBox(),
            ),
            
            // Contact list
            Expanded(
              child: contacts.isEmpty
                  ? Center(child: CircularProgressIndicator(color: Color(0xff1E2E52)))
                  : filteredContacts.isEmpty
                      ? Center(child: Text(AppLocalizations.of(context)!.translate('no_result')))
                      : ListView.builder(
                          itemCount: filteredContacts.length,
                          itemBuilder: (context, index) {
                            Contact contact = filteredContacts[index];
                            return Container(
                              margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xffF4F7FD),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.black,
                                backgroundImage: contact.photo != null
                                    ? MemoryImage(contact.photo!) 
                                    : null,
                                child: contact.photo == null
                                    ? Icon(Icons.person, color: Colors.white) 
                                    : null,
                              ),
                                title: Text(
                                  contact.displayName,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(contact.phones.isNotEmpty ? contact.phones.first.number : AppLocalizations.of(context)!.translate('no_number')),
                                trailing: Transform.scale(
                                  scale: 1.1,
                                  child: Checkbox(
                                    activeColor: Color(0xff1E2E52),
                                    value: selectedContacts.contains(contact),
                                    onChanged: (bool? value) {
                                      _toggleContactSelection(contact);
                                    },
                                  ),
                                ),
                                onTap: () => _showContactDetails(contact),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: selectedContacts.isNotEmpty
          ? FloatingActionButton(
              onPressed: () async {
                try {
                  List<Map<String, dynamic>> contactsToSend = [];
                  for (var contact in selectedContacts) {
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
                  await apiService.addLeadsFromContacts(widget.statusId, contactsToSend);
                  _showSnackBar( AppLocalizations.of(context)!.translate('contacts_sent'), Colors.green);
                  setState(() {
                    selectedContacts.clear();
                  });
                } catch (e) {
                  _showSnackBar(AppLocalizations.of(context)!.translate('error_contacts_sent'), Colors.red);
                }
              },
              backgroundColor: Color(0xff1E2E52),
              child: Icon(
                Icons.send,
                color: Colors.white,
                size: 26,
              ),
            )
          : null,
    );
  }
}