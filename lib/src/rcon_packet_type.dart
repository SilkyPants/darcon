enum RconPacketType {
  responseValue(0),
  command(2),
  authResponse(2),
  login(3);

  const RconPacketType(this.rawValue);
  final int rawValue;

  factory RconPacketType.fromInt(int value) {
    return RconPacketType.values[value];
  }
}
