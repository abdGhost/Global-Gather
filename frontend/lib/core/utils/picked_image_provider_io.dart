import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Mobile/desktop: use file path.
ImageProvider imageProviderForPickedFile(XFile file) {
  return FileImage(File(file.path));
}
