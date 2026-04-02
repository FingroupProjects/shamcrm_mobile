import 'package:flutter/material.dart';

class StyledActionButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const StyledActionButton({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  State<StyledActionButton> createState() => _StyledActionButtonState();
}

class _StyledActionButtonState extends State<StyledActionButton> {
  bool _tapLocked = false;

  void _handleTap() {
    if (_tapLocked) return;

    setState(() => _tapLocked = true);
    widget.onPressed();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_tapLocked) return;
      setState(() => _tapLocked = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _tapLocked ? null : _handleTap,
        child: IntrinsicWidth(
          child: Container(
            constraints: const BoxConstraints(
              minWidth: 100,
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: widget.color, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: 18,
                  color: widget.color,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.text,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    color: widget.color,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
