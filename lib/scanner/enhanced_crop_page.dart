import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class EnhancedCropPage extends StatefulWidget {
  final XFile imageFile;

  const EnhancedCropPage({super.key, required this.imageFile});

  @override
  State<EnhancedCropPage> createState() => _EnhancedCropPageState();
}

class _EnhancedCropPageState extends State<EnhancedCropPage> {
  double _topPercent = 0.3;
  double _bottomPercent = 0.7;
  double _leftPercent = 0.1;
  double _rightPercent = 0.9;

  bool _isMovingBox = false;
  double _lastTouchDx = 0;
  double _lastTouchDy = 0;

  static const double _edgeThreshold = 0.04;

  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _loadImageBytes();
  }

  Future<void> _loadImageBytes() async {
    try {
      _imageBytes = await widget.imageFile.readAsBytes();
    } catch (_) {}
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('调整识别范围', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: SizedBox(
              width: 56,
              height: 56,
              child: IconButton(
                icon: const Icon(Icons.check, color: Colors.blue, size: 32),
                onPressed: _processCrop,
                tooltip: '确认裁剪',
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) {
              if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) return;
              final relativeX =
                  details.localPosition.dx / constraints.maxWidth;
              final relativeY =
                  details.localPosition.dy / constraints.maxHeight;

              final distTop = (relativeY - _topPercent).abs();
              final distBottom = (relativeY - _bottomPercent).abs();
              final distLeft = (relativeX - _leftPercent).abs();
              final distRight = (relativeX - _rightPercent).abs();

              final isInside = relativeX > _leftPercent &&
                  relativeX < _rightPercent &&
                  relativeY > _topPercent &&
                  relativeY < _bottomPercent;

              final isNearEdge = distTop < _edgeThreshold ||
                  distBottom < _edgeThreshold ||
                  distLeft < _edgeThreshold ||
                  distRight < _edgeThreshold;

              _isMovingBox = isInside && !isNearEdge;
              _lastTouchDx = relativeX;
              _lastTouchDy = relativeY;
            },
            onPanUpdate: (details) {
              if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) return;
              final relativeX =
                  details.localPosition.dx / constraints.maxWidth;
              final relativeY =
                  details.localPosition.dy / constraints.maxHeight;

              setState(() {
                if (_isMovingBox) {
                  final dx = relativeX - _lastTouchDx;
                  final dy = relativeY - _lastTouchDy;
                  final boxWidth = _rightPercent - _leftPercent;
                  final boxHeight = _bottomPercent - _topPercent;

                  double newLeft = _leftPercent + dx;
                  double newRight = _rightPercent + dx;
                  double newTop = _topPercent + dy;
                  double newBottom = _bottomPercent + dy;

                  if (newLeft < 0) {
                    newLeft = 0;
                    newRight = boxWidth;
                  }
                  if (newRight > 1) {
                    newRight = 1;
                    newLeft = 1 - boxWidth;
                  }
                  if (newTop < 0) {
                    newTop = 0;
                    newBottom = boxHeight;
                  }
                  if (newBottom > 1) {
                    newBottom = 1;
                    newTop = 1 - boxHeight;
                  }

                  _leftPercent = newLeft.clamp(0.0, 1.0);
                  _rightPercent = newRight.clamp(0.0, 1.0);
                  _topPercent = newTop.clamp(0.0, 1.0);
                  _bottomPercent = newBottom.clamp(0.0, 1.0);

                  _lastTouchDx = relativeX;
                  _lastTouchDy = relativeY;
                  return;
                }

                final distTop = (relativeY - _topPercent).abs();
                final distBottom = (relativeY - _bottomPercent).abs();
                final distLeft = (relativeX - _leftPercent).abs();
                final distRight = (relativeX - _rightPercent).abs();

                final minDist = [
                  distTop,
                  distBottom,
                  distLeft,
                  distRight,
                ].reduce((a, b) => a < b ? a : b);

                if (minDist == distTop) {
                  _topPercent = relativeY.clamp(0.0, _bottomPercent);
                } else if (minDist == distBottom) {
                  _bottomPercent = relativeY.clamp(_topPercent, 1.0);
                } else if (minDist == distLeft) {
                  _leftPercent = relativeX.clamp(0.0, _rightPercent);
                } else if (minDist == distRight) {
                  _rightPercent = relativeX.clamp(_leftPercent, 1.0);
                }
              });
            },
            onPanEnd: (_) {
              _isMovingBox = false;
            },
            child: Stack(
              children: [
                Center(
                  child: _imageBytes == null
                      ? const Center(child: CircularProgressIndicator())
                      : Image.memory(_imageBytes!, fit: BoxFit.contain),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: CropOverlayPainter(
                      topPercent: _topPercent,
                      bottomPercent: _bottomPercent,
                      leftPercent: _leftPercent,
                      rightPercent: _rightPercent,
                    ),
                  ),
                ),
                _buildHorizontalHandle(
                  constraints.maxHeight * _topPercent,
                  true,
                ),
                _buildHorizontalHandle(
                  constraints.maxHeight * _bottomPercent,
                  false,
                ),
                _buildVerticalHandle(
                  constraints.maxWidth * _leftPercent,
                  true,
                ),
                _buildVerticalHandle(
                  constraints.maxWidth * _rightPercent,
                  false,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalHandle(double y, bool isTop) {
    return Positioned(
      top: y - 10,
      left: 0,
      right: 0,
      child: Container(
        height: 20,
        color: Colors.transparent,
        child: Center(
          child: Container(
            width: 60,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalHandle(double x, bool isLeft) {
    return Positioned(
      left: x - 10,
      top: 0,
      bottom: 0,
      child: Container(
        width: 20,
        color: Colors.transparent,
        child: Center(
          child: Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _processCrop() async {
    final bytes = await widget.imageFile.readAsBytes();
    final decodedImage = img.decodeImage(bytes);
    if (decodedImage == null) return;

    final int x = (decodedImage.width * _leftPercent).toInt();
    final int y = (decodedImage.height * _topPercent).toInt();
    final int width =
        (decodedImage.width * (_rightPercent - _leftPercent)).toInt();
    final int height =
        (decodedImage.height * (_bottomPercent - _topPercent)).toInt();

    final croppedImage = img.copyCrop(
      decodedImage,
      x: x,
      y: y,
      width: width,
      height: height,
    );
    final croppedBytes = Uint8List.fromList(img.encodeJpg(croppedImage));

    // Web 上无法写本地文件，用内存 bytes 构造 XFile；原生沿用写临时文件的老逻辑。
    XFile resultFile;
    if (kIsWeb) {
      resultFile = XFile.fromData(croppedBytes, mimeType: 'image/jpeg');
    } else {
      final croppedPath =
          widget.imageFile.path.replaceAll('.jpg', '_cropped.jpg');
      File(croppedPath).writeAsBytesSync(croppedBytes);
      resultFile = XFile(croppedPath);
    }

    if (mounted) Navigator.pop(context, resultFile);
  }
}

class CropOverlayPainter extends CustomPainter {
  final double topPercent;
  final double bottomPercent;
  final double leftPercent;
  final double rightPercent;

  CropOverlayPainter({
    required this.topPercent,
    required this.bottomPercent,
    required this.leftPercent,
    required this.rightPercent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.6);
    final topY = size.height * topPercent;
    final bottomY = size.height * bottomPercent;
    final leftX = size.width * leftPercent;
    final rightX = size.width * rightPercent;

    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, topY), paint);
    canvas.drawRect(Rect.fromLTRB(0, bottomY, size.width, size.height), paint);
    canvas.drawRect(Rect.fromLTRB(0, topY, leftX, bottomY), paint);
    canvas.drawRect(Rect.fromLTRB(rightX, topY, size.width, bottomY), paint);

    final borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(
      Rect.fromLTRB(leftX, topY, rightX, bottomY),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(CropOverlayPainter oldDelegate) => true;
}
