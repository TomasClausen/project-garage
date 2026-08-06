import 'package:flutter/material.dart';

class AppShadows {
  AppShadows._();

  static const none = <BoxShadow>[];
  static const elevated = <BoxShadow>[
    BoxShadow(color: Color(0x40000000), blurRadius: 18, offset: Offset(0, 8)),
  ];
}
