import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const GoogleSignInButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AC.surface(context),
          side: BorderSide(color: AC.div(context), width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _GoogleLogo(),
            const SizedBox(width: 10),
            Text(
              'Continue with Google',
              style: TextStyle(
                color: AC.text(context),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AC.div(context))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: TextStyle(color: AC.textSec(context), fontSize: 13),
          ),
        ),
        Expanded(child: Divider(color: AC.div(context))),
      ],
    );
  }
}

// Google "G" logo painted manually — no image asset needed
class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Clip to circle
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius)));

    final paint = Paint()..style = PaintingStyle.fill;

    // Background
    paint.color = Colors.white;
    canvas.drawCircle(center, radius, paint);

    final r = radius * 0.7;

    // Red (top-right)
    paint.color = const Color(0xFFEA4335);
    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(Rect.fromCircle(center: center, radius: r), -0.52, 2.09, false)
        ..close(),
      paint,
    );

    // Green (bottom-left)
    paint.color = const Color(0xFF34A853);
    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(Rect.fromCircle(center: center, radius: r), 1.57, 2.09, false)
        ..close(),
      paint,
    );

    // Yellow (bottom-right area)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(Rect.fromCircle(center: center, radius: r), 3.67, 1.05, false)
        ..close(),
      paint,
    );

    // Blue (top-left)
    paint.color = const Color(0xFF4285F4);
    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(Rect.fromCircle(center: center, radius: r), 4.71, 1.05, false)
        ..close(),
      paint,
    );

    // White center circle
    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.42, paint);

    // Blue horizontal bar (the "G" crossbar)
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(center.dx, center.dy - radius * 0.12, radius * 0.72, radius * 0.24),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
