import 'package:flutter/material.dart';

class LifecycleSlider extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onSlideComplete;

  const LifecycleSlider({
    super.key,
    required this.label,
    required this.onSlideComplete,
    this.color = Colors.blueAccent,
  });

  @override
  State<LifecycleSlider> createState() => _LifecycleSliderState();
}

class _LifecycleSliderState extends State<LifecycleSlider> {
  double _dragPosition = 0;
  final double _sliderHeight = 60;
  final double _thumbSize = 52;
  bool _isCompleted = false;

  void _reset() {
    setState(() {
      _dragPosition = 0;
      _isCompleted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = constraints.maxWidth - _thumbSize - 8;

        return Container(
          height: _sliderHeight,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: widget.color.withValues(alpha: 0.3)),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Track fill
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: _dragPosition + _thumbSize,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(40),
                ),
              ),

              // Label - centered
              Center(
                child: AnimatedOpacity(
                  opacity: _dragPosition > maxDrag * 0.3 ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),

              // Draggable thumb
              Positioned(
                left: _dragPosition + 4,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_isCompleted) return;
                    setState(() {
                      _dragPosition = (_dragPosition + details.delta.dx).clamp(
                        0.0,
                        maxDrag,
                      );
                    });
                  },
                  onHorizontalDragEnd: (_) {
                    if (_dragPosition >= maxDrag * 0.85) {
                      setState(() => _isCompleted = true);
                      widget.onSlideComplete();
                      Future.delayed(const Duration(milliseconds: 600), _reset);
                    } else {
                      setState(() => _dragPosition = 0);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isCompleted ? Icons.check : Icons.chevron_right,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
