import 'package:crm_task_manager/screens/MyNavBar.dart';
import 'package:crm_task_manager/screens/chats/chats_screen.dart';
import 'package:crm_task_manager/screens/dashboard/dashboard_screen.dart';
import 'package:crm_task_manager/screens/deal/deal_screen.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:crm_task_manager/screens/lead/lead_screen.dart';
import 'package:crm_task_manager/screens/task/task_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  final List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(),
    TaskScreen(),
    LeadScreen(),
    ChatsScreen(),
    DealScreen(),
    ProfileScreen(),
  ];

  final List<String> _titles = [
    'Дашборд',
    'Задачи',
    'Лиды',
    'Чаты',
    'Сделки',
    'Профиль',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (_selectedIndex == 5)
              IconButton(
                icon: Image.asset('assets/icons/arrow-left.png',
                    width: 24, height: 24),
                onPressed: () {
                  setState(() {
                    _selectedIndex = 0;
                  });
                },
              ),
            Container(
              width: 40,
              height: 40,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Image.asset('assets/images/avatar.png'),
                onPressed: () {
                  setState(() {
                    _selectedIndex = 5;
                  });
                },
              ),
            ),
            SizedBox(width: 8),
            _isSearching
                ? Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Поиск...',
                        border: InputBorder.none,
                      ),
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                      ),
                      onSubmitted: (query) {
                        // Обработка поиска при отправке
                        setState(() {
                          _isSearching = false;
                        });
                      },
                    ),
                  )
                : Text(
                    _titles[_selectedIndex],
                    style: TextStyle(
                        fontSize: 20,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600),
                  ),
            Spacer(),
            Row(
              children: [
                IconButton(
                  icon: Image.asset(
                    'assets/icons/AppBar/notification.png',
                    width: 24,
                    height: 24,
                  ),
                  onPressed: () {},
                ),
                if (_selectedIndex !=0) 
                  IconButton(
                    icon: Image.asset(
                      'assets/icons/AppBar/search.png',
                      width: 24,
                      height: 24,
                    ),
                    onPressed: () {
                      setState(() {
                        _isSearching = !_isSearching;
                        if (!_isSearching) {
                          _searchController.clear();
                        }
                      });
                    },
                  ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
      ),
      body: _widgetOptions[_selectedIndex],
      backgroundColor: Colors.white,
      bottomNavigationBar: _selectedIndex == 5
          ? null
          : MyNavBar(
              selectedIndex: _selectedIndex,
              onItemSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                  _isSearching = false;
                });
              },
            ),
    );
  }
}




// import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
// import 'package:crm_task_manager/bloc/lead/lead_event.dart';
// import 'package:crm_task_manager/bloc/lead/lead_state.dart';
// import 'package:crm_task_manager/screens/MyNavBar.dart';
// import 'package:crm_task_manager/screens/chats/chats_screen.dart';
// import 'package:crm_task_manager/screens/dashboard/dashboard_screen.dart';
// import 'package:crm_task_manager/screens/deal/deal_screen.dart';
// import 'package:crm_task_manager/screens/profile/profile_screen.dart';
// import 'package:crm_task_manager/screens/lead/lead_screen.dart';
// import 'package:crm_task_manager/screens/task/task_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// class HomeScreen extends StatefulWidget {
//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   int _selectedIndex = 0;
//   bool _isSearching = false;
//   int? _currentLeadStatusId;
//   final TextEditingController _searchController = TextEditingController();

//   final List<Widget> _widgetOptions = <Widget>[
//     DashboardScreen(),
//     TaskScreen(),
//     LeadScreen(),
//     ChatsScreen(),
//     DealScreen(),
//     ProfileScreen(),
//   ];

//   final List<String> _titles = [
//     'Дашборд',
//     'Задачи',
//     'Лиды',
//     'Чаты',
//     'Сделки',
//     'Профиль',
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         forceMaterialTransparency: true,
//         title: Row(
//           mainAxisAlignment: MainAxisAlignment.start,
//           children: [
//             if (_selectedIndex == 5)
//               IconButton(
//                 icon: Image.asset('assets/icons/arrow-left.png',
//                     width: 24, height: 24),
//                 onPressed: () {
//                   setState(() {
//                     _selectedIndex = 0;
//                   });
//                 },
//               ),
//             Container(
//               width: 40,
//               height: 40,
//               child: IconButton(
//                 padding: EdgeInsets.zero,
//                 icon: Image.asset('assets/images/avatar.png'),
//                 onPressed: () {
//                   setState(() {
//                     _selectedIndex = 5;
//                   });
//                 },
//               ),
//             ),
//             SizedBox(width: 8),
//             _isSearching
//                 ? Expanded(
//                     child: TextField(
//                       controller: _searchController,
//                       autofocus: true,
//                       decoration: InputDecoration(
//                         hintText: 'Поиск...',
//                         border: InputBorder.none,
//                       ),
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontFamily: 'Gilroy',
//                         fontWeight: FontWeight.w600,
//                       ),
//                       onSubmitted: (query) {
//                         setState(() {
//                           _isSearching = false;
//                         });

//                         if (_currentLeadStatusId != null) {
//                           BlocProvider.of<LeadBloc>(context).add(
//                             FetchLeads(_currentLeadStatusId!, query: query),
//                           );
//                         } else {
//                           // Можно показать сообщение или установить дефолтный статус id
//                           print('Ошибка: Не выбран статус для поиска');
//                         }
//                       },
//                     ),
//                   )
//                 : Text(
//                     _titles[_selectedIndex],
//                     style: TextStyle(
//                         fontSize: 20,
//                         fontFamily: 'Gilroy',
//                         fontWeight: FontWeight.w600),
//                   ),
//             Spacer(),
//             Row(
//               children: [
//                 IconButton(
//                   icon: Image.asset(
//                     'assets/icons/AppBar/notification.png',
//                     width: 24,
//                     height: 24,
//                   ),
//                   onPressed: () {},
//                 ),
//                 if (_selectedIndex != 0)
//                   IconButton(
//                     icon: Image.asset(
//                       'assets/icons/AppBar/search.png',
//                       width: 24,
//                       height: 24,
//                     ),
//                     onPressed: () {
//                       setState(() {
//                         _isSearching = !_isSearching;
//                         if (!_isSearching) {
//                           _searchController.clear();
//                         }
//                       });
//                     },
//                   ),
//               ],
//             ),
//           ],
//         ),
//         backgroundColor: Colors.white,
//       ),
//       body: BlocListener<LeadBloc, LeadState>(
//         listener: (context, state) {
//           if (state is LeadLoaded) {
//             setState(() {
//               _currentLeadStatusId = state.leadStatuses.isNotEmpty? state.leadStatuses.first.id : null;
//             });
//           }
//         },
//         child: _widgetOptions[_selectedIndex],
//       ),
//       backgroundColor: Colors.white,
//       bottomNavigationBar: _selectedIndex == 5
//           ? null
//           : MyNavBar(
//               selectedIndex: _selectedIndex,
//               onItemSelected: (index) {
//                 setState(() {
//                   _selectedIndex = index;
//                   _isSearching = false;
//                 });
//               },
//             ),
//     );
//   }
// }
