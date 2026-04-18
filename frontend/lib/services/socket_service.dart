import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static const String socketUrl = 'https://rentit-kappa.vercel.app';

  IO.Socket? _socket;
  Function(dynamic)? onNotification;

  void connect(String userId) {
    _socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.connect();

    _socket!.onConnect((_) {
      _socket!.emit('join', userId);
    });

    _socket!.on('notification', (data) {
      onNotification?.call(data);
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
