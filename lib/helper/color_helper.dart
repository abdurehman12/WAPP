import 'dart:ui';

class ColorHelper {
  static Color? hexCodeToColor(String? code){
    int? colorCode = int.tryParse(code?.replaceAll('#', '0xff') ?? '');

    return colorCode == null ? null : Color(colorCode);
  }
}