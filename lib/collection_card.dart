// import 'package:anjanitek/products_listing.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'modals/product_tag.dart';

class CollectionCard extends StatefulWidget {

  final ProductTag design;
  final String media;
  final double imageHeight, imageWidth;
  final int zoom;
  // final Product product;
  const CollectionCard({required this.design, required this.media, required this.imageHeight, required this.imageWidth, required this.zoom});
  // CollectionCard({required this.product, required this.design, required this.media, required this.imageHeight, required this.imageWidth});

  @override
  _CollectionCardState createState() => _CollectionCardState();
}

class _CollectionCardState extends State<CollectionCard> {
  double _xOffset = 0.0;
  double _yOffset = 0.0;
  double _elevation = 4.0;

getSizeDetails() {
  
  double ratio = (widget.imageHeight / widget.imageWidth);
  // print(ratio);
  // if(ratio == 1)
      return 190 * ratio * widget.zoom;
  
}

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _xOffset = details.delta.dx;
      _yOffset = details.delta.dy;
      _elevation = 20.0; // Increase elevation while interacting
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _xOffset = 0.0;
      _yOffset = 0.0;
      _elevation = 4.0; // Reset elevation
    });
  }

  @override
  Widget build(BuildContext context) {
    return 
    // GestureDetector(
    //   onPanUpdate: _onPanUpdate,
    //   onPanEnd: _onPanEnd,
    //   child: Transform(
    //     transform: Matrix4.identity()
    //       ..setEntry(3, 2, 0.001) // Perspective
    //       ..rotateX(_yOffset * 0.01)
    //       ..rotateY(_xOffset * 0.01),
    //     alignment: FractionalOffset.center,
    //         child: 
            Container(
              // margin: EdgeInsets.all(16),
              // height: getSizeDetails(),
              height: 300,
              width: MediaQuery.of(context).size.width,
              // width: (190 * widget.zoom).toDouble(),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(50),
                              topRight: Radius.circular(50),
                              bottomLeft: Radius.circular(50),
                              bottomRight: Radius.circular(50),
                              ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: _elevation,
                    spreadRadius: _elevation / 2,
                    offset: Offset(_xOffset, _yOffset))
                ],
              ),
              child: widget.media.length > 1
                  ? Stack(
                    alignment: Alignment.center,
                children: [
                  ClipRRect(
                  // borderRadius: BorderRadius.circular(16),
                  borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(50),
                              topRight: Radius.circular(50),
                              bottomLeft: Radius.circular(50),
                              bottomRight: Radius.circular(50),
                              ),
                  child: Stack(
                    children: [
                    Image.network(
                      'https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/products%2F${widget.media}.webp?alt=media',
                      fit: BoxFit.cover,
                      height: 300,
                      width: MediaQuery.of(context).size.width,
                      // width: (190 * widget.zoom).toDouble(),
                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      } else {
                        double progress = loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : 0;

                        return Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                          color: Colors.grey.shade200, // subtle background color
                          ),
                          FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Container(
                            color: Colors.black12, // fill color from left
                          ),
                          ),
                        ],
                        );
                      }
                      },
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(50),
                              topRight: Radius.circular(50),
                              bottomLeft: Radius.circular(50),
                              bottomRight: Radius.circular(50),
                              ),
                      gradient: LinearGradient(
                        colors: [
                        Colors.black45,
                        Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      ),
                    ),
                    ],
                  ),
                  ),
                  Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.design.name!, style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge,fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white), ),
                    const Spacer(),
                    ],
                  ),
                  ),
                ],
                
              )
                  : Container(
                      margin: const EdgeInsets.all(16),
                      height: 300,
                      width: (190 * widget.zoom).toDouble(),
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
      //       ),
      
      // ),
    );
  }
}