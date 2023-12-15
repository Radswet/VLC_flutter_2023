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
  State<TransmissionApp> createState() => _TransmissionAppState();
}

class _TransmissionAppState extends State<TransmissionApp> {
  String preamble = "10101010";
  String message = "ªHola Mundo";
  String bitText = "";
  int bitIndex = 0;
  bool isTransmitting = false;
  bool bitColor = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transmisión OOK'),
      ),
      body: GestureDetector(
        onTap: () {
          if (isTransmitting) {
            isTransmitting = false;
            bitText = "";
            bitIndex = 0;
          }
          _startTransmission();
        },
        child: Container(
          color: bitColor ? Colors.white : Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  message.substring(
                      0, (bitIndex ~/ 8).clamp(0, message.length - 1) + 1),
                  style: TextStyle(
                    color: bitColor ? Colors.purple : Colors.purple,
                    fontSize: 32,
                  ),
                ),
                Text(
                  bitText,
                  style: TextStyle(
                    color: bitColor ? Colors.purple : Colors.purple,
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
    isTransmitting = true;
    Timer.periodic(const Duration(milliseconds: 1000), (Timer timer2) {
      if (bitIndex % 8 == 0 && bitIndex > 0) {
        bitText += "\n";
      }

      int bit = (message.codeUnitAt(bitIndex ~/ 8) >> (7 - bitIndex % 8)) & 1;
      bitText += bit.toString();
      bitIndex++;

      setState(() {
        if (bit == 1) {
          bitColor = true;
        } else {
          bitColor = false;
        }
      });

      if (bitIndex >= message.length * 8) {
        timer2.cancel();
        setState(() {
          bitColor = false;
        });
      }
    });
  }
}
