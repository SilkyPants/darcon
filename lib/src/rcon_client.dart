import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:darcon/src/rcon_packet.dart';

import 'rcon_packet_type.dart';

enum RconState {
  disconnected,
  connecting,
  authenticating,
  connected,
}

class RconClient {
  late Socket _socket;
  int _requestId = 0;

  final dataBuffer = <int>[];

  RconState _connectionState = RconState.disconnected;
  RconState get connectionState => _connectionState;
  bool get isAuthenticating =>
      _connectionState == RconState.connecting ||
      _connectionState == RconState.authenticating;

  Future<bool> connect(String host, int port, String password) async {
    _connectionState = RconState.connecting;

    _socket = await Socket.connect(host, port);

    _socket.listen(
      // handle data from the client
      _processIncomingData,

      // handle errors
      onError: (error) {
        print('Error: $error');
        close();
      },

      // handle the client closing the connection
      onDone: () {
        print('Client left');
        close();
      },
    );

    _connectionState = RconState.authenticating;
    final packet = RconPacket.login(password: password);
    _socket.add(packet.data);
    await _socket.flush();

    await Future.microtask(() async {
      while (isAuthenticating) {
        await Future.delayed(Duration(milliseconds: 100));
      }
    });

    return connectionState == RconState.connected;
  }

  _processIncomingData(Uint8List data) {
    print('Data Recieved');
    dataBuffer.addAll(data);
    final responses = _readPackets();
    for (var response in responses) {
      print(response);

      if (isAuthenticating &&
          response.type == RconPacketType.authResponse &&
          response.id != -1) {
        _connectionState = RconState.connected;
      }
    }
  }

  Future<void> sendCommand(String command) async {
    final packet = RconPacket.command(
      id: _getNextRequestId(),
      command: command,
    );
    print('Sending packet: $packet');
    _socket.add(packet.data);
    return _socket.flush();
  }

  List<RconPacket> _readPackets() {
    final packets = <RconPacket>[];

    Uint8List.fromList(dataBuffer);

    // Peek the first 4 bytes (this is the packet length)
    var packetLength = bytesToInt(dataBuffer.sublist(0, 4));
    // If this is smaller than our buffer then we have everything
    // for at least one packet
    while ((packetLength + 4) <= dataBuffer.length) {
      // Grab the data and parse
      final packetData = Uint8List.fromList(
        dataBuffer.sublist(0, packetLength + 4),
      );

      final packet = RconPacket.fromData(packetData);
      packets.add(packet);
      // Remove the bytes from the buffer
      dataBuffer.removeRange(0, packetLength + 4);
    }

    return packets;
  }

  final maxRequestId = 0x7fffffff; //2147483647 or half max unsigned int32;
  int _getNextRequestId() {
    _requestId = (_requestId + 1) % maxRequestId;
    return _requestId;
  }

  void close() {
    if (connectionState == RconState.disconnected) return;

    _socket.close();
    _connectionState = RconState.disconnected;
  }
}
