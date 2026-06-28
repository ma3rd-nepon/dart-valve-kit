import 'package:dart_valve_kit/dart_valve_kit.dart';
import 'package:test/test.dart';

void main() {
  final vtf = VTFFile.fromFile("test/parse_test.vtf");

  test('VDF parsing', () {
    expect(VDFFile.fromFile("test/parse_test.vdf")["libraryfolders"]["0"]["path"], equals("C:\\Program Files (x86)\\Steam"));
  });
  test('VTF parsing', () {
    expect(vtf.frameData?.length, equals(vtf.width * vtf.height * 4));
  });
}
