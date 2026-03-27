// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class PhoneCallWidget extends StatelessWidget {
//   const PhoneCallWidget({required Key key}) : super(key: key);

//   Future<bool> _isPhoneVerified() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getBool('isPhoneVerified') ?? false;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<bool>(
//       future: _isPhoneVerified(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return CircularProgressIndicator();
//         }
//         final isVerified = snapshot.data ?? false;
//         return ListTile(
//           leading: Icon(Icons.phone, color: Colors.blue),
//           title: Text('Телефония'),
//           onTap: () {
//             Navigator.pushNamed(
//               context,
//               isVerified ? '/phone_call' : '/phone_verification',
//             );
//           },
//         );
//       },
//     );
//   }
// }