import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Stub for web: use network (blob) URL.
ImageProvider imageProviderForPickedFile(XFile file) {
  return NetworkImage(file.path);
}
