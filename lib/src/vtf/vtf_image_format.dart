import 'dart:typed_data';
import 'dxt_decompress.dart';

enum VTFImageFormat {
  IMAGE_FORMAT_NONE(-1),
  IMAGE_FORMAT_RGBA8888(0),
  IMAGE_FORMAT_ABGR8888(1),
  IMAGE_FORMAT_RGB888(2),
  IMAGE_FORMAT_BGR888(3),
  IMAGE_FORMAT_RGB565(4),
  IMAGE_FORMAT_I8(5),
  IMAGE_FORMAT_IA88(6),
  IMAGE_FORMAT_P8(7),
  IMAGE_FORMAT_A8(8),
  IMAGE_FORMAT_RGB888_BLUESCREEN(9),
  IMAGE_FORMAT_BGR888_BLUESCREEN(10),
  IMAGE_FORMAT_ARGB8888(11),
  IMAGE_FORMAT_BGRA8888(12),
  IMAGE_FORMAT_DXT1(13),
  IMAGE_FORMAT_DXT3(14),
  IMAGE_FORMAT_DXT5(15),
  IMAGE_FORMAT_BGRX8888(16),
  IMAGE_FORMAT_BGR565(17),
  IMAGE_FORMAT_BGRX5551(18),
  IMAGE_FORMAT_BGRA4444(19),
  IMAGE_FORMAT_DXT1_ONEBITALPHA(20),
  IMAGE_FORMAT_BGRA5551(21),
  IMAGE_FORMAT_UV88(22),
  IMAGE_FORMAT_UVWQ8888(23),
  IMAGE_FORMAT_RGBA16161616F(24),
  IMAGE_FORMAT_RGBA16161616(25),
  IMAGE_FORMAT_UVLX8888(26),
  IMAGE_FORMAT_R32F(27),
  IMAGE_FORMAT_RGB323232F(28),
  IMAGE_FORMAT_RGBA32323232F(29);

  final int value;
  const VTFImageFormat(this.value);

  static VTFImageFormat fromValue(int value) {
    return VTFImageFormat.values.firstWhere(
      (f) => f.value == value,
      orElse: () => VTFImageFormat.IMAGE_FORMAT_NONE,
    );
  }
}

class VTFImageFormatInfo {
  final VTFImageFormat format;
  final int bitsPerPixel;
  final int bytesPerPixel;
  final int redBitsPerPixel;
  final int greenBitsPerPixel;
  final int blueBitsPerPixel;
  final int alphaBitsPerPixel;
  final int redIndex;
  final int greenIndex;
  final int blueIndex;
  final int alphaIndex;
  final bool isCompressed;
  final bool isSupported;

  VTFImageFormatInfo({
    required this.format,
    required this.bitsPerPixel,
    required this.bytesPerPixel,
    required this.redBitsPerPixel,
    required this.greenBitsPerPixel,
    required this.blueBitsPerPixel,
    required this.alphaBitsPerPixel,
    required this.redIndex,
    required this.greenIndex,
    required this.blueIndex,
    required this.alphaIndex,
    required this.isCompressed,
    required this.isSupported,
  });

  static VTFImageFormatInfo fromFormat(VTFImageFormat format) {
    return _imageFormats[format]!;
  }

  int getSize(int width, int height) {
    if (isCompressed) {
      int blocksX = (width + 3) ~/ 4;
      int blocksY = (height + 3) ~/ 4;

      if (blocksX < 1) blocksX = 1;
      if (blocksY < 1) blocksY = 1;

      int bytesPerBlock;
      if (format == VTFImageFormat.IMAGE_FORMAT_DXT1 ||
          format == VTFImageFormat.IMAGE_FORMAT_DXT1_ONEBITALPHA) {
        bytesPerBlock = 8;
      } else {
        bytesPerBlock = 16;
      }

      return blocksX * blocksY * bytesPerBlock;
    }
    return width * height * bytesPerPixel;
  }

  Uint8List convertToBgra32(Uint8List data, int width, int height) {
    final buffer = Uint8List(width * height * 4);

    if (format == VTFImageFormat.IMAGE_FORMAT_NONE) return buffer;

    if (format == VTFImageFormat.IMAGE_FORMAT_BGRA8888) {
      buffer.setAll(0, data);
      return buffer;
    }

    if (isCompressed) {
      switch (format) {
        case VTFImageFormat.IMAGE_FORMAT_DXT1:
        case VTFImageFormat.IMAGE_FORMAT_DXT1_ONEBITALPHA:
          DXTDecompress.decompressDXT1(buffer, data, width, height);
          break;
        case VTFImageFormat.IMAGE_FORMAT_DXT3:
          DXTDecompress.decompressDXT3(buffer, data, width, height);
          break;
        case VTFImageFormat.IMAGE_FORMAT_DXT5:
          DXTDecompress.decompressDXT5(buffer, data, width, height);
          break;
        default:
          throw Exception('Unsupported format: $format');
      }
    } else {
      for (int i = 0, j = 0; i < data.length; i += bytesPerPixel, j += 4) {
        buffer[j + 0] = blueIndex >= 0 ? data[i + blueIndex] : 0;
        buffer[j + 1] = greenIndex >= 0 ? data[i + greenIndex] : 0;
        buffer[j + 2] = redIndex >= 0 ? data[i + redIndex] : 0;
        buffer[j + 3] = alphaIndex >= 0 ? data[i + alphaIndex] : 255;
      }
    }

    return buffer;
  }

  static final Map<VTFImageFormat, VTFImageFormatInfo> _imageFormats = {
    VTFImageFormat.IMAGE_FORMAT_NONE: VTFImageFormatInfo(
      format: VTFImageFormat.IMAGE_FORMAT_NONE,
      bitsPerPixel: 0,
      bytesPerPixel: 0,
      redBitsPerPixel: 0,
      greenBitsPerPixel: 0,
      blueBitsPerPixel: 0,
      alphaBitsPerPixel: 0,
      redIndex: -1,
      greenIndex: -1,
      blueIndex: -1,
      alphaIndex: -1,
      isCompressed: false,
      isSupported: false,
    ),
    VTFImageFormat.IMAGE_FORMAT_RGBA8888: VTFImageFormatInfo(
      format: VTFImageFormat.IMAGE_FORMAT_RGBA8888,
      bitsPerPixel: 32,
      bytesPerPixel: 4,
      redBitsPerPixel: 8,
      greenBitsPerPixel: 8,
      blueBitsPerPixel: 8,
      alphaBitsPerPixel: 8,
      redIndex: 0,
      greenIndex: 1,
      blueIndex: 2,
      alphaIndex: 3,
      isCompressed: false,
      isSupported: true,
    ),
    VTFImageFormat.IMAGE_FORMAT_BGRA8888: VTFImageFormatInfo(
      format: VTFImageFormat.IMAGE_FORMAT_BGRA8888,
      bitsPerPixel: 32,
      bytesPerPixel: 4,
      redBitsPerPixel: 8,
      greenBitsPerPixel: 8,
      blueBitsPerPixel: 8,
      alphaBitsPerPixel: 8,
      redIndex: 2,
      greenIndex: 1,
      blueIndex: 0,
      alphaIndex: 3,
      isCompressed: false,
      isSupported: true,
    ),
    VTFImageFormat.IMAGE_FORMAT_RGB888: VTFImageFormatInfo(
      format: VTFImageFormat.IMAGE_FORMAT_RGB888,
      bitsPerPixel: 24,
      bytesPerPixel: 3,
      redBitsPerPixel: 8,
      greenBitsPerPixel: 8,
      blueBitsPerPixel: 8,
      alphaBitsPerPixel: 0,
      redIndex: 0,
      greenIndex: 1,
      blueIndex: 2,
      alphaIndex: -1,
      isCompressed: false,
      isSupported: true,
    ),
    VTFImageFormat.IMAGE_FORMAT_DXT1: VTFImageFormatInfo(
      format: VTFImageFormat.IMAGE_FORMAT_DXT1,
      bitsPerPixel: 4,
      bytesPerPixel: 0,
      redBitsPerPixel: 0,
      greenBitsPerPixel: 0,
      blueBitsPerPixel: 0,
      alphaBitsPerPixel: 0,
      redIndex: -1,
      greenIndex: -1,
      blueIndex: -1,
      alphaIndex: -1,
      isCompressed: true,
      isSupported: true,
    ),
    VTFImageFormat.IMAGE_FORMAT_DXT3: VTFImageFormatInfo(
      format: VTFImageFormat.IMAGE_FORMAT_DXT3,
      bitsPerPixel: 8,
      bytesPerPixel: 0,
      redBitsPerPixel: 0,
      greenBitsPerPixel: 0,
      blueBitsPerPixel: 0,
      alphaBitsPerPixel: 8,
      redIndex: -1,
      greenIndex: -1,
      blueIndex: -1,
      alphaIndex: -1,
      isCompressed: true,
      isSupported: true,
    ),
    VTFImageFormat.IMAGE_FORMAT_DXT5: VTFImageFormatInfo(
      format: VTFImageFormat.IMAGE_FORMAT_DXT5,
      bitsPerPixel: 8,
      bytesPerPixel: 0,
      redBitsPerPixel: 0,
      greenBitsPerPixel: 0,
      blueBitsPerPixel: 0,
      alphaBitsPerPixel: 8,
      redIndex: -1,
      greenIndex: -1,
      blueIndex: -1,
      alphaIndex: -1,
      isCompressed: true,
      isSupported: true,
    ),
  };
}
