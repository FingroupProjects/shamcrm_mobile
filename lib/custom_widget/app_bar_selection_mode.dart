import 'package:flutter/material.dart';

class AppBarSelectionMode extends StatelessWidget {
  const AppBarSelectionMode({
    super.key,
    required this.title,
    required this.onDismiss,
    this.onApprove,
    this.onDisapprove,
    this.onDelete,
    this.onRestore,
    this.showDelete = false,
    this.showDisapprove = false,
    this.showApprove = false,
    this.showRestore = false,
  });

  final String title;
  final VoidCallback onDismiss;
  final VoidCallback? onApprove;
  final VoidCallback? onDisapprove;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;

  final bool showDelete;
  final bool showDisapprove;
  final bool showApprove;
  final bool showRestore;

  Widget _buildAction({
    required IconData icon,
    Color? color,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Icon(icon, size: 24, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: kToolbarHeight,
      color: Colors.white,
      child: Row(
        children: [
          _buildAction(
            icon: Icons.close,
            color: const Color(0xff1E2E52),
            onTap: onDismiss,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52),
              ),
            ),
          ),
          if (showDelete)
            ...[_buildAction(
              icon: Icons.delete_sharp,
              // color: Colors.red,
              onTap: onDelete,
            ),
          const SizedBox(width: 8),],

          if (showRestore)
           ...[ _buildAction(
              icon: Icons.restore_from_trash_sharp,
              // color: const Color(0xFF4CAF50),
              onTap: onRestore,
            ),
          const SizedBox(width: 8)],

          if (showDisapprove)
            ...[_buildAction(
              icon: Icons.cancel_outlined,
              // color: const Color(0xFFFFA500),
              onTap: onDisapprove,
            ),
          const SizedBox(width: 8)],

          if (showApprove)
            _buildAction(
              icon: Icons.check_circle_outline,
              // color: const Color(0xFF4CAF50),
              onTap: onApprove,
            ),
        ],
      ),
    );
  }
}
