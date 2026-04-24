import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/constants/api_config.dart';
import '../models/ws_event.dart';

final websocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService();
});

class WebSocketService {
  WebSocketChannel? _channel;
  final _eventController = StreamController<WsEvent>.broadcast();
  int? _partyId;
  String? _playerUUID;
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;
  static const _maxReconnectAttempts = 5;

  Stream<WsEvent> get events => _eventController.stream;

  void connect(int partyId, String playerUUID) {
    _partyId = partyId;
    _playerUUID = playerUUID;
    _shouldReconnect = true;
    _reconnectAttempts = 0;
    _connect();
  }

  void _connect() {
    final url = '$wsBaseUrl/party/$_partyId/ws?player_uuid=$_playerUUID';
    _channel = WebSocketChannel.connect(Uri.parse(url));

    _channel!.stream.listen(
      (data) {
        _reconnectAttempts = 0; // Reset bei erfolgreicher Nachricht
        try {
          final json = jsonDecode(data as String);
          final event = WsEvent.fromJson(json);
          _eventController.add(event);
        } catch (_) {
          // ignore parse errors
        }
      },
      onDone: () {
        if (_shouldReconnect) _scheduleReconnect();
      },
      onError: (_) {
        if (_shouldReconnect) _scheduleReconnect();
      },
    );
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) return;
    _reconnectAttempts++;

    // Exponential backoff: 1s, 2s, 4s, 8s, 16s
    final delay = Duration(seconds: 1 << (_reconnectAttempts - 1));
    Future.delayed(delay, () {
      if (_shouldReconnect) _connect();
    });
  }

  void disconnect() {
    _shouldReconnect = false;
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _eventController.close();
  }
}
