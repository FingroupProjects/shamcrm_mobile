// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class PhoneVerificationScreen extends StatefulWidget {
//   const PhoneVerificationScreen({super.key});

//   @override
//   _PhoneVerificationScreenState createState() => _PhoneVerificationScreenState();
// }

// class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
//   final TextEditingController _phoneController = TextEditingController();
//   final TextEditingController _codeController = TextEditingController();
//   String? _verificationId;
//   bool _isCodeSent = false;

//   Future<void> _verifyPhoneNumber() async {
//     final phoneNumber = _phoneController.text.trim();
//     if (phoneNumber.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Введите номер телефона')),
//       );
//       return;
//     }

//     await FirebaseAuth.instance.verifyPhoneNumber(
//       phoneNumber: phoneNumber,
//       verificationCompleted: (PhoneAuthCredential credential) async {
//         await FirebaseAuth.instance.signInWithCredential(credential);
//         _saveVerificationStatus();
//         Navigator.pushReplacementNamed(context, '/phone_call');
//       },
//       verificationFailed: (FirebaseAuthException e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Ошибка верификации: ${e.message}')),
//         );
//       },
//       codeSent: (String verificationId, int? resendToken) {
//         setState(() {
//           _verificationId = verificationId;
//           _isCodeSent = true;
//         });
//       },
//       codeAutoRetrievalTimeout: (String verificationId) {
//         _verificationId = verificationId;
//       },
//     );
//   }

//   Future<void> _verifyCode() async {
//     final code = _codeController.text.trim();
//     if (code.isEmpty || _verificationId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Введите код подтверждения')),
//       );
//       return;
//     }

//     final credential = PhoneAuthProvider.credential(
//       verificationId: _verificationId!,
//       smsCode: code,
//     );

//     try {
//       await FirebaseAuth.instance.signInWithCredential(credential);
//       _saveVerificationStatus();
//       Navigator.pushReplacementNamed(context, '/phone_call');
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Ошибка подтверждения кода')),
//       );
//     }
//   }

//   Future<void> _saveVerificationStatus() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('isPhoneVerified', true);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Верификация номера')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//               controller: _phoneController,
//               decoration: InputDecoration(labelText: 'Номер телефона'),
//               keyboardType: TextInputType.phone,
//             ),
//             if (_isCodeSent)
//               TextField(
//                 controller: _codeController,
//                 decoration: InputDecoration(labelText: 'Код подтверждения'),
//                 keyboardType: TextInputType.number,
//               ),
//             SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: _isCodeSent ? _verifyCode : _verifyPhoneNumber,
//               child: Text(_isCodeSent ? 'Подтвердить код' : 'Отправить код'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }