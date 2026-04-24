// Stub for package:camera on Web platform.
// These classes are never instantiated on Web, but allow compilation.

import 'dart:typed_data';
import 'package:flutter/widgets.dart';

enum ResolutionPreset { low, medium, high, veryHigh, ultraHigh, max }

class CameraDescription {
  final String name;
  final int lensDirection;
  final int sensorOrientation;

  const CameraDescription({
    this.name = '',
    this.lensDirection = 0,
    this.sensorOrientation = 0,
  });
}

class XFile {
  final String path;

  XFile(this.path);

  Future<Uint8List> readAsBytes() async {
    throw UnsupportedError('Camera is not supported on Web');
  }
}

class CameraController {
  final CameraDescription description;
  final ResolutionPreset resolutionPreset;
  final bool enableAudio;

  CameraController(
    this.description,
    this.resolutionPreset, {
    this.enableAudio = true,
  });

  Future<void> initialize() async {
    throw UnsupportedError('Camera is not supported on Web');
  }

  Future<XFile> takePicture() async {
    throw UnsupportedError('Camera is not supported on Web');
  }

  void dispose() {}
}

Future<List<CameraDescription>> availableCameras() async {
  return [];
}

class CameraPreview extends StatelessWidget {
  final CameraController controller;

  const CameraPreview(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
