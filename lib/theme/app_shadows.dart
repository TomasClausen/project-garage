import 'package:flutter/material.dart';

class AppShadows {
  AppShadows._();

  static const none = <BoxShadow>[];
  static const level0 = none;
  static const level1 = <BoxShadow>[
    BoxShadow(color: Color(0x26000000), blurRadius: 8, offset: Offset(0, 3)),
  ];
  static const level2 = <BoxShadow>[
    BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 5)),
  ];
  static const elevated = level1;
}
