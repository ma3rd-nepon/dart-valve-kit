import 'vtf_parser.dart';

void main() {
  String name = "lev";
  final vtf = VTFFile.fromFile("lib/src/vtf/$name.vtf");

  print("vtf 1 success");
  print('Размер: ${vtf.width}x${vtf.height}');
  print('Версия: ${vtf.header.version}');
  print('Данные: ${vtf.frameData?.length} байт');

  vtf.saveAs("$name.png", ImageFormat.png);
  vtf.saveAs("$name.bmp", ImageFormat.bmp);
  vtf.saveAs("$name.jpg", ImageFormat.jpg);
}
