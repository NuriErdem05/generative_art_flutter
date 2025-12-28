import 'dart:math';
import 'package:flutter/material.dart';
import 'scene_generator.dart'; 
import 'bezier_data.dart';     

void main() => runApp(const BezierApp());

class BezierApp extends StatelessWidget {
  const BezierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF000000),
      ),
      home: const ArtisticBezierHome(),
    );
  }
}

class ArtisticBezierHome extends StatefulWidget {
  const ArtisticBezierHome({super.key});

  @override
  State<ArtisticBezierHome> createState() => _ArtisticBezierHomeState();
}

class _ArtisticBezierHomeState extends State<ArtisticBezierHome>
    with TickerProviderStateMixin {
  
  final List<BezierCurveData> curves = [];
  final Random rng = Random();

  late AnimationController rotationController;
  late AnimationController cameraController;
  late AnimationController drawController;

  String modeName = "Başlatılıyor...";
  Offset center = Offset.zero; 
  bool initialized = false;    
  int modeIndex = 0;           

  // Arka plan gradyan geçişleri için renk paletleri
  List<Color> bgColors = [Colors.black, Colors.black, Colors.black];

  final List<Color> bgMandala = [
    Color(0xFF0F0014), Color(0xFF000000), Color(0xFF000515),
  ];
  final List<Color> bgButterfly = [
    Color(0xFF001005), Color(0xFF000500), Color(0xFF000000),
  ];
  final List<Color> bgAtom = [
    Color(0xFF001515), Color(0xFF000505), Color(0xFF000000),
  ];

  @override
  void initState() {
    super.initState();

    drawController = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    
    rotationController = AnimationController(vsync: this, duration: const Duration(seconds: 60))
      ..repeat();
    rotationController.addListener(() {
      setState(() {
        for (var c in curves) {
          c.angle += c.angularVelocity; 
        }
      });
    });

    cameraController = AnimationController(vsync: this, duration: const Duration(seconds: 12));
    cameraController.addStatusListener((st) {
      if (st == AnimationStatus.completed) generateScene();
    });

    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final size = MediaQuery.of(context).size;
        center = Offset(size.width / 2, size.height / 2);
        initialized = true;
        generateScene(); // İlk sahneyi oluştur
      }
    });
  }

  void generateScene() {
    if (!initialized) return;

    curves.clear(); 

    int mode = modeIndex % 3;
    modeIndex++;

    final generator = SceneGenerator(center);
    final palette = generator.generatePalette(mode); 

    switch (mode) {
      case 0:
        modeName = "Mod: Simetrik Atom Reaktörü";
        bgColors = bgAtom;
        curves.addAll(generator.buildAtomScene(palette));
        break;

      case 1:
        modeName = "Mod: Neon Mandala";
        bgColors = bgMandala;
        curves.addAll(generator.buildMandalaScene(palette));
        break;

      default:
        modeName = "Mod: Fraktal Kelebekler";
        bgColors = bgButterfly;
        curves.addAll(generator.buildButterflyScene(palette));
        break;
    }

    drawController
      ..reset()
      ..forward();

    cameraController
      ..reset()
      ..forward();

    setState(() {}); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(seconds: 3),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: bgColors,
                  stops: const [0, 0.6, 1],
                ),
              ),
            ),
          ),
          
          Positioned.fill(
            child: !initialized
                ? const SizedBox()
                : AnimatedBuilder(
                    animation: Listenable.merge([
                      rotationController,
                      cameraController,
                      drawController
                    ]),
                    builder: (_, __) => CustomPaint(
                      painter: AnimatedScenePainter(
                        curves: curves,
                        camera: cameraController.value,
                        progress: drawController.value,
                        center: center,
                      ),
                    ),
                  ),
          ),
          
          Positioned(
            top: 50,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54, 
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("BİL301S - Generatif Sanat",
                      style: TextStyle(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 5),
                  Text(
                    modeName,
                    style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 120,
                    child: LinearProgressIndicator(
                      value: drawController.value,
                      backgroundColor: Colors.white10,
                      color: Colors.cyanAccent,
                      minHeight: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: generateScene,
        backgroundColor: Colors.cyanAccent,
        label: const Text("Yeni Sahne",
            style: TextStyle(color: Colors.black)),
        icon: const Icon(Icons.refresh, color: Colors.black),
      ),
    );
  }
}

class AnimatedScenePainter extends CustomPainter {
  final List<BezierCurveData> curves;
  final double camera;   
  final double progress; 
  final Offset center;

  AnimatedScenePainter({
    required this.curves,
    required this.camera,
    required this.progress,
    required this.center,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (curves.isEmpty) return;

    Offset mid = size.center(Offset.zero);
    
    // Sinüs dalgası ile zoom efekti 
    double zoom = 1.2 + (sin(camera * pi) * 1.0);

    canvas.save(); // Mevcut canvas durumunu kaydet
    canvas.translate(mid.dx, mid.dy); // Merkeze git
    canvas.scale(zoom);               // Zoom yap
    canvas.translate(-mid.dx, -mid.dy); // Geri gel
    
    canvas.saveLayer(null, Paint()..blendMode = BlendMode.screen);

    for (var c in curves) {
      canvas.save();
      canvas.translate(c.position.dx, c.position.dy);
      canvas.rotate(c.angle);
      
      final p = Paint()
        ..color = c.color
        ..strokeWidth = c.strokeWidth
        ..style = PaintingStyle.stroke;

      if (progress >= 1) {
        canvas.drawPath(c.path, p);
      } else {
        for (var metric in c.path.computeMetrics()) {
          canvas.drawPath(
            metric.extractPath(0, metric.length * progress),
            p,
          );
        }
      }
      canvas.restore(); 
    }
    
    canvas.restore(); 
    canvas.restore(); 
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}