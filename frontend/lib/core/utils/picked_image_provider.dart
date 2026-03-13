import 'package:flutter/painting.dart';
import 'package:image_picker/image_picker.dart';

import 'picked_image_provider_stub.dart'
    if (dart.library.io) 'picked_image_provider_io.dart' as impl;

/// Returns an [ImageProvider] for a picked image file (web: blob URL, io: file).
ImageProvider imageProviderForPickedFile(XFile file) {
  return impl.imageProviderForPickedFile(file);
}
