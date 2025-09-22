import 'package:flutter/material.dart';
import 'package:hadith_iq/components/my_tooltip.dart';

class AnimatedHoverIconButton extends StatefulWidget {
  final IconData defaultIcon;
  final IconData hoverIcon;
  final VoidCallback? onPressed;
  final double size;
  final Color defaultColor;
  final Color hoverColor;
  final String tooltipText;
  final bool isSelected;
  final bool isDisabled; // New: Disable the button
  final TooltipDirection tooltipDirection;
  final BoxConstraints? constraints;

  const AnimatedHoverIconButton({
    super.key,
    required this.defaultIcon,
    required this.onPressed,
    required this.size,
    this.defaultColor = Colors.black,
    this.hoverColor = Colors.blue,
    this.hoverIcon = Icons.close_rounded,
    this.tooltipText = "",
    this.isSelected = false,
    this.isDisabled = false, // Default is false
    this.tooltipDirection = TooltipDirection.right,
    this.constraints,
  });

  @override
  AnimatedHoverIconButtonState createState() =>
      AnimatedHoverIconButtonState();
}

class AnimatedHoverIconButtonState extends State<AnimatedHoverIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (!widget.isDisabled) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (!widget.isDisabled) setState(() => _isHovered = false);
      },
      child: widget.tooltipText.isEmpty
          ? _buildAnimatedIcon()
          : MyTooltip(
              tooltipText: widget.tooltipText,
              direction: widget.tooltipDirection,
              distance: 17,
              child: _buildAnimatedIcon(),
            ),
    );
  }

  Widget _buildAnimatedIcon() {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(
        begin: widget.defaultColor,
        end: (widget.isDisabled
                ? Colors.grey // Set to grey if disabled
                : (_isHovered || widget.isSelected)
                    ? widget.hoverColor
                    : widget.defaultColor),
      ),
      duration: const Duration(milliseconds: 200),
      builder: (context, color, child) {
        return IconButton(
          iconSize: widget.size,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: Icon(
              (widget.isDisabled || !_isHovered && !widget.isSelected)
                  ? widget.defaultIcon
                  : widget.hoverIcon,
              key: ValueKey<bool>(_isHovered || widget.isSelected),
              color: color,
            ),
          ),
          onPressed: widget.isDisabled ? null : widget.onPressed, // Disable click
          padding: EdgeInsets.zero,
          constraints: widget.constraints,
        );
      },
    );
  }
}
