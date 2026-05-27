import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LaboratoryBackground extends StatefulWidget {
  final Widget? child;
  const LaboratoryBackground({super.key, this.child});

  @override
  State<LaboratoryBackground> createState() => _LaboratoryBackgroundState();
}

class _LaboratoryBackgroundState extends State<LaboratoryBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF050A0E) : const Color(0xFFF0F4F8);

    return Stack(
      children: [
        // Base Background
        Container(color: bgColor),
        
        // Rotating Grid Layer 1 (Slow, Large)
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _controller.value * 2 * math.pi,
                child: Transform.scale(
                  scale: 2.5,
                  child: CustomPaint(
                    painter: GridPainter(
                      color: AppTheme.accentColor.withOpacity(isDark ? 0.05 : 0.08),
                      spacing: 60,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Rotating Grid Layer 2 (Fast, Small)
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: -_controller.value * 1.5 * math.pi,
                child: Transform.scale(
                  scale: 2.2,
                  child: CustomPaint(
                    painter: GridPainter(
                      color: AppTheme.accentColor.withOpacity(isDark ? 0.03 : 0.05),
                      spacing: 30,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Subtle Radial Gradient Overlay for depth
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  bgColor.withOpacity(0.4),
                  bgColor,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class GridPainter extends CustomPainter {
  final Color color;
  final double spacing;

  GridPainter({required this.color, required this.spacing});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    // Draw vertical lines
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    
    // Draw dots at intersections for more "technical" feel (Optimized for performance)
    final dotPaint = Paint()
      ..color = color.withOpacity(color.opacity * 2)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final List<double> points = [];
    for (double x = 0; x <= size.width; x += spacing) {
      for (double y = 0; y <= size.height; y += spacing) {
        points.add(x);
        points.add(y);
      }
    }
    
    if (points.isNotEmpty) {
      canvas.drawRawPoints(ui.PointMode.points, Float32List.fromList(points), dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) =>
      color != oldDelegate.color || spacing != oldDelegate.spacing;
}
