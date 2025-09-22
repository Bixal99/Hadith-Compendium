import 'package:flutter/material.dart';

enum TooltipDirection { top, bottom, left, right }

class MyTooltip extends StatefulWidget {
  final Widget child;
  final String tooltipText;
  final TooltipDirection direction;
  final double distance; // Distance between button and tooltip
  final TextStyle? textStyle;
  final BoxDecoration? decoration;

  const MyTooltip({
    super.key,
    required this.child,
    required this.tooltipText,
    this.direction = TooltipDirection.right,
    this.distance = 10.0,
    this.textStyle,
    this.decoration,
  });

  @override
  MyTooltipState createState() => MyTooltipState();
}

class MyTooltipState extends State<MyTooltip> {
  static OverlayEntry? _currentTooltipEntry;

  @override
  void dispose() {
    _hideTooltip(); // Ensure tooltip is removed when the widget is disposed
    super.dispose();
  }

  void _showTooltip() {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final buttonSize = renderBox.size;
    final buttonPosition = renderBox.localToGlobal(Offset.zero);

    // Remove any existing tooltip to avoid duplicates
    _hideTooltip();

    final OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: _getLeft(buttonPosition, buttonSize),
          top: _getTop(buttonPosition, buttonSize),
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: widget.decoration ??
                  BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
              child: Text(
                widget.tooltipText,
                style: widget.textStyle ??
                    TextStyle(
                      color: Theme.of(context).colorScheme.onSecondary,
                      fontSize: 12,
                    ),
              ),
            ),
          ),
        );
      },
    );

    _currentTooltipEntry = overlayEntry;
    overlay.insert(overlayEntry);
  }

  void _hideTooltip() {
    _currentTooltipEntry?.remove();
    _currentTooltipEntry = null;
  }

  double _getLeft(Offset buttonPosition, Size buttonSize) {
    switch (widget.direction) {
      case TooltipDirection.left:
        return buttonPosition.dx - widget.distance;
      case TooltipDirection.right:
        return buttonPosition.dx + buttonSize.width + widget.distance;
      default:
        return buttonPosition.dx + (buttonSize.width / 2);
    }
  }

  double _getTop(Offset buttonPosition, Size buttonSize) {
    switch (widget.direction) {
      case TooltipDirection.top:
        return buttonPosition.dy - widget.distance;
      case TooltipDirection.bottom:
        return buttonPosition.dy + buttonSize.height + widget.distance;
      case TooltipDirection.left:
      case TooltipDirection.right:
        return buttonPosition.dy + (buttonSize.height / 2) - 12; }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _hideTooltip(); // Ensure tooltip is removed on tap
      },
      child: MouseRegion(
        onEnter: (event) => _showTooltip(),
        onExit: (event) => _hideTooltip(),
        child: widget.child,
      ),
    );
  }
}
