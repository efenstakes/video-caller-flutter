import 'dart:developer';
import 'package:socket_io_client/socket_io_client.dart';


const String socketUrl = 'wss://d1a6-105-163-2-62.ngrok-free.app';
class SignalService {
  // instance of Socket
  Socket? socket;

  SignalService._();
  static final instance = SignalService._();

  init({required String callerId}) {
    // init Socket
    socket = io(socketUrl, {
      "transports": ['websocket'],
      "query": {"callerId": callerId}
    });

    // listen onConnect event
    socket!.onConnect((data) {
      print("Socket connected !!");
    });

    // listen onConnectError event
    socket!.onConnectError((data) {
      print("Connect Error $data");
    });

    // connect socket
    socket!.connect();
  }
}


void main() {
  SignalService.instance.init(callerId: "Sophia");
  print("done");
}
