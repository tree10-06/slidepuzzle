import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;

void main() {
  runApp(const Center(
      child: SizedBox(
        width: 700, // or any fixed width like a mobile screen
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Slide Puzzle',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SlidePuzzle(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Stateful widget for testing
class SlidePuzzle extends StatefulWidget {
  const SlidePuzzle({Key? key}) : super(key: key);

  @override
  State<SlidePuzzle> createState() => _SlidePuzzleState();
}

class _SlidePuzzleState extends State<SlidePuzzle> {
  // default put 2
  int valueSlider = 2;
  final GlobalKey<_SlidePuzzleWidgetState> globalKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    double border = 5;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Sliding Puzzle Game for BB",
          style: TextStyle(
            color: Color(0xff225f87),
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // reload button for testing
          InkWell(
            child: const Icon(Icons.refresh),
            onTap: () => globalKey.currentState?.generatePuzzle(),
          )
        ],
      ),
      body: Container(
        height: double.maxFinite,
        width: double.maxFinite,
        color: const ui.Color.fromARGB(255, 101, 170, 248),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const ui.Color.fromARGB(255, 71, 171, 238),
                  border: Border.all(width: border, color: const ui.Color.fromARGB(255, 75, 151, 202)!),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SizedBox(
                      width: constraints.biggest.width,
                      child: SlidePuzzleWidget(
                        key: globalKey,
                        size: constraints.biggest,
                        sizePuzzle: valueSlider,
                        imageBckGround: const Image(
                          // You can use your own image - make sure to add it to pubspec.yaml
                          // For now, using a placeholder that will show colored squares
                          image: AssetImage("images/logo1.png"),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                child: Slider(
                  min: 2,
                  max: 15,
                  divisions: 13,
                  activeColor: Colors.lightBlueAccent,
                  label: valueSlider.toString(),
                  value: valueSlider.toDouble(),
                  onChanged: (value) {
                    setState(() {
                      valueSlider = value.toInt();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Stateful widget
class SlidePuzzleWidget extends StatefulWidget {
  final Size size;
  final double innerPadding;
  final Image? imageBckGround;
  final int sizePuzzle;

  const SlidePuzzleWidget({
    Key? key,
    required this.size,
    this.innerPadding = 5,
    this.imageBckGround,
    required this.sizePuzzle,
  }) : super(key: key);

  @override
  State<SlidePuzzleWidget> createState() => _SlidePuzzleWidgetState();
}

class _SlidePuzzleWidgetState extends State<SlidePuzzleWidget> {
  final GlobalKey _globalKey = GlobalKey();
  late Size size;

  // list array slide objects
  List<SlideObject>? slideObjects;
  // image load with renderer
  img.Image? fullImage;
  // success flag
  bool success = false;
  // flag already start slide
  bool startSlide = false;
  // save current swap process for reverse checking
  List<int> process = [];
  // flag finish swap
  bool finishSwap = false;

  @override
  Widget build(BuildContext context) {
    size = Size(
      widget.size.width - widget.innerPadding * 2,
      widget.size.width - widget.innerPadding,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: const BoxDecoration(color: ui.Color.fromARGB(255, 206, 202, 202)),
          width: widget.size.width,
          height: widget.size.width,
          padding: EdgeInsets.all(widget.innerPadding),
          child: Stack(
            children: [
              // Background image
              if (widget.imageBckGround != null && slideObjects == null) ...[
                RepaintBoundary(
                  key: _globalKey,
                  child: Container(
                    // padding: const EdgeInsets.all(10),
                    color: Colors.white,
                    height: double.maxFinite,
                    child: widget.imageBckGround!,
                  ),
                )
              ],
              // Empty puzzle pieces
              if (slideObjects != null)
                ...slideObjects!
                    .where((slideObject) => slideObject.empty)
                    .map((slideObject) {
                  return Positioned(
                    left: slideObject.posCurrent.dx,
                    top: slideObject.posCurrent.dy,
                    child: SizedBox(
                      width: slideObject.size.width,
                      height: slideObject.size.height,
                      child: Container(
                        alignment: Alignment.center,
                        margin: const EdgeInsets.all(2),
                        color: Colors.white24,
                        child: Stack(
                          children: [
                            if (slideObject.image != null) ...[
                              Opacity(
                                opacity: success ? 1 : 0.3,
                                child: slideObject.image!,
                              )
                            ]
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              // Non-empty puzzle pieces
              if (slideObjects != null)
                ...slideObjects!
                    .where((slideObject) => !slideObject.empty)
                    .map((slideObject) {
                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.ease,
                    left: slideObject.posCurrent.dx,
                    top: slideObject.posCurrent.dy,
                    child: GestureDetector(
                      onTap: () => changePos(slideObject.indexCurrent),
                      child: SizedBox(
                        width: slideObject.size.width,
                        height: slideObject.size.height,
                        child: Container(
                          alignment: Alignment.center,
                          margin: const EdgeInsets.all(3),
                          // color: Colors.blue,
                          child: Stack(
                            children: [
                              if (slideObject.image != null) ...[
                                slideObject.image!
                              ],
                              Center(
                                child: Text(
                                  "${slideObject.indexDefault}",
                                  style: const TextStyle(
                                    color: Color(0xff225f87),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
        Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () => generatePuzzle(),
                  child: const Text("Generate"),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: startSlide ? null : () => reversePuzzle(),
                  child: const Text("Reverse"),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () => clearPuzzle(),
                  child: const Text("Clear"),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  // Get render image
  Future<img.Image?> _getImageFromWidget() async {
    try {
      RenderRepaintBoundary? boundary =
          _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      
      if (boundary == null) return null;

      size = boundary.size;
      ui.Image uiImage = await boundary.toImage();
      ByteData? byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) return null;
      
      Uint8List pngBytes = byteData.buffer.asUint8List();
      return img.decodeImage(pngBytes);
    } catch (e) {
      print('Error getting image from widget: $e');
      return null;
    }
  }

  // Method to generate puzzle
  Future<void> generatePuzzle() async {
    finishSwap = false;
    setState(() {});

    // Load render image to crop
    if (widget.imageBckGround != null && fullImage == null) {
      fullImage = await _getImageFromWidget();
    }

    if (fullImage != null) {
      print('Full image width: ${fullImage!.width}');
    }

    // Calculate box size for each puzzle
    Size sizeBox = Size(
      size.width / widget.sizePuzzle,
      size.width / widget.sizePuzzle,
    );

    // Generate puzzle boxes
    slideObjects = List.generate(widget.sizePuzzle * widget.sizePuzzle, (index) {
      Offset offsetTemp = Offset(
        index % widget.sizePuzzle * sizeBox.width,
        index ~/ widget.sizePuzzle * sizeBox.height,
      );

      // Crop image for each piece
      img.Image? tempCrop;
      if (widget.imageBckGround != null && fullImage != null) {
        tempCrop = img.copyCrop(
          fullImage!,
          x: offsetTemp.dx.round(),
          y: offsetTemp.dy.round(),
          width: sizeBox.width.round(),
          height: sizeBox.height.round(),
        );
      }

      return SlideObject(
        posCurrent: offsetTemp,
        posDefault: offsetTemp,
        indexCurrent: index,
        indexDefault: index + 1,
        size: sizeBox,
        image: tempCrop == null
            ? null
            : Image.memory(
                img.encodePng(tempCrop),
                fit: BoxFit.contain,
              ),
      );
    });

    // Set last piece as empty
    slideObjects!.last.empty = true;

    // Shuffle the puzzle
    bool swap = true;
    process = [];

    // Shuffle 20 * size times
    for (var i = 0; i < widget.sizePuzzle * 20; i++) {
      for (var j = 0; j < widget.sizePuzzle ~/ 2; j++) {
        SlideObject slideObjectEmpty = getEmptyObject();
        int emptyIndex = slideObjectEmpty.indexCurrent;
        process.add(emptyIndex);
        int randKey;

        if (swap) {
          // Horizontal swap
          int row = emptyIndex ~/ widget.sizePuzzle;
          randKey = row * widget.sizePuzzle + Random().nextInt(widget.sizePuzzle);
        } else {
          // Vertical swap
          int col = emptyIndex % widget.sizePuzzle;
          randKey = widget.sizePuzzle * Random().nextInt(widget.sizePuzzle) + col;
        }

        changePos(randKey);
        swap = !swap;
      }
    }

    startSlide = false;
    finishSwap = true;
    setState(() {});
  }

  // Get empty slide object from list
  SlideObject getEmptyObject() {
    return slideObjects!.firstWhere((element) => element.empty);
  }

  void changePos(int indexCurrent) {
    if (slideObjects == null) return;

    SlideObject slideObjectEmpty = getEmptyObject();
    int emptyIndex = slideObjectEmpty.indexCurrent;

    int minIndex = min(indexCurrent, emptyIndex);
    int maxIndex = max(indexCurrent, emptyIndex);

    List<SlideObject> rangeMoves = [];

    // Check if same vertical or horizontal line
    if (indexCurrent % widget.sizePuzzle == emptyIndex % widget.sizePuzzle) {
      // Same vertical line
      rangeMoves = slideObjects!
          .where((element) =>
              element.indexCurrent % widget.sizePuzzle ==
              indexCurrent % widget.sizePuzzle)
          .toList();
    } else if (indexCurrent ~/ widget.sizePuzzle == emptyIndex ~/ widget.sizePuzzle) {
      // Same horizontal line
      rangeMoves = slideObjects!;
    } else {
      rangeMoves = [];
    }

    rangeMoves = rangeMoves
        .where((puzzle) =>
            puzzle.indexCurrent >= minIndex &&
            puzzle.indexCurrent <= maxIndex &&
            puzzle.indexCurrent != emptyIndex)
        .toList();

    // Sort based on empty position
    if (emptyIndex < indexCurrent) {
      rangeMoves.sort((a, b) => a.indexCurrent < b.indexCurrent ? 1 : -1);
    } else {
      rangeMoves.sort((a, b) => a.indexCurrent < b.indexCurrent ? -1 : 1);
    }

    // Switch positions
    if (rangeMoves.isNotEmpty) {
      int tempIndex = rangeMoves[0].indexCurrent;
      Offset tempPos = rangeMoves[0].posCurrent;

      for (var i = 0; i < rangeMoves.length - 1; i++) {
        rangeMoves[i].indexCurrent = rangeMoves[i + 1].indexCurrent;
        rangeMoves[i].posCurrent = rangeMoves[i + 1].posCurrent;
      }

      rangeMoves.last.indexCurrent = slideObjectEmpty.indexCurrent;
      rangeMoves.last.posCurrent = slideObjectEmpty.posCurrent;

      slideObjectEmpty.indexCurrent = tempIndex;
      slideObjectEmpty.posCurrent = tempPos;
    }

    // Check for success
    if (slideObjects!
                .where((slideObject) =>
                    slideObject.indexCurrent == slideObject.indexDefault - 1)
                .length ==
            slideObjects!.length &&
        finishSwap) {
      print("Success");
      success = true;
    } else {
      success = false;
    }

    startSlide = true;
    setState(() {});
  }

  void clearPuzzle() {
    setState(() {
      startSlide = true;
      slideObjects = null;
      finishSwap = true;
    });
  }

  Future<void> reversePuzzle() async {
    startSlide = true;
    finishSwap = true;
    setState(() {});

    for (int event in process.reversed) {
      await Future.delayed(const Duration(milliseconds: 50));
      changePos(event);
    }

    process = [];
    setState(() {});
  }
}

// Slide object class
class SlideObject {
  Offset posDefault;
  Offset posCurrent;
  int indexDefault;
  int indexCurrent;
  bool empty;
  Size size;
  Image? image;

  SlideObject({
    this.empty = false,
    this.image,
    required this.indexCurrent,
    required this.indexDefault,
    required this.posCurrent,
    required this.posDefault,
    required this.size,
  });
}