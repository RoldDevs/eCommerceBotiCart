import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double width;
  final double height;

  const AppLogo({
    super.key,
    this.width = 250.0,
    this.height = 70.0,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/botiCartLogo.png',
      width: width,
      height: height,
    );
  }
}