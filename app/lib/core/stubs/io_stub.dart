// Stub for dart:io on Web platform.
// These classes are never instantiated on Web, but allow compilation.

import 'dart:typed_data';

class File {
  final String path;

  File(this.path);

  Future<Uint8List> readAsBytes() async {
    throw UnsupportedError('File I/O is not supported on Web');
  }
}
