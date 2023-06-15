import 'dart:io';

import 'package:darcon/darcon.dart';

void main() async {
  final rcon = RconClient();

  stdout.write('Server IP [localhost]: ');
  var server = stdin.readLineSync();
  if (server == null || server.isEmpty) {
    server = 'localhost';
  }

  stdout.write('Server port [27015]: ');
  var serverPortString = stdin.readLineSync();
  if (serverPortString == null || serverPortString.isEmpty) {
    serverPortString = '';
  }
  final serverPort = int.tryParse(serverPortString) ?? 27015;

  String? password;

  while (password == null) {
    stdout.write('Server Password: ');
    password = stdin.readLineSync();
  }

  try {
    print('Connecting');
    final connected = await rcon.connect(server, serverPort, password);

    if (connected) {
      print('Connected');

      while (rcon.connectionState == RconState.connected) {
        stdout.write('> ');
        final command = stdin.readLineSync();
        if (command != null && command.isNotEmpty) {
          if (command == ':q') {
            break;
          }

          rcon.sendCommand(command);

          await Future.delayed(Duration(milliseconds: 500));
        }
      }
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    rcon.close();
  }
}
