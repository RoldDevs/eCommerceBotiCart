import 'package:flutter/material.dart';

class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.arrow_back_ios_new,
            size: 16,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}