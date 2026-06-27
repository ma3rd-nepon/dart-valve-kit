import 'dart:io';
import 'dart:typed_data';
import 'vtf_header.dart';
import 'vtf_image_format.dart';
import 'vtf_image.dart';
import 'package:image/image.dart' as img;

typedef ImageEncoder = Uint8List Function(img.Image image);

class VTFFile {
  static const String VTF_HEADER = "VTF";

  late VTFHeader header;
  late List<VTFResource> resources;
  VTFImage? lowResImage;
  Uint8List? frameData;

  int width = 0;
  int height = 0;

  VTFFile.fromFile(String filePath) {
    final file = File(filePath);
    final bytes = file.readAsBytesSync();
    _parse(bytes);
  }

  VTFFile.fromBytes(Uint8List bytes) {
    _parse(bytes);
  }

  void _parse(Uint8List bytes) {
    final reader = ByteDataReader(bytes);

    final headerStr = reader.readString(4);
    if (headerStr != VTF_HEADER) {
      throw Exception(
        'Invalid VTF header. Expected "$VTF_HEADER", got "$headerStr"',
      );
    }

    header = VTFHeader();

    final versionMajor = reader.readUint32();
    final versionMinor = reader.readUint32();
    header.version = versionMajor + (versionMinor / 10);

    final headerSize = reader.readUint32();
    width = reader.readUint16();
    height = reader.readUint16();
    header.flags = VTFImageFlag.fromValue(reader.readUint32());

    final numFrames = reader.readUint16();
    final firstFrame = reader.readUint16();
    reader.skip(4);

    header.reflectivity = reader.readVector3();
    reader.skip(4);
    header.bumpmapScale = reader.readFloat32();

    final highResImageFormat = VTFImageFormat.fromValue(reader.readUint32());
    final mipmapCount = reader.readUint8();
    final lowResImageFormat = VTFImageFormat.fromValue(reader.readUint32());
    final lowResWidth = reader.readUint8();
    final lowResHeight = reader.readUint8();

    int depth = 1;
    int numResources = 0;

    if (header.version >= 7.2) {
      depth = reader.readUint16();
    }

    if (header.version >= 7.3) {
      reader.skip(3);
      numResources = reader.readUint32();
      reader.skip(8);
    }

    int numFaces = 1;
    if (header.flags.hasFlag(VTFImageFlag.TEXTUREFLAGS_ENVMAP)) {
      numFaces = (header.version < 7.5 && firstFrame != 0xFFFF) ? 7 : 6;
    }

    final highResFormatInfo = VTFImageFormatInfo.fromFormat(highResImageFormat);
    final lowResFormatInfo = VTFImageFormatInfo.fromFormat(lowResImageFormat);

    int thumbnailSize = lowResImageFormat == VTFImageFormat.IMAGE_FORMAT_NONE
        ? 0
        : lowResFormatInfo.getSize(lowResWidth, lowResHeight);

    int thumbnailOffset = headerSize;

    resources = List.generate(numResources, (i) {
      final type = VTFResourceType.fromValue(reader.readUint32());
      final dataSize = reader.readUint32();

      return VTFResource(type: type, data: dataSize);
    });

    if (lowResImageFormat != VTFImageFormat.IMAGE_FORMAT_NONE) {
      reader.position = thumbnailOffset;
      final thumbSize = lowResFormatInfo.getSize(lowResWidth, lowResHeight);
      lowResImage = VTFImage(
        format: lowResImageFormat,
        width: lowResWidth,
        height: lowResHeight,
        data: reader.readBytes(thumbSize),
      );
    }

    reader.position = headerSize + thumbnailSize;
    resources = List.generate(numResources, (i) {
      final type = VTFResourceType.fromValue(reader.readUint32());
      final dataSize = reader.readUint32();
      return VTFResource(type: type, data: dataSize);
    });

    // ==========================================
    // Чтение основного изображения (NEED TESTING)
    // ==========================================
    Uint8List? mainImageData;

    for (int mipLevel = mipmapCount - 1; mipLevel >= 0; mipLevel--) {
      for (int frameID = 0; frameID < numFrames; frameID++) {
        for (int faceID = 0; faceID < numFaces; faceID++) {
          for (int sliceID = 0; sliceID < depth; sliceID++) {
            final mipWidth = _getMipSize(width, mipLevel);
            final mipHeight = _getMipSize(height, mipLevel);
            final dataSize = highResFormatInfo.getSize(mipWidth, mipHeight);

            if (dataSize == 0 || reader.position + dataSize > bytes.length) {
              continue;
            }

            final data = reader.readBytes(dataSize);

            if (mipLevel == 0 && frameID == 0 && faceID == 0 && sliceID == 0) {
              if (highResImageFormat == VTFImageFormat.IMAGE_FORMAT_BGRA8888) {
                mainImageData = data;
              } else {
                mainImageData = highResFormatInfo.convertToBgra32(
                  data,
                  mipWidth,
                  mipHeight,
                );
              }
            }
          }
        }
      }
    }

    frameData = mainImageData;

    if (frameData == null) {
      throw Exception(
        'Failed to extract main image data. MipCount: $mipmapCount, Format: $highResImageFormat',
      );
    }

    // ПОЧЕМУ ЛИНТЕР БЫКУЕТ НА НИХ МОЛ НЕЮЗАЮТСЯ
    bool convertToBGRA32 = true;
    bool hasAlpha = true;

    switch (highResImageFormat) {
      case VTFImageFormat.IMAGE_FORMAT_A8:
      case VTFImageFormat.IMAGE_FORMAT_ABGR8888:
      case VTFImageFormat.IMAGE_FORMAT_ARGB8888:
      case VTFImageFormat.IMAGE_FORMAT_BGRA4444:
      case VTFImageFormat.IMAGE_FORMAT_DXT1_ONEBITALPHA:
      case VTFImageFormat.IMAGE_FORMAT_DXT3:
      case VTFImageFormat.IMAGE_FORMAT_DXT5:
      case VTFImageFormat.IMAGE_FORMAT_RGBA8888:
      case VTFImageFormat.IMAGE_FORMAT_BGRA8888:
      case VTFImageFormat.IMAGE_FORMAT_BGRX8888:
      case VTFImageFormat.IMAGE_FORMAT_RGBA16161616F:
      case VTFImageFormat.IMAGE_FORMAT_RGBA16161616:
        convertToBGRA32 = false;
        break;
      case VTFImageFormat.IMAGE_FORMAT_BGR565:
      case VTFImageFormat.IMAGE_FORMAT_RGB565:
      case VTFImageFormat.IMAGE_FORMAT_DXT1:
      case VTFImageFormat.IMAGE_FORMAT_RGB888:
        hasAlpha = false;
        convertToBGRA32 = false;
        break;
      default:
        break;
    }
  }

  static int _getMipSize(int input, int level) {
    int res = input >> level;
    if (res < 1) res = 1;
    return res;
  }

  img.Image toImage() {
    if (frameData == null) {
      throw img.ImageException("No image data");
    }
    print("framesData lentgth: ${frameData!.length}");
    return img.Image.fromBytes(
      width: width,
      height: height,
      bytes: frameData!.buffer,
      order: img.ChannelOrder.bgra,
    );
  }

  void saveAs(String outputPath, ImageFormat format) {
    try {
      final image = toImage();
      final fBytes = format.encode(image);
      File(outputPath).writeAsBytesSync(fBytes);
    } catch (e) {
      print("Error occured $e");
    }
  }
}

class ByteDataReader {
  final Uint8List _bytes;
  int _position = 0;

  ByteDataReader(this._bytes);

  int get position => _position;
  set position(int value) => _position = value;

  void skip(int count) {
    _position += count;
  }

  String readString(int length) {
    final bytes = readBytes(length);
    return String.fromCharCodes(bytes).replaceAll('\x00', '').trim();
  }

  Uint8List readBytes(int count) {
    final result = _bytes.sublist(_position, _position + count);
    _position += count;
    return result;
  }

  int readUint8() {
    return _bytes[_position++];
  }

  int readUint16() {
    final value = _bytes[_position] | (_bytes[_position + 1] << 8);
    _position += 2;
    return value;
  }

  int readUint32() {
    final value =
        _bytes[_position] |
        (_bytes[_position + 1] << 8) |
        (_bytes[_position + 2] << 16) |
        (_bytes[_position + 3] << 24);
    _position += 4;
    return value;
  }

  double readFloat32() {
    final bytes = readBytes(4);
    final data = ByteData.sublistView(bytes);
    return data.getFloat32(0, Endian.little);
  }

  List<double> readVector3() {
    return [readFloat32(), readFloat32(), readFloat32()];
  }
}

class VTFResource {
  final VTFResourceType type;
  final int data;

  VTFResource({required this.type, required this.data});
}

enum VTFResourceType {
  LowResImage,
  Image,
  Sheet,
  CRC,
  TextureLodSettings,
  TextureSettingsEx,
  KeyValueData;

  static VTFResourceType fromValue(int value) {
    switch (value) {
      case 0x01:
        return VTFResourceType.LowResImage;
      case 0x30:
        return VTFResourceType.Image;
      case 0x10:
        return VTFResourceType.Sheet;
      case 0x02:
        return VTFResourceType.CRC;
      case 0x31:
        return VTFResourceType.TextureLodSettings;
      case 0x32:
        return VTFResourceType.TextureSettingsEx;
      case 0x03:
        return VTFResourceType.KeyValueData;
      default:
        throw Exception('Unknown resource type: $value');
    }
  }
}

enum ImageFormat {
  png(img.encodePng, '.png'),
  bmp(img.encodeBmp, '.bmp'),
  jpg(img.encodeJpg, '.jpg'),
  tga(img.encodeTga, '.tga');

  final ImageEncoder encoder;
  final String extension;

  const ImageFormat(this.encoder, this.extension);

  Uint8List encode(img.Image image) => encoder(image);
}
