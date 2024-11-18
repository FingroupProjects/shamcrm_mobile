// import 'dart:io';
// import 'package:just_audio/just_audio.dart';

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
