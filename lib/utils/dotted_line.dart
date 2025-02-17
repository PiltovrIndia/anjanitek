
import 'package:flutter/material.dart';

class DottedLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate how many dots can fit based on the available width
        double dotWidth = 1;
        double spaceWidth = 4;
        int numberOfDots = (constraints.maxWidth / (dotWidth + spaceWidth)).floor();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(numberOfDots, (index) {
            return Container(
              width: dotWidth,
              height: 1,
              color: Colors.black54,
            );
          }),
        );
      },
    );
  }
}