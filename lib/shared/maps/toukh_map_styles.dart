import 'package:flutter/material.dart';

/// Light (day) and dark (night) Google Maps JSON styles for Toukh apps.
abstract final class ToukhMapStyles {
  static const String light = r'''
[
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#A7D8FF"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#F4F9FF"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#FFFFFF"},{"weight":2}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#D6EAFF"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#5BA8FF"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#FFFFFF"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#DFF1FF"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#C8F0D0"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative","elementType":"labels.text.fill","stylers":[{"color":"#5A6B7A"}]},
  {"featureType":"poi.business","elementType":"labels.text.fill","stylers":[{"color":"#4A90E2"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#4A90E2"}]},
  {"featureType":"road","elementType":"labels.text.stroke","stylers":[{"color":"#FFFFFF"}]},
  {"featureType":"poi","elementType":"labels.icon","stylers":[{"saturation":20}]}
]
''';

  static const String dark = r'''
[
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#13293D"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#1A1D24"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#2B3440"},{"weight":2}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#344252"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3B82F6"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#FFFFFF"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#243140"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#1F3A2A"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative","elementType":"labels.text.fill","stylers":[{"color":"#A0AEC0"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#C7D2FE"}]},
  {"featureType":"road","elementType":"labels.text.stroke","stylers":[{"color":"#1A1D24"}]},
  {"featureType":"poi.business","elementType":"labels.text.fill","stylers":[{"color":"#60A5FA"}]},
  {"featureType":"poi.medical","elementType":"labels.text.fill","stylers":[{"color":"#93C5FD"}]},
  {"featureType":"poi.school","elementType":"labels.text.fill","stylers":[{"color":"#93C5FD"}]}
]
''';

  static String styleForBrightness(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }
}
