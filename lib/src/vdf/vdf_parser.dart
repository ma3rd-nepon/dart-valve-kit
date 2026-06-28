import 'dart:convert';
import 'dart:io';

const VDFFile vdf = VDFFile();
String vdfEncode(Map<String, dynamic> input) => vdf.encode(input);
Map<String, dynamic> vdfDecode(String input) => vdf.decode(input);

// ===============================
// ======== NEED TESTING =========
// ===============================

class VDFFile extends Codec<Map<String, dynamic>, String> {
  const VDFFile();

  @override
  VdfEncoder get encoder => const VdfEncoder();

  @override
  VdfDecoder get decoder => const VdfDecoder();

  static Map<String, dynamic> fromFile(String filePath) {
    try {
      final file = File(filePath).readAsStringSync();
      return const VdfDecoder().convert(file);
    } catch (error) {
      throw FormatException('Error during VDF decoding from file: $error');
    }
  }

  static Future<Map<String, dynamic>> fromFileAsync(String filePath) async {
    try {
      final file = await File(filePath).readAsString();
      return const VdfDecoder().convert(file);
    } catch (error) {
      throw FormatException('Error during async VDF decoding from file: $error');
    }
  }

  static void saveAsVdf(
    Map<String, dynamic> data, 
    String filePath, {
    Function(Object)? onError, 
    Function(Object)? onSuccess, 
    FileMode writeMode=FileMode.write
    }) {
    try {
      if (writeMode == FileMode.read) {throw FileSystemException('Use write or append mode instead'); }

      final file = File(filePath);
      if (!file.existsSync() && writeMode == FileMode.append) { throw FileSystemException('File does not exists: $filePath'); }

      if (!file.parent.existsSync()) { file.parent.createSync(recursive: true); }

      final String vdfString = VdfEncoder().convert(data);
      file.writeAsStringSync(vdfString, mode: writeMode);

      if (onSuccess != null) onSuccess(filePath);
    } catch (error) {
      onError != null ? onError(error) : throw FormatException('Error during saving as VDF: $error');
    }
  }

  static void saveAsVdfAsync(
    Map<String, dynamic> data, 
    String filePath, {
    Function(Object)? onError, 
    Function(Object)? onSuccess, 
    FileMode writeMode=FileMode.write
    }) async {
    try {
      if (writeMode == FileMode.read) {throw FileSystemException('Use write or append mode instead'); }

      final file = File(filePath);
      if (!await file.exists() && writeMode == FileMode.append) { throw FileSystemException('File does not exists: $filePath'); }

      if (!await file.parent.exists()) { await file.parent.create(recursive: true); }

      final String vdfString = VdfEncoder().convert(data);
      await file.writeAsString(vdfString, mode: writeMode);

      if (onSuccess != null) onSuccess(filePath);
    } catch (error) {
      onError != null ? onError(error) : throw FormatException('Error during saving as VDF: $error');
    }
  }

  static void saveAsJson(
    Map<String, dynamic> data,
    String filePath, {
    bool pretty = true,
    int indent = 4,
    FileMode writeMode = FileMode.write,
    Function(Object)? onError,
    Function(Object)? onSuccess,
  }) {
    try {
      if (writeMode == FileMode.read) {throw FileSystemException('Use write or append mode instead'); }

      final file = File(filePath);
      if (!file.existsSync() && writeMode == FileMode.append) { throw Exception('File does not exists: $filePath'); }

      if (!file.parent.existsSync()) { file.parent.createSync(recursive: true); }

      final String jsonString = pretty ? JsonEncoder.withIndent(' ' * indent).convert(data) : jsonEncode(data);
      file.writeAsStringSync(jsonString, mode: writeMode);

      if (onSuccess != null) onSuccess(filePath);
    } catch (error) {
      onError == null ? throw FormatException('Error during saving JSON: $error') : onError(error);
    }
  }

  static void saveAsJsonAsync(
    Map<String, dynamic> data,
    String filePath, {
    bool pretty = true,
    int indent = 4,
    FileMode writeMode = FileMode.write,
    Function(Object)? onError,
    Function(Object)? onSuccess,
  }) async {
    try {
      if (writeMode == FileMode.read) {throw FileSystemException('Use write or append mode instead'); }

      final file = File(filePath);
      if (!await file.exists() && writeMode == FileMode.append) { throw Exception('File does not exists: $filePath'); }

      if (!(await file.parent.exists())) { await file.parent.create(recursive: true); }

      final String jsonString = pretty ? JsonEncoder.withIndent(' ' * indent).convert(data) : jsonEncode(data);
      await file.writeAsString(jsonString);

      if (onSuccess != null) onSuccess(filePath);
    } catch (error) {
      onError == null ? throw FormatException('Error during saving JSON: $error') : onError(error);
    }
  }
}

class VdfEncoder extends Converter<Map<String, dynamic>, String> {
  const VdfEncoder();

  @override
  String convert(Map<String, dynamic> input) {
    return _decode(input);
  }

  String _decode(Map input, [int level = 0]) {
    const x = '\t';
    var result = '';
    var indent = '';

    indent = List.generate(level, (_) => x).join();

    for (final key in input.keys) {
      if (input[key] is Map) {
        result += [
          indent,
          '"',
          key,
          '"\n',
          indent,
          '{\n',
          _decode(input[key], level + 1),
          indent,
          '}\n',
        ].join();
      } else {
        result += [
          indent,
          '"',
          key,
          '"',
          x,
          x,
          '"',
          input[key].toString(),
          '"\n',
        ].join();
      }
    }

    return result;
  }
}

class VdfDecoder extends Converter<String, Map<String, dynamic>> {
  const VdfDecoder();

  @override
  Map<String, dynamic> convert(String input) {
    List<String> lines = input.split('\n');
    Map<String, dynamic> object = {};
    List<dynamic> stack = [object];
    bool expect = false;

    final regex = RegExp(
      '^("((?:\\\\.|[^\\\\"])+)"|([a-z0-9\\-\\_]+))([ \t]*("((?:\\\\.|[^\\\\"])*)(")?|([a-z0-9\\-\\_]+)))?',
    );

    int i = 0;
    final j = lines.length;

    bool comment = false;

    for (; i < j; i++) {
      var line = lines[i].trim();

      if (line.startsWith('/*') && line.endsWith('*/')) {
        continue;
      }

      if (line.startsWith('/*')) {
        comment = true;
        continue;
      }

      if (line.endsWith('*/')) {
        comment = false;
        continue;
      }

      if (comment) {
        continue;
      }
      if (line == '' || line[0] == '/') {
        continue;
      }
      if (line[0] == '{') {
        expect = false;
        continue;
      }
      if (expect) {
        throw FormatException('Invalid syntax on line ${i + 1}.');
      }
      if (line[0] == '}') {
        stack.removeLast();
        continue;
      }

      while (true) {
        var m = regex.firstMatch(line);
        if (m == null) {
          throw FormatException('Invalid syntax on line ${i + 1}.');
        }
        dynamic key = (m[2] != null) ? m[2] : m[3];
        dynamic val = (m[6] != null) ? m[6] : m[8];

        if (val == null) {
          if ((stack[stack.length - 1] as Map)[key] == null) {
            (stack[stack.length - 1] as Map)[key] = {};
          }
          stack.add((stack[stack.length - 1] as Map)[key]);
          expect = true;
        } else {
          if (m[7] == null && m[8] == null) {
            line += '\n${lines[++i]}';
            continue;
          }

          if (val != '' && num.tryParse(val) != null) {
            val = num.parse(val);
          }

          switch (val) {
            case 'true':
              val = true;
            case 'false':
              val = false;
            case 'null' || 'undefined':
              val = null;
          }
          (stack[stack.length - 1] as Map)[key] = val;
        }
        break;
      }
    }

    if (stack.length != 1) {
      throw FormatException('Open parentheses somewhere.');
    }

    return object;
  }
}
