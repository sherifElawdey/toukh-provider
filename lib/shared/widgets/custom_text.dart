import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_fonts.dart';

/// App text using Cairo and theme defaults, with optional overrides.
class CustomText extends StatelessWidget {
  const CustomText(
    this.data, {
    super.key,
    this.style,
    this.color,
    this.fontSize,
    this.maxLines,
    this.textDirection,
    this.textDecoration,
    this.textAlign,
    this.fontWeight,
    this.overflow,
    this.softWrap,
  });

  final String data;
  final TextStyle? style;
  final Color? color;
  final double? fontSize;
  final int? maxLines;
  final TextDirection? textDirection;
  final TextDecoration? textDecoration;
  final TextAlign? textAlign;
  final FontWeight? fontWeight;
  final TextOverflow? overflow;
  final bool? softWrap;

  @override
  Widget build(BuildContext context) {
    var base = style ?? DefaultTextStyle.of(context).style;
    if (base.fontFamily == null || base.fontFamily!.isEmpty) {
      base = base.copyWith(fontFamily: AppFonts.family);
    }
    if (color != null) {
      base = base.copyWith(color: color);
    }
    if (fontSize != null) {
      base = base.copyWith(fontSize: fontSize);
    }
    if (fontWeight != null) {
      base = base.copyWith(fontWeight: fontWeight);
    }
    if (textDecoration != null) {
      base = base.copyWith(decoration: textDecoration);
    }
    return Text(
      data.tr,
      style: base,
      maxLines: maxLines,
      textDirection: textDirection,
      textAlign: textAlign,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}
