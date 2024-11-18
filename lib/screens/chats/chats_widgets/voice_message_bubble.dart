// import 'package:flutter/material.dart';
// import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
// import 'package:audio_waveforms/audio_waveforms.dart';

// class VoiceMessageBubble extends StatefulWidget {
//   final String time;
//   final bool isSender;
//   final String filePath;

//   const VoiceMessageBubble({
//     Key? key,
//     required this.time,
//     required this.isSender,
//     required this.filePath,
//   }) : super(key: key);

//   @override
//   _VoiceMessageBubbleState createState() => _VoiceMessageBubbleState();
// }

// class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
//   late PlayerController _playerController;
//   bool isPlaying = false;

//   final String baseUrl = 'https://shamcrm.com/storage/';

//   @override
//   void initState() {
//     super.initState();
//     _playerController = PlayerController();
//     _preparePlayer();
//   }

//   Future<void> _preparePlayer() async {
//     try {
//       final String url = '$baseUrl${widget.filePath}';
//       print('Путь к файлу: $url');

//       await _playerController.preparePlayer(
//         path: url,
//         shouldExtractWaveform: true,
//       );

//       print('Плеер успешно инициализирован.');
//     } catch (e) {
//       print('Ошибка при инициализации плеера: $e');
//     }
//   }

//   @override
//   void dispose() {
//     _playerController.dispose();
//     super.dispose();
//   }

//   void _togglePlayPause() async {
//     try {
//       if (isPlaying) {
//         await _playerController.pausePlayer();
//       } else {
//         await _playerController.startPlayer(finishMode: FinishMode.pause);
//       }
//       setState(() {
//         isPlaying = !isPlaying;
//       });
//     } catch (e) {
//       print('Ошибка воспроизведения: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Align(
//       alignment: widget.isSender ? Alignment.centerRight : Alignment.centerLeft,
//       child: Column(
//         crossAxisAlignment: widget.isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//         children: [
//           GestureDetector(
//             onTap: _togglePlayPause,
//             child: Container(
//               margin: const EdgeInsets.symmetric(vertical: 5),
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: widget.isSender
//                     ? ChatSmsStyles.messageBubbleSenderColor
//                     : ChatSmsStyles.messageBubbleReceiverColor,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(
//                     isPlaying ? Icons.pause : Icons.play_arrow,
//                     color: widget.isSender ? Colors.white : Colors.black,
//                   ),
//                   const SizedBox(width: 10),
//                   AudioFileWaveforms(
//                     size: const Size(150, 50),
//                     playerController: _playerController,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           Text(
//             widget.time,
//             style: const TextStyle(
//               fontSize: 12,
//               color: ChatSmsStyles.appBarTitleColor,
//               fontWeight: FontWeight.w400,
//               fontFamily: 'Gilroy',
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }








// ElevatedButton(
//   onPressed: () {
//     final audioPlayer = AudioPlayerExample();
//     audioPlayer.playAudio('http://62.84.186.96/storage/chat/files/q9c459xdjfYqOVvv3j8ivM3OSdlB90k6HGfMYhKc.mp3');
//   },
//   child: Text('Play Audio'),
// )
// class AudioPlayerExample {
//   final AudioPlayer player = AudioPlayer();

//   Future<void> playAudio(String url) async {
//     // Проверяем, является ли url локальным файлом или удаленным URL
//     if (url.startsWith('http://') || url.startsWith('https://')) {
//       // Если это URL, воспроизводим его сразу
//       await player.setUrl(url);
//       await player.play();
//     } else {
//       // Если это локальный файл, проверяем его существование
//       final file = File(url);
//       if (await file.exists()) {
//         await player.setUrl(url);
//         await player.play();
//       } else {
//         print('Файл не найден: $url');
//       }
//     }
//   }
// }




















// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
// import 'package:audio_waveforms/audio_waveforms.dart';
// import 'package:just_audio/just_audio.dart';

// class VoiceMessageBubble extends StatefulWidget {
//   final String time;
//   final bool isSender;
//   final String filePath;

//   const VoiceMessageBubble({
//     Key? key,
//     required this.time,
//     required this.isSender,
//     required this.filePath,
//   }) : super(key: key);

//   @override
//   _VoiceMessageBubbleState createState() => _VoiceMessageBubbleState();
// }

// class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
//   late PlayerController _playerController;
//   final AudioPlayerExample _audioPlayerExample = AudioPlayerExample(); // Создаем экземпляр AudioPlayerExample
//   bool isPlaying = false;

//   // Базовый URL для доступа к аудиофайлам
//   final String baseUrl = 'http://62.84.186.96/storage/';

//   @override
//   void initState() {
//     super.initState();
//     _playerController = PlayerController();
//     print('Инициализация плеера...');
//     _preparePlayer();
//   }

//   Future<void> _preparePlayer() async {
//     try {
//       print('Инициализация плеера...');
//       final String url = '$baseUrl${widget.filePath}';
//       print('Путь к файлу: $url');

//       await _playerController.preparePlayer(
//         path: url, // Убедитесь, что передаете сетевой URL
//         shouldExtractWaveform: true,
//       );

//       print('Плеер успешно инициализирован.');
//     } catch (e) {
//       print('Ошибка при инициализации плеера: $e');
//     }
//   }

//   @override
//   void dispose() {
//     print('Освобождение ресурсов плеера...');
//     _playerController.dispose();
//     super.dispose();
//   }

//   void _togglePlayPause() async {
//     try {
//       print('Проверка статуса воспроизведения...'); // Лог статуса воспроизведения
//       if (isPlaying) {
//         print('Приостановка воспроизведения...');
//         await _audioPlayerExample.player.pause();
//       } else {
//         print('Начало воспроизведения...');
//         await _audioPlayerExample.playAudio('$baseUrl${widget.filePath}'); // Используем baseUrl и filePath
//       }
//       setState(() {
//         isPlaying = !isPlaying;
//       });
//       print('Статус воспроизведения изменен на: ${isPlaying ? "воспроизведение" : "приостановлено"}');
//     } catch (e) {
//       print('Ошибка воспроизведения: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Align(
//       alignment: widget.isSender ? Alignment.centerRight : Alignment.centerLeft,
//       child: Column(
//         crossAxisAlignment: widget.isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//         children: [
//           GestureDetector(
//             onTap: _togglePlayPause,
//             child: Container(
//               margin: const EdgeInsets.symmetric(vertical: 5),
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: widget.isSender
//                     ? ChatSmsStyles.messageBubbleSenderColor
//                     : ChatSmsStyles.messageBubbleReceiverColor,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(
//                     isPlaying ? Icons.pause : Icons.play_arrow,
//                     color: widget.isSender ? Colors.white : Colors.black,
//                   ),
//                   SizedBox(width: 10),
//                   AudioFileWaveforms(
//                     size: Size(150, 50),
//                     playerController: _playerController,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           Text(
//             widget.time,
//             style: const TextStyle(
//               fontSize: 12,
//               color: ChatSmsStyles.appBarTitleColor,
//               fontWeight: FontWeight.w400,
//               fontFamily: 'Gilroy',
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class AudioPlayerExample {
//   final AudioPlayer player = AudioPlayer();

//   Future<void> playAudio(String url) async {
//     // Проверяем, является ли url локальным файлом или удаленным URL
//     if (url.startsWith('http://') || url.startsWith('https://')) {
//       // Если это URL, воспроизводим его сразу
//       await player.setUrl(url);
//       await player.play();
//     } else {
//       // Если это локальный файл, проверяем его существование
//       final file = File(url);
//       if (await file.exists()) {
//         await player.setUrl(url);
//         await player.play();
//       } else {
//         print('Файл не найден: $url');
//       }
//     }
//   }
// }
