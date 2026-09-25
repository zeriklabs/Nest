import 'package:flutter/material.dart';

class NestIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final bool useGradient;

  const NestIcon({
    super.key,
    required this.size,
    this.color,
    this.useGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _NestIconPainter(
          color: color ?? Colors.white,
          useGradient: useGradient,
        ),
      ),
    );
  }
}

class _NestIconPainter extends CustomPainter {
  final Color color;
  final bool useGradient;

  _NestIconPainter({
    required this.color,
    required this.useGradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100;
    // Reducido el stroke y ajustadas las coordenadas para que sea más pequeño y estilizado
    final strokeWidth = 25.0 * scale;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (useGradient) {
      // Pilar Derecho
      paint.shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF6366F1),
          Color(0xFF312E81),
        ],
      ).createShader(Rect.fromLTWH(70.8 * scale, 26 * scale, strokeWidth, 48 * scale));

      canvas.drawLine(
        Offset(70.8 * scale, 26 * scale),
        Offset(70.8 * scale, 74 * scale),
        paint,
      );

      // Diagonal
      paint.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF9575CD).withOpacity(0.85),
          const Color(0xFF6A1B9A).withOpacity(0.9),
          const Color(0xFF4338CA).withOpacity(0.95),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(29.2 * scale, 26 * scale, 41.6 * scale, 48 * scale));

      final path = Path()
        ..moveTo(29.2 * scale, 26 * scale)
        ..quadraticBezierTo(50 * scale, 46 * scale, 70.8 * scale, 74 * scale);
      canvas.drawPath(path, paint);

      // Pilar Izquierdo
      paint.shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFF6A1B9A).withOpacity(0.65),
          const Color(0xFF9575CD).withOpacity(0.65),
        ],
      ).createShader(Rect.fromLTWH(29.2 * scale, 26 * scale, strokeWidth, 48 * scale));

      canvas.drawLine(
        Offset(29.2 * scale, 26 * scale),
        Offset(29.2 * scale, 74 * scale),
        paint,
      );
    } else {
      paint.shader = null;
      paint.color = color;

      canvas.drawLine(Offset(70.8 * scale, 26 * scale), Offset(70.8 * scale, 74 * scale), paint);

      final path = Path()
        ..moveTo(29.2 * scale, 26 * scale)
        ..quadraticBezierTo(50 * scale, 46 * scale, 70.8 * scale, 74 * scale);
      canvas.drawPath(path, paint);

      canvas.drawLine(Offset(29.2 * scale, 26 * scale), Offset(29.2 * scale, 74 * scale), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NestIconPainter oldDelegate) =>
      oldDelegate.useGradient != useGradient || oldDelegate.color != color;
}
