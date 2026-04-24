import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

// TFLite nur auf Mobile importieren
import 'package:tflite_flutter/tflite_flutter.dart'
    if (dart.library.html) '../../core/stubs/tflite_stub.dart';

final mlServiceProvider = Provider<MlService>((ref) {
  return MlService();
});

class DetectedCard {
  final int label;
  final int points;
  final double confidence;
  final double x, y, width, height;

  const DetectedCard({
    required this.label,
    required this.points,
    required this.confidence,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  String get symbol {
    const symbols = {
      0: '0',
      1: '1',
      2: '2',
      3: '3',
      4: '4',
      5: '5',
      6: '6',
      7: '7',
      8: '8',
      9: '9',
      10: '+4',
      11: '+2',
      12: '↺',
      13: '⊘',
      14: 'W',
    };
    return symbols[label] ?? '?';
  }
}

class MlService {
  Interpreter? _interpreter;
  bool _isLoaded = false;

  static const _labelToPoints = {
    0: 0,
    1: 1,
    2: 2,
    3: 3,
    4: 4,
    5: 5,
    6: 6,
    7: 7,
    8: 8,
    9: 9,
    10: 50,
    11: 20,
    12: 20,
    13: 20,
    14: 50,
  };

  Future<void> loadModel() async {
    if (kIsWeb) return;
    if (_isLoaded) return;
    _interpreter = await Interpreter.fromAsset(
      'assets/models/best_float32.tflite',
    );
    _isLoaded = true;
  }

  Future<List<DetectedCard>> detect(img.Image image) async {
    if (kIsWeb) return [];
    if (!_isLoaded) await loadModel();

    final resized = img.copyResize(image, width: 416, height: 416);

    final input = List.generate(
      1,
      (_) => List.generate(
        416,
        (y) => List.generate(416, (x) {
          final pixel = resized.getPixel(x, y);
          return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
        }),
      ),
    );

    final output = List.generate(
      1,
      (_) => List.generate(19, (_) => List.filled(3549, 0.0)),
    );

    _interpreter!.run(input, output);
    return _parseOutput(output[0]);
  }

  List<DetectedCard> _parseOutput(List<List<double>> output) {
    final results = <DetectedCard>[];
    const confidenceThreshold = 0.5;

    for (int i = 0; i < 3549; i++) {
      final x = output[0][i];
      final y = output[1][i];
      final w = output[2][i];
      final h = output[3][i];

      double maxScore = 0;
      int bestClass = 0;
      for (int c = 4; c < 19; c++) {
        if (output[c][i] > maxScore) {
          maxScore = output[c][i];
          bestClass = c - 4;
        }
      }

      if (maxScore >= confidenceThreshold) {
        results.add(
          DetectedCard(
            label: bestClass,
            points: _labelToPoints[bestClass] ?? 0,
            confidence: maxScore,
            x: x,
            y: y,
            width: w,
            height: h,
          ),
        );
      }
    }

    return _nms(results);
  }

  List<DetectedCard> _nms(
    List<DetectedCard> cards, {
    double iouThreshold = 0.5,
  }) {
    if (cards.isEmpty) return [];

    final sorted = List<DetectedCard>.from(cards)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));

    final kept = <DetectedCard>[];
    final suppressed = List.filled(sorted.length, false);

    for (int i = 0; i < sorted.length; i++) {
      if (suppressed[i]) continue;
      kept.add(sorted[i]);
      for (int j = i + 1; j < sorted.length; j++) {
        if (_iou(sorted[i], sorted[j]) > iouThreshold) {
          suppressed[j] = true;
        }
      }
    }

    return kept;
  }

  double _iou(DetectedCard a, DetectedCard b) {
    final ax1 = a.x - a.width / 2;
    final ay1 = a.y - a.height / 2;
    final ax2 = a.x + a.width / 2;
    final ay2 = a.y + a.height / 2;

    final bx1 = b.x - b.width / 2;
    final by1 = b.y - b.height / 2;
    final bx2 = b.x + b.width / 2;
    final by2 = b.y + b.height / 2;

    final interX1 = ax1 > bx1 ? ax1 : bx1;
    final interY1 = ay1 > by1 ? ay1 : by1;
    final interX2 = ax2 < bx2 ? ax2 : bx2;
    final interY2 = ay2 < by2 ? ay2 : by2;

    if (interX2 < interX1 || interY2 < interY1) return 0;

    final interArea = (interX2 - interX1) * (interY2 - interY1);
    final aArea = a.width * a.height;
    final bArea = b.width * b.height;

    return interArea / (aArea + bArea - interArea);
  }

  void dispose() {
    if (!kIsWeb) _interpreter?.close();
  }
}
