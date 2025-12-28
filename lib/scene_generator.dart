import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

import 'bezier_data.dart';

class SceneGenerator {
  final Random rng = Random();
  final Offset center;

  SceneGenerator(this.center);

  List<Color> generatePalette(int mode) {
    // Rastgele renk
    double base = rng.nextDouble() * 360;

    if (mode == 0) {
      // ATOM MODU
      return [
        HSVColor.fromAHSV(1, base, 1, 1).toColor(),
        HSVColor.fromAHSV(1, (base + 120) % 360, 1, 1).toColor(),
        HSVColor.fromAHSV(1, (base + 240) % 360, 1, 1).toColor(),
        const Color(0xFFFFFFFF),
      ];
    }
    if (mode == 1) {
      // MANDALA MODU
      return List.generate(
        5,
        (i) => HSVColor.fromAHSV(1, (base + 30 * i) % 360, 0.8, 1).toColor(),
      );
    }
    // KELEBEK MODU
    return [
      HSVColor.fromAHSV(0.6, base, 0.6, 1).toColor(),
      HSVColor.fromAHSV(0.6, (base + 180) % 360, 0.6, 1).toColor(),
      HSVColor.fromAHSV(0.6, (base + 90) % 360, 0.5, 1).toColor(),
    ];
  }

  //ATOM SİMÜLASYONU
  List<BezierCurveData> buildAtomScene(List<Color> palette) {
    List<BezierCurveData> curves = [];
    Color nucleus = palette.last.withOpacity(0.9); //

    // Çekirdek
    for (int i = 0; i < 15; i++) {
      curves.add(
        _ellipse(
          center,
          10 + rng.nextDouble() * 5,
          5 + rng.nextDouble() * 3,
          rng.nextDouble() * pi,
          nucleus,
          1.8,
          (rng.nextBool() ? 1 : -1) * (0.2 + rng.nextDouble() * 0.1),
        ),
      );
    }

    // Yörüngeler
    for (int s = 1; s <= 5; s++) {
      int orbitCount = 6 + s * 2;
      double rx = 50.0 * s; 
      double ry = 30.0 * s; 
      Color color = palette[s % palette.length].withOpacity(0.7);

      for (int k = 0; k < orbitCount; k++) {
        curves.add(
          _ellipse(
            center,
            rx,
            ry,
            (pi / orbitCount) * k,
            color,
            0.8,
            (s.isEven ? 1 : -1) * 0.02, // Dönüş Hızı
          ),
        );
      }
    }
    return curves;
  }

  //MANDALA
  List<BezierCurveData> buildMandalaScene(List<Color> palette) {
    List<BezierCurveData> curves = [];

    for (int layer = 0; layer < 6; layer++) {
      int petals = 8 + (layer * 4);
      double radius = 60 + (layer * 45);
      Color color = palette[layer % palette.length].withOpacity(0.7);

      Path petal = Path();
      double spread = 0.6; // Yaprak Genişliği

      Offset p1 = Offset(radius * cos(spread), radius * sin(spread));
      Offset p2 = Offset(radius * cos(-spread), radius * sin(-spread));

      petal.moveTo(0, 0);
      petal.cubicTo(p1.dx, p1.dy, p2.dx, p2.dy, 0, 0);

      for (int i = 0; i < petals; i++) {
        double angle = (2 * pi / petals) * i;

        Path rotated = petal.transform(
          (Matrix4.identity()..rotateZ(angle)).storage,
        );

        curves.add(
          BezierCurveData(
            path: rotated,
            color: color,
            strokeWidth: 1.5,
            position: center,
            angle: 0,
            angularVelocity: (layer.isEven ? 1 : -1) * 0.015, // Dönüş Hızı
          ),
        );
      }
    }
    return curves;
  }

  //KELEBEK
  List<BezierCurveData> buildButterflyScene(List<Color> palette) {
    List<BezierCurveData> curves = [];

    for (int i = 0; i < 10; i++) {
      //
      Offset pos = Offset(
        center.dx + (rng.nextDouble() - 0.5) * 300,
        center.dy + (rng.nextDouble() - 0.5) * 400,
      );
      Color color = palette[i % palette.length];
      double scale = 25 + rng.nextDouble() * 10;

      Path butterfly = Path();
      bool first = true;

      // Kelebek Eğrisi
      for (double t = 0; t <= 12 * pi; t += 0.01) {
        double r = exp(cos(t)) - 2 * cos(4 * t) - pow(sin(t / 12), 5);

        double x = r * sin(t) * scale;
        double y = -r * cos(t) * scale;

        if (first) {
          butterfly.moveTo(x, y);
          first = false;
        } else {
          butterfly.lineTo(x, y);
        }
      }

      curves.add(
        BezierCurveData(
          path: butterfly,
          color: color,
          strokeWidth: 1.2,
          position: pos,
          angle: rng.nextDouble() * 2 * pi,
          angularVelocity: (rng.nextDouble() - 0.5) * 0.02,
        ),
      );
    }
    return curves;
  }

  BezierCurveData _ellipse(
    Offset position,
    double rx,
    double ry,
    double tilt,
    Color color,
    double width,
    double velocity,
  ) {
    Path path = Path();

    for (double t = 0; t <= 2 * pi; t += 0.01) {
      //kutupsal koordinatlar
      double x = rx * cos(t);
      double y = ry * sin(t);
      //döndürme matrisi
      double xr = x * cos(tilt) - y * sin(tilt);
      double yr = x * sin(tilt) + y * cos(tilt);

      if (t == 0) {
        path.moveTo(xr, yr);
      } else {
        path.lineTo(xr, yr);
      }
    }
    path.close();
    return BezierCurveData(
      path: path,
      color: color,
      strokeWidth: width,
      position: position,
      angle: 0,
      angularVelocity: velocity,
    );
  }
}
