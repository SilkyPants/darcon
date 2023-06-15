import 'dart:typed_data';

import 'rcon_packet_type.dart';

class RconPacket {
  final int id;
  final RconPacketType type;
  final String payload;
  final Uint8List data;

  static final packetMinimumSize = 14;

  const RconPacket._internal({
    required this.id,
    required this.type,
    required this.payload,
    required this.data,
  });

  factory RconPacket.login({
    required String password,
  }) =>
      RconPacket(
        id: 0,
        type: RconPacketType.login,
        payload: password,
      );

  factory RconPacket.command({
    required int id,
    required String command,
  }) =>
      RconPacket(
        id: id,
        type: RconPacketType.command,
        payload: command,
      );

  factory RconPacket({
    required int id,
    required RconPacketType type,
    required String payload,
  }) {
    var payloadLength = payload.length;
    var packetLength = packetMinimumSize + payloadLength;
    var packetData = Uint8List(packetLength);

    packetData.setRange(0, 4, _intToBytes(packetLength - 4));
    packetData.setRange(4, 8, _intToBytes(id));
    packetData.setRange(8, 12, _intToBytes(type.rawValue));
    packetData.setRange(12, packetLength - 2, payload.codeUnits);
    packetData.setRange(packetLength - 2, packetLength, [0, 0]);

    return RconPacket._internal(
      id: id,
      type: type,
      payload: payload,
      data: packetData,
    );
  }

  factory RconPacket.fromData(Uint8List data) {
    var packetLength = bytesToInt(data.sublist(0, 4));
    var packetId = bytesToInt(data.sublist(4, 8));
    var packetType = bytesToInt(data.sublist(8, 12));
    var payload =
        packetLength > 10 ? String.fromCharCodes(data.sublist(12)) : '';

    return RconPacket._internal(
      id: packetId,
      type: RconPacketType.fromInt(packetType),
      payload: payload,
      data: data,
    );
  }

  @override
  String toString() {
    return '($id) $type Payload\n"$payload"\n\n$data';
  }
}

Uint8List _intToBytes(int value) {
  var byteData = ByteData(4);
  byteData.setUint32(0, value, Endian.little);
  return byteData.buffer.asUint8List();
}

int bytesToInt(List<int> bytes) {
  var byteData = Uint8List.fromList(bytes);
  return ByteData.view(byteData.buffer).getInt32(0, Endian.little);
}
