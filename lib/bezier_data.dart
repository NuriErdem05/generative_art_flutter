import 'dart:ui';
class BezierCurveData {
  Path path;
  Color color;
  double strokeWidth;
  Offset position;
  double angle;
  double angularVelocity;

  BezierCurveData({
    required this.path,
    required this.color,
    required this.strokeWidth,
    required this.position,
    required this.angle,
    required this.angularVelocity,
  });
}