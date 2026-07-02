import 'package:flutter/material.dart';

class ShimmerText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerText({
    super.key,
    required this.text,
    required this.style,
    this.baseColor = Colors.black,
    this.highlightColor = const Color(0xFFF5F5F5),
  });

  @override
  State<ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize controller for the animation speed (e.g., 1.5 seconds)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(); // Repeat indefinitely
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Helper method to define the moving gradient
  LinearGradient _buildGradient(double angle) {
    // The gradient colors define the shimmer appearance
    final gradientColors = [
      widget.baseColor,
      widget.highlightColor,
      widget.baseColor,
    ];

    // Stops control the size of the highlight
    const gradientStops = [0.1, 0.5, 0.9];

    return LinearGradient(
      colors: gradientColors,
      stops: gradientStops,
      // Apply the sliding transformation
      transform: _SlidingGradientTransform(angle: angle),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. AnimatedBuilder drives the animation
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Calculate the translation value for the gradient: -1.0 to 1.0
        final double angle = _controller.value * 2.0 - 1.0;

        // 2. ShaderMask applies the gradient
        return ShaderMask(
          // Define the moving gradient based on the bounds of the Text widget
          shaderCallback: (bounds) {
            return _buildGradient(angle).createShader(
              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
            );
          },
          // BlendMode.srcIn ensures the gradient only appears within the opaque shape (the text characters)
          blendMode: BlendMode.srcIn,
          
          // 3. Child Widget: The Text to be shimmered
          child: Text(
            widget.text,
            // Crucial: Set the text color to an opaque color (e.g., white)
            // This defines the shape that the gradient will be masked onto.
            style: widget.style.copyWith(color: Colors.white), 
          ),
        );
      },
    );
  }
}

// Custom Gradient Transform to make the LinearGradient appear to slide
class _SlidingGradientTransform extends GradientTransform {
  final double angle;

  const _SlidingGradientTransform({required this.angle});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    // Creates a translation matrix that moves the gradient horizontally across the text width.
    // The factor `angle` goes from -1.0 to 1.0, ensuring the gradient slides completely off and on.
    return Matrix4.translationValues(bounds.width * angle, 0, 0);
  }
}