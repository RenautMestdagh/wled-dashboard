import 'package:flutter/cupertino.dart';

class WLEDInstance with ChangeNotifier {
  final int id;
  final String ip;
  String name;
  bool supportsRGB;

  WLEDInstance({
    required this.id,
    required this.ip,
    required this.name,
    required this.supportsRGB,
  });

  factory WLEDInstance.fromJson(Map<String, dynamic> json) {
    return WLEDInstance(
      id: json['id'],
      ip: json['ip'],
      name: '',
      supportsRGB: false,
    );
  }
}