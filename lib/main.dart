import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

abstract class AnimationInterpreter {
  const AnimationInterpreter();

  bool validFor(ui.Image? image);

  Size size(ui.Image? image, double animationValue, double dpr) {
    return sizeFor(image, 1.0, dpr);
  }

  Size sizeFor(ui.Image? image, double scale, double dpr) {
    scale = scale / dpr;
    return Size((image?.width ?? 0) * scale, (image?.height ?? 0) * scale);
  }

  double? rotation(double animationValue) {
    return null;
  }
}

class ScaleAnimationInterpreter extends AnimationInterpreter {
  const ScaleAnimationInterpreter(this.min, this.max);

  final double min;
  final double max;

  @override
  validFor(ui.Image? image) {
    return (max <= 10 || image == null || image.width < 20);
  }

  @override
  Size size(ui.Image? image, double animationValue, double dpr) {
    double value = 1.0 - ((animationValue - 0.5).abs() * 2.0);
    double scale = (min + value * (max - min));
    return sizeFor(image, scale, dpr);
  }

  String toString() => 'Scale($min <=> $max)';
}

class StaticScaleInterpreter extends AnimationInterpreter {
  const StaticScaleInterpreter(this.scale);

  final double scale;

  @override
  validFor(ui.Image? image) {
    return (scale <= 10 || image == null || image.width < 20);
  }

  @override
  Size size(ui.Image? image, double animationValue, double dpr) {
    return sizeFor(image, scale, dpr);
  }

  String toString() => 'StaticScale($scale)';
}

class RotationAnimationInterpreter extends AnimationInterpreter {
  const RotationAnimationInterpreter([this.scale = 1.0]);

  final double scale;

  @override
  validFor(ui.Image? image) {
    return (scale <= 10 || image == null || image.width < 20);
  }

  @override
  Size size(ui.Image? image, double animationValue, double dpr) {
    return sizeFor(image, scale, dpr);
  }

  @override
  double rotation(double animationValue) {
    return animationValue * 2 * math.pi;
  }

  String toString() => 'Rotate(@ $scale scale)';
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  ui.FilterQuality leftQuality = FilterQuality.none;
  ui.FilterQuality rightQuality = FilterQuality.none;
  Map<String, ui.Image> allImages = {};
  ui.Image? theImage;
  late AnimationController controller = AnimationController(
    vsync: this,
    duration: Duration(seconds: 5),
  );
  static List<AnimationInterpreter> allInterpreters = const [
    ScaleAnimationInterpreter(0.25, 0.5),
    ScaleAnimationInterpreter(0.5, 1.0),
    ScaleAnimationInterpreter(1.0, 5.0),
    ScaleAnimationInterpreter(1.0, 50.0),
    ScaleAnimationInterpreter(0.25, 5.0),
    StaticScaleInterpreter(0.25),
    StaticScaleInterpreter(0.5),
    StaticScaleInterpreter(1.0),
    StaticScaleInterpreter(2.0),
    StaticScaleInterpreter(5.0),
    StaticScaleInterpreter(100.0),
    RotationAnimationInterpreter(0.25),
    RotationAnimationInterpreter(),
    RotationAnimationInterpreter(3.0),
    RotationAnimationInterpreter(50.0),
  ];
  static Map<String, ui.FilterQuality> qualities = const {
    'nearest': ui.FilterQuality.none,
    'bilinear': ui.FilterQuality.low,
    // 'nearestMipmapNearest': const ui.FilterQuality.mipmap(
    //     pixelSampling: ui.PixelSampling.nearest, mipmapSampling: ui.MipmapSampling.nearest),
    // 'bilinearMipmapNearest': const ui.FilterQuality.mipmap(
    //     pixelSampling: ui.PixelSampling.bilinear, mipmapSampling: ui.MipmapSampling.nearest),
    // 'nearestMipmapLinear': const ui.FilterQuality.mipmap(
    //     pixelSampling: ui.PixelSampling.nearest, mipmapSampling: ui.MipmapSampling.bilinear),
    'bilinearMipmapLinear': ui.FilterQuality.medium,
    'cubic': ui.FilterQuality.high,
  };
  AnimationInterpreter interpreter = const StaticScaleInterpreter(1.0);
  double dpr = 1.0;

  @override
  void initState() {
    super.initState();
    controller.addListener(() { setState(() {}); });
    makeImages().then((_) => setState(() {
      controller.repeat();
    }));
  }

  @override
  void dispose() {
    controller.stop();
    controller.dispose();
    super.dispose();
  }

  Future<void> makeImages() async {
    ui.Image mixed = await makeMixedImage();
    ui.Image grid = await makeGridImage();
    ui.Image cross = await makeCrossImage();
    ui.Image colors = await makeColorsImage();
    setState(() {
      allImages = {
        'mix': mixed,
        'grid': grid,
        'cross': cross,
        'colors': colors,
      };
      theImage = mixed;
    });
  }

  Path diamond(Offset center, double size) => Path()
    ..moveTo(center.dx, center.dy - size)
    ..lineTo(center.dx + size, center.dy)
    ..lineTo(center.dx, center.dy + size)
    ..lineTo(center.dx - size, center.dy)
    ..close();

  Future<ui.Image> makeMixedImage() {
    int size = 200;
    Rect bounds = Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());
    Offset center = bounds.center;
    Offset centerPixel = center.translate(0.5, 0.5);
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(recorder, bounds);
    Paint p = Paint();
    p.color = Colors.blue;
    canvas.drawCircle(center, size * .48, p);
    p.color = Colors.white;
    canvas.drawCircle(center, size * .46, p);
    p.color = Colors.blue;
    canvas.drawCircle(center, size * .05, p);
    p.isAntiAlias = false;
    p.style = PaintingStyle.stroke;
    canvas.drawCircle(center, size * .42, p);
    p.color = Colors.black;
    p.isAntiAlias = true;
    canvas.drawPath(diamond(centerPixel, size * .35), p);
    p.isAntiAlias = false;
    canvas.drawPath(diamond(centerPixel, size * .30), p);
    canvas.drawRect(Rect.fromLTWH(size * .40, size * .40, size * .20, size * .20), p);
    return recorder.endRecording().toImage(size, size);
  }

  Future<ui.Image> makeGridImage() {
    int size = 200;
    Rect bounds = Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(recorder, bounds);
    Paint p = Paint();
    p.color = Colors.black;
    p.isAntiAlias = false;
    paintCrosshatches(canvas, bounds, 5, 5, Colors.white, Colors.black);
    return recorder.endRecording().toImage(size, size);
  }

  Future<ui.Image> makeCrossImage() {
    int size = 200;
    Rect bounds = Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(recorder, bounds);
    Paint p = Paint();
    p.isAntiAlias = false;
    p.color = Colors.white;
    canvas.drawPaint(p);
    p.color = Colors.black;
    canvas.drawRect(Rect.fromLTRB(0, 80, 200, 120), p);
    canvas.drawRect(Rect.fromLTRB(80, 0, 120, 200), p);
    return recorder.endRecording().toImage(size, size);
  }

  List<List<Color>> _colors = [
    [ Colors.blue,   Colors.green,  Colors.pink,  Colors.yellow, ],
    [ Colors.orange, Colors.purple, Colors.cyan,  Colors.white, ],
    [ Colors.black,  Colors.lime,   Colors.brown, Colors.indigo, ],
    [ Colors.teal,   Colors.amber,  Colors.grey,  Colors.cyanAccent, ],
  ];
  Future<ui.Image> makeColorsImage() {
    int size = 4;
    Rect bounds = Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(recorder, bounds);
    Paint p = Paint();
    p.isAntiAlias = false;
    double y = 0;
    for (final row in _colors) {
      double x = 0;
      for (final color in row) {
        canvas.drawRect(Rect.fromLTWH(x++, y, 1, 1), p..color = color);
      }
      y++;
    }
    return recorder.endRecording().toImage(size, size);
  }

  paintCrosshatches(Canvas canvas, Rect bounds, double w, double h, Color bg, Color fg) {
    Paint p = Paint();
    p.color = bg;
    canvas.drawRect(bounds, p);
    p.color = fg;
    for (double y = bounds.top; y < bounds.bottom; y += h) {
      canvas.drawRect(Rect.fromLTWH(bounds.left, y, bounds.width, 1), p);
    }
    for (double x = bounds.left; x < bounds.right; x += w) {
      canvas.drawRect(Rect.fromLTWH(x, bounds.top, 1, bounds.height), p);
    }
  }

  Widget imageWidget(ui.FilterQuality quality) {
    Size size = interpreter.size(theImage, controller.value, dpr);
    Widget child = RawImage(
      image: theImage,
      width: size.width,
      height: size.height,
      fit: BoxFit.fill,
      filterQuality: quality,
    );
    double? rotation = interpreter.rotation(controller.value);
    if (rotation != null) {
      child = Transform.rotate(
        angle: rotation,
        child: child,
      );
    }
    return child;
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData? data = MediaQuery.maybeOf(context);
    if (data != null && data.devicePixelRatio != dpr) {
      dpr = data.devicePixelRatio;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                imageWidget(leftQuality),
                imageWidget(rightQuality),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            DropdownButton<ui.FilterQuality>(
              value: leftQuality,
              onChanged: (value) => setState(() => leftQuality = value!),
              items: qualities.entries.map((e) =>
                  DropdownMenuItem(
                    value: e.value,
                    child: Text(e.key),
                  )
              ).toList(),
            ),
            DropdownButton<ui.Image>(
              value: theImage,
              onChanged: (value) => setState(() => theImage = value),
              items: allImages.entries
                  .where((e) => interpreter.validFor(e.value))
                  .map((e) =>
                    DropdownMenuItem(
                      value: e.value,
                      child: Text(e.key),
                    )
                  )
                  .toList(),
            ),
            DropdownButton<AnimationInterpreter>(
              value: interpreter,
              onChanged: (value) => setState(() => interpreter = value!),
              items: allInterpreters
                  .where((interpreter) => interpreter.validFor(theImage))
                  .map((interpreter) => DropdownMenuItem(
                      value: interpreter,
                      child: Text(interpreter.toString()),
                    )
                  )
                  .toList(),
            ),
            DropdownButton<ui.FilterQuality>(
              value: rightQuality,
              onChanged: (value) => setState(() => rightQuality = value!),
              items: qualities.entries.map((e) =>
                  DropdownMenuItem(
                    value: e.value,
                    child: Text(e.key),
                  )
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
