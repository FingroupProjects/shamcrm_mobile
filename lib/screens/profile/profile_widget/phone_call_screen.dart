// import 'dart:convert';
// import 'package:agora_rtc_engine/agora_rtc_engine.dart';
// import 'package:crm_task_manager/models/call_model.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:uuid/uuid.dart';

// class PhoneCallScreen extends StatefulWidget {
//   const PhoneCallScreen({super.key});

//   @override
//   _PhoneCallScreenState createState() => _PhoneCallScreenState();
// }

// class _PhoneCallScreenState extends State<PhoneCallScreen> {
//   final TextEditingController _phoneController = TextEditingController();
//   List<Call> _callHistory = [];
//   bool _isCalling = false;
//   bool _isIncomingCall = false;
//   String _incomingCaller = '';
//   late RtcEngine _engine;
//   final String _channelName = 'shamCRM_channel'; // Фиксированное имя канала
//   bool _isMuted = false;
//   bool _isSpeakerOn = false;
//   String _selectedFilter = 'all'; // Фильтр для журнала звонков

//   @override
//   void initState() {
//     super.initState();
//     _initAgora();
//     _loadCallHistory();
//   }

//   Future<void> _initAgora() async {
//     try {
//       _engine = createAgoraRtcEngine();
//       await _engine.initialize(const RtcEngineContext(
//         appId: '1b1ecafbce994cffb01533d3933bc38c',
//         channelProfile: ChannelProfileType.channelProfileCommunication,
//       ));

//       _engine.registerEventHandler(
//         RtcEngineEventHandler(
//           onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
//             setState(() {
//               _isCalling = true;
//             });
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text('Подключение к каналу успешно')),
//             );
//           },
//           onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
//             setState(() {
//               _isIncomingCall = true;
//               _incomingCaller = 'Пользователь $remoteUid';
//             });
//             _addCallToHistory('incoming', _incomingCaller);
//           },
//           onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
//             _endCall();
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text('Пользователь отключился')),
//             );
//           },
//           onError: (ErrorCodeType err, String msg) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text('Ошибка: $msg')),
//             );
//           },
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Ошибка инициализации Agora: $e')),
//       );
//     }
//   }

//   Future<void> _loadCallHistory() async {
//     final prefs = await SharedPreferences.getInstance();
//     final jsonString = prefs.getString('call_history');
//     if (jsonString != null) {
//       final List<dynamic> jsonList = jsonDecode(jsonString);
//       setState(() {
//         _callHistory = jsonList.map((json) => Call.fromJson(json)).toList();
//       });
//     }
//   }

//   Future<void> _saveCallHistory() async {
//     final prefs = await SharedPreferences.getInstance();
//     final jsonList = jsonEncode(_callHistory.map((call) => call.toJson()).toList());
//     await prefs.setString('call_history', jsonList);
//   }

//   Future<void> _addCallToHistory(String status, String phoneNumber) async {
//     final call = Call(
//       id: Uuid().v4(),
//       phoneNumber: phoneNumber,
//       status: status,
//       timestamp: DateTime.now(),
//     );
//     setState(() {
//       _callHistory.add(call);
//     });
//     await _saveCallHistory();
//   }

//   Future<void> _startCall(String phoneNumber) async {
//     if (phoneNumber.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Введите номер телефона')),
//       );
//       return;
//     }

//     try {
//       await _engine.joinChannel(
//         token: '007eJxTYNhz+H2m2XL+WrNH0s9OmvHNcVyy3Hqv+D9zawXfv+8unzupwGCYZJianJiWlJxqaWmSnJaWZGBoamycYmxpbJyUbGyRfOFhZUZDICPDnVw5BkYoBPH5GYozEnOdg3zjkzMS8/JScxgYAHVvJfw=',
//         channelId: _channelName,
//         uid: 0,
//         options: ChannelMediaOptions(),
//       );
//       _addCallToHistory('outgoing', phoneNumber);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Ошибка при подключении к звонку: $e')),
//       );
//     }
//   }

//   Future<void> _acceptCall() async {
//     try {
//       await _engine.joinChannel(
//         token: '007eJxTYNhz+H2m2XL+WrNH0s9OmvHNcVyy3Hqv+D9zawXfv+8unzupwGCYZJianJiWlJxqaWmSnJaWZGBoamycYmxpbJyUbGyRfOFhZUZDICPDnVw5BkYoBPH5GYozEnOdg3zjkzMS8/JScxgYAHVvJfw=',
//         channelId: _channelName,
//         uid: 0,
//         options: ChannelMediaOptions(),
//       );
//       setState(() {
//         _isCalling = true;
//         _isIncomingCall = false;
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Ошибка при принятии звонка: $e')),
//       );
//     }
//   }

//   Future<void> _endCall() async {
//     await _engine.leaveChannel();
//     setState(() {
//       _isCalling = false;
//       _isMuted = false;
//       _isSpeakerOn = false;
//       _isIncomingCall = false;
//     });
//   }

//   Future<void> _toggleMute() async {
//     setState(() {
//       _isMuted = !_isMuted;
//     });
//     await _engine.muteLocalAudioStream(_isMuted);
//   }

//   Future<void> _toggleSpeaker() async {
//     setState(() {
//       _isSpeakerOn = !_isSpeakerOn;
//     });
//     await _engine.setEnableSpeakerphone(_isSpeakerOn);
//   }

//   @override
//   void dispose() {
//     _engine.release();
//     _phoneController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final filteredHistory = _selectedFilter == 'all'
//         ? _callHistory
//         : _callHistory.where((call) => call.status == _selectedFilter).toList();

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Телефония', style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600)),
//         backgroundColor: Color(0xff1E2E52),
//       ),
//       body: Column(
//         children: [
//           // Ввод номера и кнопка звонка
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _phoneController,
//                     decoration: InputDecoration(
//                       labelText: 'Номер телефона',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       filled: true,
//                       fillColor: Colors.grey[100],
//                     ),
//                     keyboardType: TextInputType.phone,
//                     style: TextStyle(fontFamily: 'Gilroy'),
//                   ),
//                 ),
//                 SizedBox(width: 8),
//                 AnimatedScaleButton(
//                   child: ElevatedButton(
//                     onPressed: () => _startCall(_phoneController.text),
//                     child: Icon(Icons.call, color: Colors.white),
//                     style: ElevatedButton.styleFrom(
//                       shape: CircleBorder(),
//                       padding: EdgeInsets.all(16),
//                       backgroundColor: Color(0xff1E2E52),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           // Интерфейс входящего звонка
//           if (_isIncomingCall)
//             Container(
//               padding: EdgeInsets.all(16),
//               color: Colors.blue[50],
//               child: Column(
//                 children: [
//                   Text(
//                     'Входящий звонок от: $_incomingCaller',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       fontFamily: 'Gilroy',
//                       color: Color(0xff1E2E52),
//                     ),
//                   ),
//                   SizedBox(height: 16),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       AnimatedScaleButton(
//                         child: ElevatedButton(
//                           onPressed: _acceptCall,
//                           child: Icon(Icons.call, color: Colors.white),
//                           style: ElevatedButton.styleFrom(
//                             shape: CircleBorder(),
//                             padding: EdgeInsets.all(16),
//                             backgroundColor: Colors.green,
//                           ),
//                         ),
//                       ),
//                       SizedBox(width: 16),
//                       AnimatedScaleButton(
//                         child: ElevatedButton(
//                           onPressed: _endCall,
//                           child: Icon(Icons.call_end, color: Colors.white),
//                           style: ElevatedButton.styleFrom(
//                             shape: CircleBorder(),
//                             padding: EdgeInsets.all(16),
//                             backgroundColor: Colors.red,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           // Интерфейс активного звонка
//           if (_isCalling && !_isIncomingCall)
//             Container(
//               padding: EdgeInsets.all(16),
//               color: Colors.blue[50],
//               child: Column(
//                 children: [
//                   Text(
//                     'Звонок: ${_phoneController.text}',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       fontFamily: 'Gilroy',
//                       color: Color(0xff1E2E52),
//                     ),
//                   ),
//                   SizedBox(height: 16),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       AnimatedScaleButton(
//                         child: IconButton(
//                           icon: Icon(_isMuted ? Icons.mic_off : Icons.mic, color: Color(0xff1E2E52)),
//                           onPressed: _toggleMute,
//                         ),
//                       ),
//                       AnimatedScaleButton(
//                         child: IconButton(
//                           icon: Icon(
//                             _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
//                             color: Color(0xff1E2E52),
//                           ),
//                           onPressed: _toggleSpeaker,
//                         ),
//                       ),
//                       AnimatedScaleButton(
//                         child: IconButton(
//                           icon: Icon(Icons.call_end, color: Colors.red),
//                           onPressed: _endCall,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           // Фильтры для журнала звонков
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 ChoiceChip(
//                   label: Text('Все', style: TextStyle(fontFamily: 'Gilroy')),
//                   selected: _selectedFilter == 'all',
//                   onSelected: (selected) {
//                     if (selected) setState(() => _selectedFilter = 'all');
//                   },
//                 ),
//                 ChoiceChip(
//                   label: Text('Исходящие', style: TextStyle(fontFamily: 'Gilroy')),
//                   selected: _selectedFilter == 'outgoing',
//                   onSelected: (selected) {
//                     if (selected) setState(() => _selectedFilter = 'outgoing');
//                   },
//                 ),
//                 ChoiceChip(
//                   label: Text('Входящие', style: TextStyle(fontFamily: 'Gilroy')),
//                   selected: _selectedFilter == 'incoming',
//                   selectedColor: Colors.green[100],
//                   onSelected: (selected) {
//                     if (selected) setState(() => _selectedFilter = 'incoming');
//                   },
//                 ),
//                 ChoiceChip(
//                   label: Text('Пропущенные', style: TextStyle(fontFamily: 'Gilroy')),
//                   selected: _selectedFilter == 'missed',
//                   onSelected: (selected) {
//                     if (selected) setState(() => _selectedFilter = 'missed');
//                   },
//                 ),
//               ],
//             ),
//           ),
//           // Журнал звонков
//           Expanded(
//             child: ListView.builder(
//               itemCount: filteredHistory.length,
//               itemBuilder: (context, index) {
//                 final call = filteredHistory[index];
//                 return ListTile(
//                   leading: Icon(
//                     call.status == 'outgoing'
//                         ? Icons.call_made
//                         : call.status == 'incoming'
//                             ? Icons.call_received
//                             : Icons.call_missed,
//                     color: call.status == 'missed' ? Colors.red : Colors.green,
//                   ),
//                   title: Text(
//                     call.phoneNumber,
//                     style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600),
//                   ),
//                   subtitle: Text(
//                     call.timestamp.toString(),
//                     style: TextStyle(fontFamily: 'Gilroy'),
//                   ),
//                   trailing: IconButton(
//                     icon: Icon(Icons.call, color: Color(0xff1E2E52)),
//                     onPressed: () => _startCall(call.phoneNumber),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Виджет для анимации кнопок
// class AnimatedScaleButton extends StatefulWidget {
//   final Widget child;

//   const AnimatedScaleButton({required this.child, super.key});

//   @override
//   _AnimatedScaleButtonState createState() => _AnimatedScaleButtonState();
// }

// class _AnimatedScaleButtonState extends State<AnimatedScaleButton> with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _scaleAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 100),
//       vsync: this,
//     );
//     _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
//     );
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTapDown: (_) => _controller.forward(),
//       onTapUp: (_) => _controller.reverse(),
//       onTapCancel: () => _controller.reverse(),
//       child: ScaleTransition(
//         scale: _scaleAnimation,
//         child: widget.child,
//       ),
//     );
//   }
// }