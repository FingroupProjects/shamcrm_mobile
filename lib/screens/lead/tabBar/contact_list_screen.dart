import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactsScreen extends StatefulWidget {
  @override
  _ContactsScreenState createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<Contact> contacts = [];
  List<Contact> filteredContacts = [];
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestPermissionAndLoadContacts();
  }

  Future<void> _requestPermissionAndLoadContacts() async {
    var status = await Permission.contacts.status;

    if (status.isDenied || status.isRestricted) {
      status = await Permission.contacts.request();
    }

    if (status.isGranted) {
      _getContacts();
    } else {
      _showPermissionDeniedMessage();
    }
  }

  Future<void> _getContacts() async {
    try {
      List<Contact> fetchedContacts = await ContactsService.getContacts();
      setState(() {
        contacts = fetchedContacts;
        filteredContacts = contacts; 
      });
    } catch (e) {
      print("Ошибка при загрузке контактов: $e");
    }
  }

  void _showPermissionDeniedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Нет разрешения на доступ к контактам")),
    );
  }

  void _showContactDetails(Contact contact) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
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
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: Text(
                  contact.displayName ?? 'Без имени',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Телефоны:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                ),
              ),
              ...contact.phones!.map((phone) {
                String phoneLabel = phone.label ?? 'Неизвестный номер';
                return Text('$phoneLabel: ${phone.value ?? ''}');
              }).toList(),
              SizedBox(height: 16),
              Text(
                'Emails:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                ),
              ),
              ...contact.emails!
                  .map((email) => Text(email.value ?? ''))
                  .toList(),
              SizedBox(height: 16),
              Text(
                'Адрес:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                ),
              ),
              ...contact.postalAddresses!
                  .map((address) => Text(address.street ?? ''))
                  .toList(),
            ],
          ),
        );
      },
    );
  }

  @override
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        titleSpacing: 2,
        title: isSearching
            ? TextField(
                controller: searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Поиск...',
                  border: InputBorder.none,
                ),
                onChanged: _filterContacts,
              )
            : Text(
                'Контакты телефона',
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                ),
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
      body: contacts.isEmpty
          ? Center(
              child:
                  CircularProgressIndicator()) // Показать загрузку, если контакты еще не загружены
          : filteredContacts.isEmpty
              ? Center(
                  child:
                      Text('Нечего не найдено', style: TextStyle(fontSize: 18)))
              : ListView.builder(
                  itemCount: filteredContacts.length,
                  itemBuilder: (context, index) {
                    Contact contact = filteredContacts[index];
                    return Card(
                      color: const Color(0xffF4F7FD),
                      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      elevation: 0,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.black,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          contact.displayName ?? 'Без имени',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          contact.phones!.isNotEmpty
                              ? contact.phones!.first.value ?? ''
                              : 'Нет номера',
                        ),
                        onTap: () => _showContactDetails(contact),
                      ),
                    );
                  },
                ),
    );
  }
}
