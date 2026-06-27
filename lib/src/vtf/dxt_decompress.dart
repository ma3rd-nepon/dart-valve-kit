import 'dart:typed_data';

class DXTDecompress {
  static void decompressDXT1(
    Uint8List buffer,
    Uint8List data,
    int width,
    int height,
  ) {
    int position = 0;
    final c = Uint8List(16);

    for (int y = 0; y < height; y += 4) {
      for (int x = 0; x < width; x += 4) {
        int c0 = data[position++];
        c0 |= data[position++] << 8;
        int c1 = data[position++];
        c1 |= data[position++] << 8;

        c[0] = (c0 & 0xF800) >> 8;
        c[1] = (c0 & 0x07E0) >> 3;
        c[2] = (c0 & 0x001F) << 3;
        c[3] = 255;

        c[4] = (c1 & 0xF800) >> 8;
        c[5] = (c1 & 0x07E0) >> 3;
        c[6] = (c1 & 0x001F) << 3;
        c[7] = 255;

        if (c0 > c1) {
          c[8] = (2 * c[0] + c[4]) ~/ 3;
          c[9] = (2 * c[1] + c[5]) ~/ 3;
          c[10] = (2 * c[2] + c[6]) ~/ 3;
          c[11] = 255;

          c[12] = (c[0] + 2 * c[4]) ~/ 3;
          c[13] = (c[1] + 2 * c[5]) ~/ 3;
          c[14] = (c[2] + 2 * c[6]) ~/ 3;
          c[15] = 255;
        } else {
          c[8] = (c[0] + c[4]) ~/ 2;
          c[9] = (c[1] + c[5]) ~/ 2;
          c[10] = (c[2] + c[6]) ~/ 2;
          c[11] = 255;

          c[12] = 0;
          c[13] = 0;
          c[14] = 0;
          c[15] = 0;
        }

        int bytes = data[position++];
        bytes |= data[position++] << 8;
        bytes |= data[position++] << 16;
        bytes |= data[position++] << 24;

        for (int yy = 0; yy < 4; yy++) {
          for (int xx = 0; xx < 4; xx++) {
            int xPosition = x + xx;
            int yPosition = y + yy;

            if (xPosition < width && yPosition < height) {
              int index = bytes & 0x0003;
              index *= 4;
              int pointer = yPosition * width * 4 + xPosition * 4;

              buffer[pointer + 0] = c[index + 2]; // B
              buffer[pointer + 1] = c[index + 1]; // G
              buffer[pointer + 2] = c[index + 0]; // R
              buffer[pointer + 3] = c[index + 3]; // A
            }

            bytes >>= 2;
          }
        }
      }
    }
  }

  static void decompressDXT3(
    Uint8List buffer,
    Uint8List data,
    int width,
    int height,
  ) {
    int position = 0;
    final c = Uint8List(16);
    final a = Uint8List(8);

    for (int y = 0; y < height; y += 4) {
      for (int x = 0; x < width; x += 4) {
        for (int i = 0; i < 8; i++) {
          a[i] = data[position++];
        }

        int c0 = data[position++];
        c0 |= data[position++] << 8;
        int c1 = data[position++];
        c1 |= data[position++] << 8;

        c[0] = (c0 & 0xF800) >> 8;
        c[1] = (c0 & 0x07E0) >> 3;
        c[2] = (c0 & 0x001F) << 3;
        c[3] = 255;

        c[4] = (c1 & 0xF800) >> 8;
        c[5] = (c1 & 0x07E0) >> 3;
        c[6] = (c1 & 0x001F) << 3;
        c[7] = 255;

        c[8] = (2 * c[0] + c[4]) ~/ 3;
        c[9] = (2 * c[1] + c[5]) ~/ 3;
        c[10] = (2 * c[2] + c[6]) ~/ 3;
        c[11] = 255;

        c[12] = (c[0] + 2 * c[4]) ~/ 3;
        c[13] = (c[1] + 2 * c[5]) ~/ 3;
        c[14] = (c[2] + 2 * c[6]) ~/ 3;
        c[15] = 255;

        int bytes = data[position++];
        bytes |= data[position++] << 8;
        bytes |= data[position++] << 16;
        bytes |= data[position++] << 24;

        for (int yy = 0; yy < 4; yy++) {
          for (int xx = 0; xx < 4; xx++) {
            int xPosition = x + xx;
            int yPosition = y + yy;
            int aIndex = yy * 4 + xx;

            if (xPosition < width && yPosition < height) {
              int index = bytes & 0x0003;
              index *= 4;

              int alpha = (a[aIndex >> 1] >> (aIndex << 2 & 0x07)) & 0x0f;
              alpha = (alpha << 4) | alpha;

              int pointer = yPosition * width * 4 + xPosition * 4;

              buffer[pointer + 0] = c[index + 2]; // B
              buffer[pointer + 1] = c[index + 1]; // G
              buffer[pointer + 2] = c[index + 0]; // R
              buffer[pointer + 3] = alpha; // A
            }

            bytes >>= 2;
          }
        }
      }
    }
  }

  static void decompressDXT5(
    Uint8List buffer,
    Uint8List data,
    int width,
    int height,
  ) {
    int position = 0;
    final c = Uint8List(16);
    final a = List<int>.filled(8, 0);

    int blocksX = (width + 3) ~/ 4;
    int blocksY = (height + 3) ~/ 4;

    for (int blockY = 0; blockY < blocksY; blockY++) {
      for (int blockX = 0; blockX < blocksX; blockX++) {
        int baseX = blockX * 4;
        int baseY = blockY * 4;

        if (position + 8 > data.length) break;
        int a0 = data[position++];
        int a1 = data[position++];

        a[0] = a0;
        a[1] = a1;

        if (a0 > a1) {
          a[2] = (6 * a[0] + 1 * a[1] + 3) ~/ 7;
          a[3] = (5 * a[0] + 2 * a[1] + 3) ~/ 7;
          a[4] = (4 * a[0] + 3 * a[1] + 3) ~/ 7;
          a[5] = (3 * a[0] + 4 * a[1] + 3) ~/ 7;
          a[6] = (2 * a[0] + 5 * a[1] + 3) ~/ 7;
          a[7] = (1 * a[0] + 6 * a[1] + 3) ~/ 7;
        } else {
          a[2] = (4 * a[0] + 1 * a[1] + 2) ~/ 5;
          a[3] = (3 * a[0] + 2 * a[1] + 2) ~/ 5;
          a[4] = (2 * a[0] + 3 * a[1] + 2) ~/ 5;
          a[5] = (1 * a[0] + 4 * a[1] + 2) ~/ 5;
          a[6] = 0x00;
          a[7] = 0xFF;
        }

        if (position + 6 > data.length) break;
        int aIndexLow =
            data[position++] |
            (data[position++] << 8) |
            (data[position++] << 16) |
            (data[position++] << 24);
        int aIndexHigh = data[position++] | (data[position++] << 8);

        if (position + 4 > data.length) break;
        int c0 = data[position++] | (data[position++] << 8);
        int c1 = data[position++] | (data[position++] << 8);

        c[0] = (c0 & 0xF800) >> 8;
        c[1] = (c0 & 0x07E0) >> 3;
        c[2] = (c0 & 0x001F) << 3;
        c[3] = 255;

        c[4] = (c1 & 0xF800) >> 8;
        c[5] = (c1 & 0x07E0) >> 3;
        c[6] = (c1 & 0x001F) << 3;
        c[7] = 255;

        c[8] = (2 * c[0] + c[4]) ~/ 3;
        c[9] = (2 * c[1] + c[5]) ~/ 3;
        c[10] = (2 * c[2] + c[6]) ~/ 3;
        c[11] = 255;

        c[12] = (c[0] + 2 * c[4]) ~/ 3;
        c[13] = (c[1] + 2 * c[5]) ~/ 3;
        c[14] = (c[2] + 2 * c[6]) ~/ 3;
        c[15] = 255;

        if (position + 4 > data.length) break;
        int colorIndex =
            data[position++] |
            (data[position++] << 8) |
            (data[position++] << 16) |
            (data[position++] << 24);

        for (int yy = 0; yy < 4; yy++) {
          for (int xx = 0; xx < 4; xx++) {
            int xPosition = baseX + xx;
            int yPosition = baseY + yy;

            if (xPosition >= width || yPosition >= height) {
              continue;
            }

            int pointer = (yPosition * width + xPosition) * 4;

            if (pointer < 0 || pointer + 3 >= buffer.length) {
              continue;
            }

            int colorIdx = (colorIndex >> (2 * (yy * 4 + xx))) & 0x03;
            colorIdx *= 4;

            int alphaBitIndex = 3 * (yy * 4 + xx);
            int alphaIdx;
            if (alphaBitIndex < 32) {
              alphaIdx = (aIndexLow >> alphaBitIndex) & 0x07;
            } else {
              alphaIdx = (aIndexHigh >> (alphaBitIndex - 32)) & 0x07;
            }

            buffer[pointer + 0] = c[colorIdx + 2]; // B
            buffer[pointer + 1] = c[colorIdx + 1]; // G
            buffer[pointer + 2] = c[colorIdx + 0]; // R
            buffer[pointer + 3] = a[alphaIdx]; // A
          }
        }
      }
    }
  }
}
