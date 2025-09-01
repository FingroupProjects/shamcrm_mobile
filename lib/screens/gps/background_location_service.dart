import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

class MusicPlayerService {
  static AudioPlayer? _instance;
  static bool _isInitialized = false;
  
  static AudioPlayer get player {
    if (!_isInitialized) {
      _instance = AudioPlayer();
      _isInitialized = true;
    }
    return _instance!;
  }
  
  static void dispose() {
    _instance?.dispose();
    _instance = null;
    _isInitialized = false;
  }
}

class MusicPage extends StatefulWidget {
  const MusicPage({super.key});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> with WidgetsBindingObserver {
  List<Map<String, dynamic>> _songs = [];
  int? _currentIndex;
  bool _isPlaying = false;
  bool _isLoading = true;

  // Используем глобальный плеер
  AudioPlayer get _player => MusicPlayerService.player;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupPlayerListeners();
    _loadSongs();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // НЕ dispose плеер - он должен работать глобально
    super.dispose();
  }

  void _setupPlayerListeners() {
    // Слушаем изменения состояния плеера
    _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });

    // Обработка окончания трека
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed && _currentIndex != null) {
        // Автоматически переходим к следующему треку
        if (_currentIndex! < _songs.length - 1) {
          _playSong(_currentIndex! + 1);
        }
      }
    });
  }

  // Обработка изменений состояния приложения
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Музыка продолжает играть независимо от состояния приложения
    print('App lifecycle changed to: $state');
  }

  Future<void> _loadSongs() async {
    setState(() {
      _isLoading = true;
    });

    // Запрос разрешений для Android 13+
    bool storageGranted = false;
    
    if (Platform.isAndroid) {
      var status = await Permission.audio.request();
      if (status.isGranted) {
        storageGranted = true;
      } else {
        var legacyStatus = await Permission.storage.request();
        if (legacyStatus.isGranted) {
          storageGranted = true;
        }
      }
    } else {
      storageGranted = true;
    }

    if (!storageGranted) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    List<Map<String, dynamic>> tempSongs = [];

    // Попробуем разные пути к музыкальным файлам
    List<String> musicPaths = [
      "/storage/emulated/0/Music",
      "/storage/emulated/0/Download", 
      "/storage/emulated/0/Downloads",
      "/sdcard/Music",
      "/sdcard/Download",
      "/sdcard/Downloads",
    ];

    for (String path in musicPaths) {
      final dir = Directory(path);
      if (await dir.exists()) {
        try {
          final files = dir.listSync(recursive: true);
          
          for (var file in files) {
            if (file is File && 
                (file.path.toLowerCase().endsWith(".mp3") || 
                 file.path.toLowerCase().endsWith(".m4a") ||
                 file.path.toLowerCase().endsWith(".wav") ||
                 file.path.toLowerCase().endsWith(".flac"))) {
              
              String title = file.uri.pathSegments.last;
              String artist = "Unknown Artist";
              
              // Убираем расширение из названия
              if (title.contains('.')) {
                title = title.substring(0, title.lastIndexOf('.'));
              }

              tempSongs.add({
                "file": file,
                "title": title,
                "artist": artist,
                "art": null,
              });
            }
          }
        } catch (e) {
          continue;
        }
      }
    }

    setState(() {
      _songs = tempSongs;
      _isLoading = false;
    });
  }

  // Функция для загрузки обложки по требованию
  Future<Uint8List?> _loadAlbumArt(File file) async {
    try {
      final metadata = await readMetadata(file, getImage: true);
      return metadata.pictures.isNotEmpty ? metadata.pictures.first.bytes : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _playSong(int index) async {
    try {
      final file = _songs[index]["file"] as File;
      
      // Загружаем обложку только при воспроизведении
      if (_songs[index]["art"] == null) {
        final albumArt = await _loadAlbumArt(file);
        if (mounted) {
          setState(() {
            _songs[index]["art"] = albumArt;
          });
        }
      }
      
      await _player.setFilePath(file.path);
      await _player.play();
      
      if (mounted) {
        setState(() {
          _currentIndex = index;
          _isPlaying = true;
        });
      }
    } catch (e) {
      print('Error playing song: $e');
      // Показать ошибку пользователю
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка воспроизведения: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _playPause() async {
    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        await _player.play();
      }
      if (mounted) {
        setState(() {
          _isPlaying = !_isPlaying;
        });
      }
    } catch (e) {
      print('Error toggling playback: $e');
    }
  }

  Future<void> _skipToPrevious() async {
    if (_currentIndex != null && _currentIndex! > 0) {
      await _playSong(_currentIndex! - 1);
    }
  }

  Future<void> _skipToNext() async {
    if (_currentIndex != null && _currentIndex! < _songs.length - 1) {
      await _playSong(_currentIndex! + 1);
    }
  }

  // Метод для полной остановки музыки
  Future<void> _stopMusic() async {
    try {
      await _player.stop();
      if (mounted) {
        setState(() {
          _isPlaying = false;
          // НЕ сбрасываем _currentIndex, чтобы UI показывал последний трек
        });
      }
    } catch (e) {
      print('Error stopping music: $e');
    }
  }

  Widget _buildPlayerUI(Map<String, dynamic> song) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Обложка
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(16),
              ),
              child: song["art"] != null
                  ? Image.memory(
                      song["art"], 
                      height: 200, 
                      width: 200, 
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.music_note, size: 80, color: Colors.white);
                      },
                    )
                  : const Icon(Icons.music_note, size: 80, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          Text(song["title"],
              style: const TextStyle(
                fontFamily: "Gilroy",
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center),
          Text(song["artist"] ?? "Unknown Artist",
              style: const TextStyle(
                fontFamily: "Gilroy",
                fontSize: 14,
                color: Colors.white70,
              )),
          const SizedBox(height: 20),

          // Кнопки управления - используем Material для избежания hero анимаций
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: _currentIndex != null && _currentIndex! > 0 ? _skipToPrevious : null,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.skip_previous, 
                      color: _currentIndex != null && _currentIndex! > 0 ? Colors.white : Colors.grey, 
                      size: 36
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(40),
                  onTap: _playPause,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: _currentIndex != null && _currentIndex! < _songs.length - 1 ? _skipToNext : null,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.skip_next, 
                      color: _currentIndex != null && _currentIndex! < _songs.length - 1 ? Colors.white : Colors.grey, 
                      size: 36
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Кнопка полной остановки
          const SizedBox(height: 15),
          Material(
            color: Colors.red.shade700,
            borderRadius: BorderRadius.circular(25),
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              onTap: _stopMusic,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: const Text(
                  "Остановить музыку",
                  style: TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Переопределяем поведение кнопки назад
      onWillPop: () async {
        Navigator.pop(context);
        return false; // Не даем системе обработать нажатие назад
      },
      child: Scaffold(
        backgroundColor: const Color(0xff111111),
        appBar: AppBar(
          backgroundColor: const Color(0xff111111),
          title: const Text("Музыка", style: TextStyle(fontFamily: "Gilroy", color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          leading: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white))
            : _songs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.music_off, size: 64, color: Colors.white54),
                        const SizedBox(height: 16),
                        const Text(
                          "Музыкальные файлы не найдены", 
                          style: TextStyle(color: Colors.white, fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Проверьте папки Music, Downloads", 
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _loadSongs(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Обновить"),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _songs.length,
                    itemBuilder: (context, index) {
                      final song = _songs[index];
                      final isCurrentSong = _currentIndex == index;
                      
                      return Material(
                        color: isCurrentSong ? Colors.grey.shade900 : Colors.transparent,
                        child: InkWell(
                          onTap: () => _playSong(index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                // Обложка/иконка
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey.shade800,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: song["art"] != null
                                        ? Image.memory(
                                            song["art"], 
                                            width: 50, 
                                            height: 50, 
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Icon(Icons.music_note, color: Colors.white);
                                            },
                                          )
                                        : const Icon(Icons.music_note, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Информация о треке
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        song["title"],
                                        style: TextStyle(
                                          color: isCurrentSong ? Colors.blue : Colors.white, 
                                          fontFamily: "Gilroy",
                                          fontWeight: isCurrentSong ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        song["artist"] ?? "Unknown Artist",
                                        style: const TextStyle(
                                          color: Colors.white70, 
                                          fontFamily: "Gilroy",
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                // Индикатор воспроизведения
                                if (isCurrentSong && _isPlaying)
                                  const Icon(Icons.volume_up, color: Colors.blue, size: 24),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
        bottomNavigationBar: _currentIndex != null
            ? _buildPlayerUI(_songs[_currentIndex!])
            : null,
      ),
    );
  }
}