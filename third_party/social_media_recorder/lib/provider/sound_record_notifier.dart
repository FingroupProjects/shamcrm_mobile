import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:social_media_recorder/audio_encoder_type.dart';

class SoundRecordNotifier extends ChangeNotifier {
  int _counter = 0;
  int _localCounterForMaxRecordTime = 0;
  GlobalKey key = GlobalKey();
  int? maxRecordTime;

  /// This Timer Just For wait about 1 second until starting record
  Timer? _timer;

  /// This time for counter wait about 1 send to increase counter
  Timer? _timerCounter;

  StreamSubscription<Amplitude>? _amplitudeSub;

  /// Use last to check where the last draggable in X
  double last = 0;

  /// Used when user enter the needed path
  String initialStorePathRecord = "";

  /// recording mp3 sound Object
  AudioRecorder recordMp3 = AudioRecorder();

  /// recording mp3 sound to check if all permisiion passed
  bool _isAcceptedPermission = false;

  /// used to update state when user draggable to the top state
  double currentButtonHeihtPlace = 0;

  /// used to know if isLocked recording make the object true
  /// else make the object isLocked false
  bool isLocked = false;

  /// when pressed in the recording mic button convert change state to true
  /// else still false
  bool isShow = false;

  /// to show second of recording
  late int second;

  /// to show minute of recording
  late int minute;

  /// to know if pressed the button
  late bool buttonPressed;

  /// used to update space when dragg the button to left
  late double edge;
  late bool loopActive;

  /// store final path where user need store mp3 record
  late bool startRecord;

  /// store the value we draggble to the top
  late double heightPosition;

  /// store status of record if lock change to true else
  /// false
  late bool lockScreenRecord;
  late String mPath;

  /// Normalized mic levels 0..1 for live waveform (oldest → newest).
  final List<double> amplitudeSamples = <double>[];

  /// Latest normalized amplitude 0..1.
  double currentAmplitude = 0;

  static const int maxAmplitudeSamples = 56;

  /// function called when start recording
  Function()? startRecording;
  Function(File soundFile, String time) sendRequestFunction;

  /// function called when stop recording, return the recording time (even if time < 1)
  Function(String time)? stopRecording;

  late AudioEncoderType encode;

  /// Bumped whenever a record attempt is started or cancelled so in-flight
  /// async work from a previous tap cannot start/stop the next session.
  int _recordSession = 0;

  bool _disposed = false;

  bool get _isDisposed => _disposed;

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _recordSession++;
    _timer?.cancel();
    _timer = null;
    _timerCounter?.cancel();
    _timerCounter = null;
    _amplitudeSub?.cancel();
    _amplitudeSub = null;
    _clearAmplitude();
    try {
      recordMp3.dispose();
    } catch (_) {}
    super.dispose();
  }

  SoundRecordNotifier({
    required this.stopRecording,
    required this.sendRequestFunction,
    required this.startRecording,
    this.edge = 0.0,
    this.minute = 0,
    this.second = 0,
    this.buttonPressed = false,
    this.loopActive = false,
    this.mPath = '',
    this.startRecord = false,
    this.heightPosition = 0,
    this.lockScreenRecord = false,
    this.encode = AudioEncoderType.AAC,
    this.maxRecordTime,
  });

  /// Map dBFS (−160…0) into a perceptually useful 0…1 bar height.
  static double normalizeDb(double dbfs) {
    const minDb = -52.0;
    const maxDb = -2.0;
    final clamped = dbfs.clamp(minDb, maxDb);
    final linear = (clamped - minDb) / (maxDb - minDb);
    // Mild curve so quiet speech still moves, loud peaks stretch tall.
    return math.pow(linear.clamp(0.0, 1.0), 0.72).toDouble();
  }

  void _pushAmplitude(double normalized) {
    if (_isDisposed) return;
    currentAmplitude = normalized;
    amplitudeSamples.add(normalized);
    while (amplitudeSamples.length > maxAmplitudeSamples) {
      amplitudeSamples.removeAt(0);
    }
    notifyListeners();
  }

  void _clearAmplitude() {
    amplitudeSamples.clear();
    currentAmplitude = 0;
  }

  Future<void> _stopAmplitudeListening() async {
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    _clearAmplitude();
  }

  void _startAmplitudeListening() {
    if (_isDisposed) return;
    _amplitudeSub?.cancel();
    _amplitudeSub = recordMp3
        .onAmplitudeChanged(const Duration(milliseconds: 50))
        .listen((Amplitude amp) {
      if (_isDisposed || !buttonPressed) return;
      _pushAmplitude(normalizeDb(amp.current));
    }, onError: (_) {});
  }

  /// To increase counter after 1 sencond
  void _mapCounterGenerater() {
    if (_isDisposed) return;
    _timerCounter = Timer(const Duration(seconds: 1), () {
      if (_isDisposed) return;
      _increaseCounterWhilePressed();
      if (buttonPressed) _mapCounterGenerater();
    });
  }

  finishRecording() {
    if (_isDisposed) return;
    final time = '$minute:$second';
    if (buttonPressed && (second > 1 || minute > 0) && mPath.isNotEmpty) {
      sendRequestFunction(File.fromUri(Uri(path: mPath)), time);
    }
    // Always notify the host. Short taps / aborted starts used to skip this
    // and leave the chat input bar hidden (_voicePressed stuck true).
    stopRecording?.call(time);
    resetEdgePadding();
  }

  /// used to reset all value to initial value when end the record
  resetEdgePadding() async {
    if (_isDisposed) return;
    final session = ++_recordSession;
    if (_initWidth == -33) {
      final ctx = key.currentContext;
      if (ctx != null) {
        final box = ctx.findRenderObject() as RenderBox?;
        if (box != null) {
          final position = box.localToGlobal(Offset.zero);
          _initWidth = position.dx;
        }
      }
    }
    _localCounterForMaxRecordTime = 0;
    isLocked = false;
    edge = 0;
    buttonPressed = false;
    second = 0;
    minute = 0;
    isShow = false;
    key = GlobalKey();
    heightPosition = 0;
    lockScreenRecord = false;
    _timer?.cancel();
    _timer = null;
    _timerCounter?.cancel();
    _timerCounter = null;
    await _stopAmplitudeListening();
    if (_isDisposed || session != _recordSession) {
      return;
    }
    try {
      final value = await recordMp3.isRecording();
      if (_isDisposed || session != _recordSession) {
        return;
      }
      if (value == true) {
        await recordMp3.stop();
        if (_isDisposed || session != _recordSession) {
          return;
        }
        recordMp3 = AudioRecorder();
      }
    } catch (_) {}
    notifyListeners();
  }

  String _getSoundExtention() {
    if (encode == AudioEncoderType.AAC ||
        encode == AudioEncoderType.AAC_LD ||
        encode == AudioEncoderType.AAC_HE ||
        encode == AudioEncoderType.OPUS) {
      return ".m4a";
    } else {
      return ".3gp";
    }
  }

  /// used to get the current store path
  Future<String> getFilePath() async {
    Directory tempDir = await getTemporaryDirectory();
    final sdPath =
        initialStorePathRecord.isEmpty ? tempDir.path : initialStorePathRecord;
    var d = Directory(sdPath);
    if (!d.existsSync()) {
      d.createSync(recursive: true);
    }
    DateTime now = DateTime.now();
    String convertedDateTime =
        "${_counter.toString()}${now.year.toString()}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    _counter++;
    String storagePath = "$sdPath/$convertedDateTime${_getSoundExtention()}";
    mPath = storagePath;
    return storagePath;
  }

  /// used to change the draggable to top value
  setNewInitialDraggableHeight(double newValue) {
    currentButtonHeihtPlace = newValue;
  }

  double _initWidth = -33;

  /// used to change the draggable to top value
  /// or To The X vertical
  /// and update this value in screen
  updateScrollValue(Offset currentValue, BuildContext context) async {
    if (_isDisposed) return;
    if (buttonPressed == true) {
      final x = currentValue;

      double hightValue = currentButtonHeihtPlace - x.dy;

      if (hightValue >= 50) {
        isLocked = true;
        lockScreenRecord = true;
        hightValue = 50;
        notifyListeners();
      }
      if (hightValue < 0) hightValue = 0;
      heightPosition = hightValue;
      lockScreenRecord = isLocked;
      notifyListeners();

      try {
        RenderBox box = key.currentContext?.findRenderObject() as RenderBox;
        Offset position = box.localToGlobal(Offset.zero);
        if (position.dx <= MediaQuery.of(context).size.width * 0.6) {
          String time = '$minute:$second';
          if (stopRecording != null) stopRecording!(time);
          resetEdgePadding();
        } else if (x.dx >= MediaQuery.of(context).size.width) {
          edge = 0;
        } else {
          edge = (_initWidth - x.dx) > 0 ? (_initWidth - x.dx) : 0;
        }
        // ignore: empty_catches
      } catch (e) {}
      notifyListeners();
    }
  }

  _increaseCounterWhilePressed() async {
    if (_isDisposed || loopActive) {
      return;
    }

    loopActive = true;
    if (maxRecordTime != null) {
      if (_localCounterForMaxRecordTime >= maxRecordTime!) {
        loopActive = false;
        finishRecording();
      }
      _localCounterForMaxRecordTime++;
    }
    second = second + 1;
    buttonPressed = buttonPressed;
    if (second == 60) {
      second = 0;
      minute = minute + 1;
    }

    notifyListeners();
    loopActive = false;
    notifyListeners();
  }

  /// this function to start record voice
  record(Function()? startRecord) async {
    if (_isDisposed) return;
    final session = ++_recordSession;
    if (!_isAcceptedPermission) {
      await Permission.microphone.request();
      await Permission.manageExternalStorage.request();
      await Permission.storage.request();
      if (_isDisposed || session != _recordSession) {
        return;
      }
      _isAcceptedPermission = true;
      notifyListeners();
      return;
    }

    buttonPressed = true;
    isShow = true;
    _clearAmplitude();
    startRecord?.call();
    notifyListeners();

    final String recordFilePath = await getFilePath();
    if (_isDisposed || session != _recordSession) {
      return;
    }
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 250), () async {
      if (_isDisposed || session != _recordSession) {
        return;
      }
      try {
        await recordMp3.start(const RecordConfig(), path: recordFilePath);
        if (_isDisposed || session != _recordSession) {
          try {
            await recordMp3.stop();
          } catch (_) {}
          return;
        }
        _startAmplitudeListening();
      } catch (_) {
        // Keep UI alive even if start fails on a transient race.
      }
    });

    _mapCounterGenerater();
    notifyListeners();
  }

  /// to check permission
  voidInitialSound() async {
    startRecord = false;
    final status = await Permission.microphone.status;
    if (status.isGranted) {
      if (Platform.isIOS) {
        _isAcceptedPermission = true;
        return;
      }
      final result = await Permission.storage.request();
      if (result.isGranted) {
        _isAcceptedPermission = true;
      }
    }
  }
}
