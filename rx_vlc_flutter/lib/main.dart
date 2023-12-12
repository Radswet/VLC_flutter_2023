import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

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
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  late CameraController _controller;
  bool _isReady = false;
  List<int> bits = [];
  String preamble = '10101010';
  int preambleIndex = 0;
  bool receivingData = false;

  String receivedText = '';

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
      ResolutionPreset.low, // Ajusta la resolución aquí
      enableAudio: false,
    );

    await _controller.initialize();

    if (!mounted) {
      return;
    }

    setState(() {
      _isReady = true;
      _startImageProcessing();
    });
  }

  Future<void> _startImageProcessing() async {
    _controller.startImageStream((CameraImage image) {
      _processImage(image);
    });
  }

  void _processImage(CameraImage image) {
    int sum = 0;
    for (int i = 0; i < image.planes[0].bytes.length; i++) {
      sum += image.planes[0].bytes[i];
    }
    int average = sum ~/ image.planes[0].bytes.length;

    setState(() {
      _processReceivedData(average);
    });
  }

  void _processReceivedData(int luminance) {
    if (!receivingData) {
      if (luminance > 100) {
        if (preamble[preambleIndex] == '1') {
          preambleIndex++;
          if (preambleIndex == preamble.length) {
            setState(() {
              receivingData = true;
              bits = [];
            });
          }
        } else {
          preambleIndex = 0;
        }
      } else {
        preambleIndex = 0;
      }
    } else {
      bits.add(luminance > 100 ? 1 : 0);
      if (bits.length >= 8) {
        _processCapturedBits();
      }
    }

    if (receivingData) {
      print('Bits recibidos: $bits');
    }
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
      receivedText = text;
    });

    final int expectedBitsAfterPreamble = 8 * text.length;
    if (receivingData && bits.length >= expectedBitsAfterPreamble) {
      setState(() {
        receivingData = false;
        preambleIndex = 0;
        receivedText = '';
        bits = [];
      });
    }
    print('Texto actualizado: $receivedText');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VLC Receiver'),
      ),
      body: _isReady
          ? Stack(
              children: [
                CameraPreview(_controller),
                Center(
                  child: Container(
                    width: 2.0,
                    height: MediaQuery.of(context).size.height,
                    color: Colors.white,
                  ),
                ),
                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: 2.0,
                    color: Colors.white,
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      receivingData
                          ? 'Capturando datos'
                          : 'Esperando inicialización',
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
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
