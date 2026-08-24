import 'dart:math';

import 'package:flutter/material.dart';

import '../select_theme.dart';

/// A shimmering wrapper used for loading skeleton UIs.
///
/// The shimmer is applied to [child] via a moving linear gradient shader.
class SkeletonView extends StatefulWidget {
  const SkeletonView({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 2000),
    this.interval = Duration.zero,
    this.colors,
  });

  /// The widget to which the shimmer effect is applied.
  final Widget child;

  /// The duration of a single shimmer sweep across the [child].
  ///
  /// Defaults to 2000ms. After each sweep completes, the animation restarts
  /// (optionally delayed by [interval]).
  final Duration duration;

  /// The delay between consecutive shimmer sweeps.
  ///
  /// Defaults to [Duration.zero], which restarts the sweep immediately. A
  /// non-zero value inserts a pause after each completed sweep before the next
  /// one begins.
  final Duration interval;

  /// The gradient colors used for the shimmer effect.
  ///
  /// If null, a default translucent white gradient is used.
  final List<Color>? colors;

  @override
  State<SkeletonView> createState() => _SkeletonViewState();
}

class _SkeletonViewState extends State<SkeletonView>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  Animation? gradientPosition;

  CurvedAnimation? curvedAnimation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    curvedAnimation = CurvedAnimation(
      parent: controller,
      curve: Curves.linear,
    );
    gradientPosition = Tween<double>(
      begin: -3,
      end: 10,
    ).animate(curvedAnimation!);
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (widget.interval != Duration.zero) {
          Future.delayed(widget.interval, () {
            if (mounted) {
              controller.forward(from: 0);
            }
          });
        } else {
          if (mounted) {
            controller.forward(from: 0);
          }
        }
      }
    });
    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    curvedAnimation?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(gradientPosition?.value ?? 0, 0),
              end: const Alignment(-1, 0),
              colors: widget.colors ??
                  const [
                    Color(0x05FFFFFF),
                    Color(0x80FFFFFF),
                    Color(0x05FFFFFF),
                  ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A rectangular placeholder used inside [SkeletonView].
class SkeletonTile extends StatelessWidget {
  /// The height of the placeholder tile.
  ///
  /// If null, the tile's height is determined by its parent constraints or
  /// content.
  final double? height;

  /// The width of the placeholder tile.
  ///
  /// If null (the default), the tile expands to fill the available width
  /// unless [random] is provided, in which case a randomized width is used.
  final double? width;

  /// The fill color of the placeholder tile.
  ///
  /// If null, [SelectThemeData.backgroundColorHigh] is used.
  final Color? color;

  /// A border to draw around the placeholder tile.
  final BoxBorder? border;

  /// The border radius of the placeholder tile's corners.
  final BorderRadiusGeometry? borderRadius;

  /// An optional source of randomness used to vary the tile's width.
  ///
  /// When provided, the tile width is randomized within the available space
  /// (bounded by [widthUsed]) and [width] is ignored.
  final Random? random;

  /// The horizontal space already consumed, used to bound the randomized
  /// [width] when [random] is provided.
  final double widthUsed;

  const SkeletonTile({
    super.key,
    this.height,
    this.width,
    this.color,
    this.border,
    this.borderRadius,
    this.random,
    this.widthUsed = 0,
  });

  @override
  Widget build(BuildContext context) {
    var effectiveWidth = width;
    if (random != null) {
      final screenHalfWidth = (MediaQuery.sizeOf(context).width ~/ 2).toInt();
      effectiveWidth = (random!.nextInt(screenHalfWidth - widthUsed.toInt()) +
              screenHalfWidth)
          .toDouble();
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: effectiveWidth?.toDouble(),
        height: height,
        decoration: BoxDecoration(
          border: border,
          borderRadius: borderRadius,
          color: color ?? SelectTheme.of(context).backgroundColorHigh,
        ),
      ),
    );
  }
}
