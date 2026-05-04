import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:sip_ua/src/transports/socket_interface.dart';

import '../logger.dart';

class SIPUAUdpSocket extends SIPUASocketInterface {
  SIPUAUdpSocket(String host, String port,
      {required int messageDelay, int? weight})
      : _host = host,
        _port = port,
        _messageDelay = messageDelay,
        _weight = weight {
    logger.d('new() [host:$host:$port]');
    _sipUri = 'sip:$host:$port;transport=udp';
    _viaTransport = 'UDP';
  }

  final String _host;
  final String _port;
  final int _messageDelay;
  final int? _weight;

  RawDatagramSocket? _socket;
  bool _closed = false;
  bool _connected = false;
  bool _connecting = false;
  String _viaTransport = 'UDP';
  String? _sipUri;
  InternetAddress? _remoteAddress;
  int? _remotePort;
  StreamSubscription<dynamic>? _socketSubscription;
  final StreamController<dynamic> _queue =
      StreamController<dynamic>.broadcast();
  StreamSubscription<dynamic>? _queueSubscription;

  @override
  String get via_transport => _viaTransport;

  @override
  set via_transport(String value) {
    _viaTransport = value.toUpperCase();
  }

  @override
  int? get weight => _weight;

  @override
  String? get sip_uri => _sipUri;

  @override
  String? get url => '$_host:$_port';

  @override
  void connect() async {
    logger.d('connect()');

    if (isConnected()) {
      logger.d('UdpSocket $_host:$_port is already connected');
      return;
    } else if (isConnecting()) {
      logger.d('UdpSocket $_host:$_port is connecting');
      return;
    }

    _connecting = true;
    _closed = false;

    try {
      final addresses = await InternetAddress.lookup(_host);
      if (addresses.isEmpty) {
        throw SocketException('Host lookup returned no addresses for $_host');
      }
      _remoteAddress = addresses.first;
      _remotePort = int.parse(_port);

      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _socket!.broadcastEnabled = true;
      _socket!.writeEventsEnabled = true;
      _socket!.readEventsEnabled = true;

      _socketSubscription = _socket!.listen(
        (event) {
          if (event == RawSocketEvent.read) {
            final datagram = _socket!.receive();
            if (datagram == null) return;
            _onMessage(datagram.data);
            return;
          }

          if (event == RawSocketEvent.closed) {
            _connected = false;
            _connecting = false;
            _onClose(true, 0, 'UDP socket closed');
          }
        },
        onError: (Object error) {
          _connected = false;
          _connecting = false;
          _onClose(false, 500, error.toString());
        },
      );

      _startQueue();

      _connected = true;
      _connecting = false;
      _onOpen();
    } catch (e, s) {
      logger.e(e.toString(), error: e, stackTrace: s);
      _connected = false;
      _connecting = false;
      _onClose(false, 500, e.toString());
    }
  }

  void _startQueue() {
    _queueSubscription?.cancel();
    _queueSubscription = _queue.stream.asyncMap((event) async {
      await Future<void>.delayed(Duration(milliseconds: _messageDelay));
      return event;
    }).listen((event) {
      final socket = _socket;
      final remoteAddress = _remoteAddress;
      final remotePort = _remotePort;
      if (socket == null || remoteAddress == null || remotePort == null) return;

      final message = event.toString();
      socket.send(utf8.encode(message), remoteAddress, remotePort);
      logger.d('send:\n\n$message');
    });
  }

  @override
  void disconnect() {
    logger.d('disconnect()');
    if (_closed) return;

    _closed = true;
    _connected = false;
    _connecting = false;

    _queueSubscription?.cancel();
    _socketSubscription?.cancel();
    _socket?.close();
    _socket = null;

    _onClose(true, 0, 'Client send disconnect');
  }

  @override
  bool send(dynamic message) {
    logger.d('send()');
    if (_closed) {
      throw 'transport closed';
    }
    _queue.add(message);
    return true;
  }

  @override
  bool isConnected() => _connected;

  @override
  bool isConnecting() => _connecting;

  void _onOpen() {
    logger.d('UdpSocket $_host:$_port connected');
    onconnect?.call();
  }

  void _onClose(bool wasClean, int? code, String? reason) {
    logger.d('UdpSocket $_host:$_port closed');
    ondisconnect?.call(this, !wasClean, code, reason);
  }

  void _onMessage(Uint8List data) {
    if (data.isEmpty) return;
    ondata?.call(data);
  }
}
