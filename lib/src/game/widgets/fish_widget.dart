import 'package:flutter/material.dart';
import 'package:pesca_game/src/game/models/fish_model.dart';

class FishWidget extends StatefulWidget {
  final Fish fish;
  final void Function(Fish) onTapped;

  const FishWidget({super.key, required this.fish, required this.onTapped});

  @override
  State<FishWidget> createState() => _FishWidgetState();
}

class _FishWidgetState extends State<FishWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // Faster blinking
    );
    _opacityAnimation =
        Tween(begin: 0.4, end: 1.0).animate(_animationController);

    if (widget.fish.isStunned) {
      _animationController.repeat(reverse: true);
    } else {
      // Ensure it's fully opaque when not stunned initially.
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant FishWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if the stunned state has changed
    if (widget.fish.isStunned != oldWidget.fish.isStunned) {
      if (widget.fish.isStunned) {
        _animationController.repeat(reverse: true);
      } else {
        // Stop blinking and make sure it's fully opaque.
        _animationController.stop();
        _animationController.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      widget.fish.imagePath,
      width: 80,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 80,
          height: 40,
          color: Colors.red.withOpacity(0.5),
          child: const Center(child: Icon(Icons.error)),
        );
      },
    );

    return Positioned(
      left: widget.fish.position.dx,
      top: widget.fish.position.dy,
      child: GestureDetector(
        onTap: () => widget.onTapped(widget.fish),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationY(widget.fish.goesRight ? 3.14159 : 0),
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: image,
          ),
        ),
      ),
    );
  }
}
