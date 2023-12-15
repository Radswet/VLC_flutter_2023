import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CameraApp(),
    );
  }
}

class CameraApp extends StatefulWidget {
  const CameraApp({Key? key}) : super(key: key);

  @override
  State<CameraApp> createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  late CameraController _controller;
  List<int> bits = [];
  bool receivingData = false;
  String receivedText = '';
  String luminanceText = '';

  bool preambleOk = false;
  int inter = 1000;
  late StreamController<CameraImage> _imageStreamController;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.first;

    _controller = CameraController(
      camera,
      ResolutionPreset.low,
      enableAudio: false,
    );

    await _controller.initialize();

    _controller.setExposureMode(ExposureMode.auto);
    _imageStreamController = StreamController<CameraImage>.broadcast();

    _controller.startImageStream((CameraImage image) {
      _imageStreamController.add(image);
    });

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  void _startImageProcessing() {
    int contador = 0;
    Duration interval =
        Duration(milliseconds: inter); // Intervalo de un segundo
    Stopwatch stopwatch = Stopwatch()..start(); // Inicia el cronómetro

    int preambleaCount = 0;

    int auxluminance = 0;
    int preambleAux = 0;

    _imageStreamController.stream.listen((CameraImage image) {
      if (preambleOk) {
        if (stopwatch.elapsed >= interval) {
          int sum = 0;
          for (int i = 0; i < image.planes[0].bytes.length; i++) {
            sum += image.planes[0].bytes[i];
          }
          int luminance = sum ~/ image.planes[0].bytes.length;
          luminanceText = 'Luminancia actual: $luminance';
          bits.add(luminance > 140 ? 1 : 0);

          setState(() {
            luminanceText = 'Luminancia actual: $luminance';
            receivingData = true;
          });

          if (bits.length >= 8) {
            _processCapturedBits();
            interval = Duration(milliseconds: inter - 10);
            contador++;
            if (contador == 10) {
              preambleOk = false;
              contador = 0;
              bits = [];
              return;
            }
          }

          stopwatch.reset();
        }
      } else {
        if (stopwatch.elapsed >= interval) {
          int sum = 0;
          for (int i = 0; i < image.planes[0].bytes.length; i++) {
            sum += image.planes[0].bytes[i];
          }

          int luminance = sum ~/ image.planes[0].bytes.length;
          luminanceText = 'Luminancia actual: $luminance';
          bits.add(luminance > 100 ? 1 : 0);

          setState(() {
            luminanceText = 'Luminancia actual: $luminance';
            receivingData = true;
          });

          auxluminance = luminance > 100 ? 1 : 0;
          if (auxluminance != preambleAux) {
            preambleaCount++;
            preambleAux = auxluminance;
          } else {
            preambleaCount = 0;
          }

          if (preambleaCount == 8) {
            setState(() {
              preambleOk = true;
              print('Preamble OK');
              bits = [];
            });
          }

          if (bits.length >= 8) {
            bits = [];
          }

          stopwatch.reset();
        }
      }
    });
  }

  void _processCapturedBits() {
    String result = bits.join('');

    List<String> bytes = [];
    for (int i = 0; i < result.length; i += 8) {
      bytes.add(result.substring(i, i + 8));
    }

    String text = "";
    for (String byte in bytes) {
      try {
        int asciiValue = int.parse(byte, radix: 2);
        text += String.fromCharCode(asciiValue);
      } catch (e) {
        print('Error al convertir byte: $byte');
      }
    }

    setState(() {
      receivedText += text;
      luminanceText = '';
      bits = [];
    });

    print('Texto actualizado: $receivedText');
  }

  @override
  Widget build(BuildContext context) {
    /*if (_isReady) {
      _startImageProcessing();
    }*/

    return Scaffold(
      appBar: AppBar(
        title: const Text('VLC Receiver'),
      ),
      body: Stack(
        children: [
          CameraPreview(_controller),
          Center(
              child: Container(
                  width: 2.0,
                  height: MediaQuery.of(context).size.height,
                  color: Colors.white)),
          Center(
              child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: 2.0,
                  color: Colors.white)),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black.withOpacity(0.5),
              padding: const EdgeInsets.all(8.0),
              child: Text(
                luminanceText,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          Positioned(
            bottom: 90,
            left: 0,
            right: 0,
            child: //boton
                ElevatedButton(
                    onPressed: () {
                      _startImageProcessing();
                    },
                    style: ButtonStyle(
                      backgroundColor: !preambleOk
                          ? MaterialStateProperty.all<Color>(Colors.white)
                          : MaterialStateProperty.all<Color>(Colors.purple),
                    ),
                    child: const Text('Recibir',
                        style: TextStyle(color: Colors.black))),
          ),
          Positioned(
            bottom: 56,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black.withOpacity(0.5),
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Bits Recibidos: $bits',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black.withOpacity(0.5),
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Texto Recibido: $receivedText',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _imageStreamController.close();
    super.dispose();
  }
}
