import 'dart:async';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: TransmissionApp(),
    );
  }
}

class TransmissionApp extends StatefulWidget {
  const TransmissionApp({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _TransmissionAppState createState() => _TransmissionAppState();
}

class _TransmissionAppState extends State<TransmissionApp> {
  String preamble = "10101010";
  String message = "Hola Mundo";
  String bitText = "";
  int bitIndex = 0;
  bool isTransmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transmisión OOK'),
      ),
      body: GestureDetector(
        onTap: () {
          setState(() {
            isTransmitting = !isTransmitting;
            bitIndex = 0;
          });
          _startTransmission();
        },
        child: Container(
          color: isTransmitting ? Colors.white : Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  message.substring(0, (bitIndex / 8).floor() + 1),
                  style: TextStyle(
                    color: isTransmitting ? Colors.purple : Colors.purple,
                    fontSize: 32,
                  ),
                ),
                Text(
                  bitText,
                  style: TextStyle(
                    color: isTransmitting ? Colors.purple : Colors.purple,
                    fontSize: 32,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startTransmission() {
    if (isTransmitting) {
      _sendPreamble();

      Timer.periodic(const Duration(milliseconds: 250), (timer) {
        int bit = (message.codeUnitAt(bitIndex ~/ 8) >> (7 - bitIndex % 8)) & 1;
        if (bitText.length % 9 == 0) {
          bitText += "\n";
        }
        bitText += bit.toString();
        print(bit);
        bitIndex++;

        setState(() {
          if (bit == 1) {
            isTransmitting = true;
          } else {
            isTransmitting = false;
          }
        });

        if (bitIndex == message.length * 8 - 1) {
          timer.cancel();
          setState(() {
            isTransmitting = false;
          });
        }
      });
    }
  }

  void _sendPreamble() {
    for (int i = 0; i < preamble.length; i++) {
      int bit = int.parse(preamble[i]);
      setState(() {
        isTransmitting = bit == 1;
      });
      print('Enviando preámbulo: $isTransmitting');
      Future.delayed(const Duration(milliseconds: 50), () {});
    }
  }
}
