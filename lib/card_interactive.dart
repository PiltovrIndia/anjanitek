import 'package:anjanitek/products_listing.dart';
import 'package:flutter/material.dart';

class CardInteractive extends StatefulWidget {

  final String design;
  final String media;
  final double imageHeight, imageWidth;
  final int zoom;
  final String? productSize;
  // final Product product;
  const CardInteractive({super.key, required this.design, required this.media, required this.imageHeight, required this.imageWidth, required this.zoom, this.productSize});
  // CardInteractive({required this.product, required this.design, required this.media, required this.imageHeight, required this.imageWidth});

  @override
  State<CardInteractive> createState() => _CardInteractiveState();
}

class _CardInteractiveState extends State<CardInteractive> {
  double _xOffset = 0.0;
  double _yOffset = 0.0;
  double _elevation = 4.0;

  List<String> get _parts =>
      (widget.productSize ?? '').split('x').where((s) => s.trim().isNotEmpty).toList();

  bool get _isHexagon => widget.productSize != null && _parts.length == 3;

  // Returns (widthMm, heightMm) for aspect-ratio calculation
  (double, double) get _mmDims {
    try {
      if (widget.productSize != null && _parts.length >= 2) {
        if (_parts.length == 3) {
          // hexagon: "270x467x540" — C is corner-to-corner width, B is flat-to-flat height
          return (double.parse(_parts[2]), double.parse(_parts[1]));
        }
        return (double.parse(_parts[0]), double.parse(_parts[1]));
      }
    } catch (_) {}
    return (widget.imageWidth, widget.imageHeight);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _xOffset = details.delta.dx;
      _yOffset = details.delta.dy;
      _elevation = 20.0;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _xOffset = 0.0;
      _yOffset = 0.0;
      _elevation = 4.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final (wMm, hMm) = _mmDims;

    final double cardWidth = widget.productSize != null
        ? MediaQuery.of(context).size.width * 0.38 * widget.zoom
        : (120 * widget.zoom).toDouble();

    final double cardHeight = cardWidth * (hMm / wMm);

    final imageUrl =
        'https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/products%2F${widget.media}.webp?alt=media';

    Widget imageWidget = Image.network(
      imageUrl,
      fit: BoxFit.cover,
      height: cardHeight,
      width: cardWidth,
      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
        if (loadingProgress == null) return child;
        final double progress = loadingProgress.expectedTotalBytes != null
            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
            : 0;
        return Stack(
          fit: StackFit.expand,
          children: [
            Container(color: Colors.grey.shade200),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(color: Colors.black12),
            ),
          ],
        );
      },
    );

    Widget clippedImage = _isHexagon
        ? ClipPath(
            clipper: _HexagonClipper(),
            child: imageWidget,
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: imageWidget,
          );

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(_yOffset * 0.01)
          ..rotateY(_xOffset * 0.01),
        alignment: FractionalOffset.center,
        child: Container(
          margin: const EdgeInsets.all(16),
          height: cardHeight,
          width: cardWidth,
          decoration: BoxDecoration(
            borderRadius: _isHexagon ? null : BorderRadius.circular(16),
            boxShadow: _isHexagon
                ? null
                : [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: _elevation,
                      spreadRadius: _elevation / 2,
                      offset: Offset(_xOffset, _yOffset),
                    )
                  ],
          ),
          child: widget.media.length > 1
              ? Stack(children: [clippedImage])
              : Container(
                  margin: const EdgeInsets.all(16),
                  height: cardHeight,
                  width: cardWidth,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'No image available',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final double w = size.width;
    final double h = size.height;
    // Flat-top regular hexagon: two horizontal edges, four diagonal edges
    return Path()
      ..moveTo(w / 4, 0)
      ..lineTo(3 * w / 4, 0)
      ..lineTo(w, h / 2)
      ..lineTo(3 * w / 4, h)
      ..lineTo(w / 4, h)
      ..lineTo(0, h / 2)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
