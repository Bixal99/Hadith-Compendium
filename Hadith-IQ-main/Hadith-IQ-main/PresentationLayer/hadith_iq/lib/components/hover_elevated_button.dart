import 'package:flutter/material.dart';

class AnimatedHoverElevatedButton extends StatefulWidget {
  final IconData defaultIcon;
  final IconData hoverIcon;
  final VoidCallback onPressed;
  final double iconSize;
  final Color defaultColor;
  final Color hoverColor;
  final bool isSelected;
  final String text;
  final int textSize;
  final bool isTextBelow;

  const AnimatedHoverElevatedButton({
    super.key,
    required this.defaultIcon,
    required this.onPressed,
    required this.iconSize,
    this.defaultColor = Colors.black,
    this.hoverColor = Colors.blue,
    this.hoverIcon = Icons.close_rounded,
    this.isSelected = false,
    required this.text,
    this.isTextBelow = false,
    this.textSize = 12,
  });

  @override
  AnimatedHoverElevatedButtonState createState() =>
      AnimatedHoverElevatedButtonState();
}

class AnimatedHoverElevatedButtonState
    extends State<AnimatedHoverElevatedButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: ElevatedButton(
        onPressed: widget.onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: TweenAnimationBuilder<Color?>(
          tween: ColorTween(
            begin: widget.defaultColor,
            end: (_isHovered || widget.isSelected)
                ? widget.hoverColor
                : widget.defaultColor,
          ),
          duration: const Duration(milliseconds: 200),
          builder: (context, color, child) {
            return widget.isTextBelow
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildAnimatedIcon(color!),
                      if (widget.text.isNotEmpty)
                        Text(
                          widget.text,
                          style: TextStyle(fontSize: widget.textSize.toDouble()),
                        ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildAnimatedIcon(color!),
                      const SizedBox(width: 10),
                      if (widget.text.isNotEmpty)
                        Text(
                          widget.text,
                          style: TextStyle(fontSize: widget.textSize.toDouble()),
                        ),
                    ],
                  );
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon(Color color) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: Icon(
        (_isHovered || widget.isSelected) ? widget.hoverIcon : widget.defaultIcon,
        key: ValueKey<bool>(_isHovered || widget.isSelected),
        size: widget.iconSize,
        color: color,
      ),
    );
  }
}
