import 'dart:typed_data';
import 'vtf_image_format.dart';

class VTFImage {
  final VTFImageFormat format;
  final int width;
  final int height;
  final Uint8List data;

  VTFImage({
    required this.format,
    required this.width,
    required this.height,
    required this.data,
  });
}
