import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../../../../core/widgets/app_logo.dart';
import '../../../auth/presentation/screens/login_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.ease;

            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var _ = animation.drive(tween);

            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              const AppLogo(
                width: 250.0,
                height: 70.0,
              ),
              AutoSizeText(
                'Empowering Pharmacies. Simplifying Care.',
                maxLines: 1,
                minFontSize: 10,
                style: TextStyle(
                  fontFamily: GoogleFonts.poppins().fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3BBFB2),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AutoSizeText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int maxLines;
  final double minFontSize;

  const AutoSizeText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines = 1,
    this.minFontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textSpan = TextSpan(
          text: text,
          style: style,
        );
        
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          maxLines: maxLines,
          textAlign: textAlign ?? TextAlign.start,
        );
        
        double fontSize = style?.fontSize ?? 14;

        do {
          textPainter.textScaler = TextScaler.linear(
            fontSize / (style?.fontSize ?? 14),
          );
          textPainter.layout(maxWidth: constraints.maxWidth);

          if (textPainter.didExceedMaxLines || textPainter.width > constraints.maxWidth) {
            fontSize -= 0.5;
          } else {
            break;
          }
        } while (fontSize >= minFontSize);
        
        return Text(
          text,
          style: style?.copyWith(fontSize: fontSize),
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: TextOverflow.visible,
        );
      },
    );
  }
}