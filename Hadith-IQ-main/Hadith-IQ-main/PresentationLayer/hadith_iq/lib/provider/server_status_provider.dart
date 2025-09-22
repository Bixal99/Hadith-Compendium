import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hadith_iq/config/app_config.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class ServerStatusProvider with ChangeNotifier {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _isOnline = false;
  bool get isOnline => _isOnline;

  Timer? _reconnectTimer;
  bool _isConnecting = false; // prevent multiple reconnects

  ServerStatusProvider() {
    _connectWebSocket();
  }

  void _connectWebSocket() async {
    if (_isConnecting) return;
    _isConnecting = true;

    try {
      final uri = Uri.parse(AppConfig.webSocketUrl);

      // Connect safely inside try-catch
      final tempChannel = WebSocketChannel.connect(uri);

      // Listen with guarded error handling
      _subscription = tempChannel.stream.listen(
        (message) {
          try {
            final data = json.decode(message);
            final newStatus = data['status'] == 'online';
            if (newStatus != _isOnline) {
              _isOnline = newStatus;
              notifyListeners();
            }
          } catch (e) {
            debugPrint('Error parsing WS message: $e');
          }
        },
        onError: (error) {
          debugPrint("WebSocket error: $error");
          _handleDisconnect();
        },
        onDone: () {
          debugPrint("WebSocket closed");
          _handleDisconnect();
        },
        cancelOnError: true,
      );

      _channel = tempChannel;
    } catch (e, stack) {
      debugPrint('WebSocket connection failed: $e');
      debugPrint(stack.toString());
      _handleDisconnect();
    } finally {
      _isConnecting = false;
    }
  }

  void _handleDisconnect() {
    if (_isOnline) {
      _isOnline = false;
      notifyListeners();
    }

    try {
      _subscription?.cancel();
    } catch (e) {
      debugPrint("Error canceling subscription: $e");
    }
    _subscription = null;

    try {
      _channel?.sink.close(status.goingAway);
    } catch (e) {
      debugPrint("Error closing WebSocket channel: $e");
    }
    _channel = null;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), _connectWebSocket);
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    try {
      _channel?.sink.close(status.goingAway);
    } catch (e) {
      debugPrint("Error closing channel during dispose: $e");
    }
    super.dispose();
  }
}
