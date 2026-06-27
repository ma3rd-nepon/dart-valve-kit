class VTFHeader {
  double version = 0.0;
  VTFImageFlag flags = VTFImageFlag(0);
  List<double> reflectivity = [0, 0, 0];
  double bumpmapScale = 0.0;
}

class VTFImageFlag {
  final int value;

  const VTFImageFlag(this.value);

  bool hasFlag(VTFImageFlag flag) => (value & flag.value) != 0;

  static const TEXTUREFLAGS_POINTSAMPLE = VTFImageFlag(0x00000001);
  static const TEXTUREFLAGS_TRILINEAR = VTFImageFlag(0x00000002);
  static const TEXTUREFLAGS_CLAMPS = VTFImageFlag(0x00000004);
  static const TEXTUREFLAGS_CLAMPT = VTFImageFlag(0x00000008);
  static const TEXTUREFLAGS_ANISOTROPIC = VTFImageFlag(0x00000010);
  static const TEXTUREFLAGS_HINT_DXT5 = VTFImageFlag(0x00000020);
  static const TEXTUREFLAGS_SRGB = VTFImageFlag(0x00000040);
  static const TEXTUREFLAGS_NORMAL = VTFImageFlag(0x00000080);
  static const TEXTUREFLAGS_NOMIP = VTFImageFlag(0x00000100);
  static const TEXTUREFLAGS_NOLOD = VTFImageFlag(0x00000200);
  static const TEXTUREFLAGS_ALL_MIPS = VTFImageFlag(0x00000400);
  static const TEXTUREFLAGS_PROCEDURAL = VTFImageFlag(0x00000800);
  static const TEXTUREFLAGS_ONEBITALPHA = VTFImageFlag(0x00001000);
  static const TEXTUREFLAGS_EIGHTBITALPHA = VTFImageFlag(0x00002000);
  static const TEXTUREFLAGS_ENVMAP = VTFImageFlag(0x00004000);
  static const TEXTUREFLAGS_RENDERTARGET = VTFImageFlag(0x00008000);
  static const TEXTUREFLAGS_DEPTHRENDERTARGET = VTFImageFlag(0x00010000);
  static const TEXTUREFLAGS_NODEBUGOVERRIDE = VTFImageFlag(0x00020000);
  static const TEXTUREFLAGS_SINGLECOPY = VTFImageFlag(0x00040000);
  static const TEXTUREFLAGS_NODEPTHBUFFER = VTFImageFlag(0x00800000);
  static const TEXTUREFLAGS_CLAMPU = VTFImageFlag(0x02000000);
  static const TEXTUREFLAGS_VERTEXTEXTURE = VTFImageFlag(0x04000000);
  static const TEXTUREFLAGS_SSBUMP = VTFImageFlag(0x08000000);
  static const TEXTUREFLAGS_BORDER = VTFImageFlag(0x20000000);

  static VTFImageFlag fromValue(int value) => VTFImageFlag(value);
}
