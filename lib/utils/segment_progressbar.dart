import 'dart:ui';

import 'package:flutter/material.dart';

Widget BuildSegmentedProgressBar(double safeProgress, Color progressColor) {
    const totalSegments = 50;
    const gap = 1.2;
    final filledSegments =
        (safeProgress * totalSegments).round().clamp(0, totalSegments);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      // decoration: BoxDecoration(
      //   borderRadius: BorderRadius.circular(14),
      //   color: Colors.white.withValues(alpha: 0.45),
      //   border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
      //   boxShadow: [
      //     BoxShadow(
      //       color: progressColor.withValues(alpha: 0.12),
      //       blurRadius: 14,
      //       spreadRadius: 0.5,
      //       offset: const Offset(0, 4),
      //     ),
      //   ],
      // ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalGap = (totalSegments - 1) * gap;
          final segmentWidth =
              ((constraints.maxWidth - totalGap) / totalSegments)
                  .clamp(1.0, 6.0);

          return Row(
            children: List.generate(totalSegments, (index) {
              final isFilled = index < filledSegments;

              return Container(
                width: segmentWidth,
                height: 12,
                margin: EdgeInsets.only(
                    right: index == totalSegments - 1 ? 0 : gap),
                decoration: BoxDecoration(
                  color: isFilled
                      ? progressColor
                      : progressColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(2.5),
                  boxShadow: isFilled
                      ? [
                          BoxShadow(
                            color: progressColor.withValues(alpha: 0.25),
                            blurRadius: 2,
                            spreadRadius: 0.3,
                          ),
                        ]
                      : null,
                ),
              );
            }),
          );
        },
      ),
    );
  }



  Widget BuildSegmentedProgressBar2(double safeProgress, Color progressColor) {
    const totalSegments = 50;
    const gap = 1.2;
    final filledSegments =
        (safeProgress * totalSegments).round().clamp(0, totalSegments);

    return Container(
      // padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      // decoration: BoxDecoration(
      //   borderRadius: BorderRadius.circular(14),
      //   color: Colors.white.withValues(alpha: 0.45),
      //   border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
      //   boxShadow: [
      //     BoxShadow(
      //       color: progressColor.withValues(alpha: 0.12),
      //       blurRadius: 14,
      //       spreadRadius: 0.5,
      //       offset: const Offset(0, 4),
      //     ),
      //   ],
      // ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalGap = (totalSegments - 1) * gap;
          final segmentWidth =
              ((constraints.maxWidth - totalGap) / totalSegments)
                  .clamp(1.0, 6.0);

          return Row(
            children: List.generate(totalSegments, (index) {
              final isFilled = index < filledSegments;

              return Container(
                width: segmentWidth,
                height: 2,
                margin: EdgeInsets.only(
                    right: index == totalSegments - 1 ? 0 : gap),
                decoration: BoxDecoration(
                  color: isFilled
                      ? progressColor
                      : Colors.black12,
                  borderRadius: BorderRadius.circular(2.5),
                  boxShadow: isFilled
                      ? [
                          BoxShadow(
                            color: progressColor.withValues(alpha: 0.15),
                            blurRadius: 1,
                            spreadRadius: 0.3,
                          ),
                        ]
                      : null,
                ),
              );
            }),
          );
        },
      ),
    );
  }