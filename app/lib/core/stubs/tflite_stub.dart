// Stub for tflite_flutter on Web platform.
// These classes are never instantiated on Web, but allow compilation.

class Interpreter {
  Interpreter._();

  static Future<Interpreter> fromAsset(String assetPath) async {
    throw UnsupportedError('TFLite is not supported on Web');
  }

  void run(Object input, Object output) {
    throw UnsupportedError('TFLite is not supported on Web');
  }

  void close() {}
}
