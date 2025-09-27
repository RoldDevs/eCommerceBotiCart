import 'package:flutter/material.dart';

class SocialLoginButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const SocialLoginButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F9FC),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Icon(
          icon,
          size: 30,
          color: Colors.black87,
        ),
      ),
    );
  }
}