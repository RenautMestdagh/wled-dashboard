import 'package:flutter/cupertino.dart';

class WLEDInstance with ChangeNotifier {
  final int id;
  final String ip;
  String name;
  bool supportsRGB;
  bool supportsWhite;
  bool supportsCCT;

  WLEDInstance({
    required this.id,
    required this.ip,
    required this.name,
    required this.supportsRGB,
    required this.supportsWhite,
    required this.supportsCCT,
  });

  factory WLEDInstance.fromJson(Map<String, dynamic> json) {
    return WLEDInstance(
      id: json['id'],
      ip: json['ip'],
      name: '',
      supportsRGB: false,
      supportsWhite: false,
      supportsCCT: false,
    );
  }
}