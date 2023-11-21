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
  _TransmissionAppState createState() => _TransmissionAppState();
}

class _TransmissionAppState extends State<TransmissionApp> {
  String message = "Hola mundo";
  int bitIndex = 0;
  String bitString = "";
  bool bit = false;
  String preamble = '10101010';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transmisión de Bits'),
      ),
      body: GestureDetector(
        onTap: () async {
          _startTransmission();
        },
        child: Container(
          color: bit ? Colors.white : Colors.black,
          child: Center(
            child: Text(
              bitString,
              style: const TextStyle(
                color: Colors.purple,
                fontSize: 32,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _startTransmission() {
    bitIndex = 0;
    for (int i = 0; i < preamble.length; i++) {
      int bitAux = int.parse(preamble[i]);
      setState(() {
        if (bitAux == 1) {
          bit = true;
        } else {
          bit = false;
        }
      });
      print('Enviando preámbulo: $bit');
      Future.delayed(const Duration(milliseconds: 50), () {});
    }

    _transmitNextBit();
  }

  void _transmitNextBit() {
    if (bit && bitIndex < message.length * 8) {
      int bit = _getBit(bitIndex);
      setState(() {
        bitString += bit.toString();
        if ((bitIndex + 1) % 8 == 0 && bitIndex < message.length * 8 - 1) {
          bitString += " ";
        }
      });
      bitIndex++;
      Future.delayed(const Duration(milliseconds: 250), _transmitNextBit);
    } else {
      setState(() {
        bit = false;
      });
    }
  }

  int _getBit(int index) {
    int charIndex = index ~/ 8;
    int charBitIndex = index % 8;
    if (charIndex < message.length) {
      int charCode = message.codeUnitAt(charIndex);
      return (charCode >> (7 - charBitIndex)) & 1;
    }
    return 0;
  }
}
