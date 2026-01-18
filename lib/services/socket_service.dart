import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/constants.dart';

class SocketService {
  late IO.Socket socket;
  Function(dynamic)? onKioskLinked;

  void initSocket(String deviceId) {
    socket = IO.io(AppConstants.socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      print('Connected to Socket.io server');
      // Join room for this specific device
      socket.emit('join-device', deviceId); // Backend expects 'join-device' and plain string or body
    });

    socket.onDisconnect((_) => print('Disconnected from Socket.io server'));

    socket.on('kiosk-linked', (data) {
      print('Received kiosk-linked event: $data');
      if (onKioskLinked != null) {
        onKioskLinked!(data);
      }
    });
  }

  void dispose() {
    socket.disconnect();
    socket.dispose();
  }
}
