import 'package:flutter/material.dart';

enum DownloadFormat {
  svg('svg', 'Download SVG', Icons.download),
  png('png', 'Download PNG', Icons.image),
  csv('csv', 'Download CSV', Icons.table_chart);

  const DownloadFormat(this.value, this.label, this.icon);

  final String value;
  final String label;
  final IconData icon;
}

class DownloadPopupMenu extends StatelessWidget {
  const DownloadPopupMenu({
    super.key,
    required this.onDownload,
    this.formats = const [DownloadFormat.svg, DownloadFormat.png, DownloadFormat.csv],
    this.icon,
    this.tooltip = 'Download options',
    this.enabled = true,
    this.loading = false,
    this.offset = const Offset(0, 40),
    this.elevation = 8,
    this.borderRadius = 12,
    this.iconSize = 24,
    this.textStyle,
  });

  final Function(DownloadFormat) onDownload;
  final List<DownloadFormat> formats;
  final Widget? icon;
  final String tooltip;
  final bool enabled;
  final bool loading;
  final Offset offset;
  final double elevation;
  final double borderRadius;
  final double iconSize;
  final TextStyle? textStyle;

  TextStyle get _defaultTextStyle => const TextStyle(
        fontFamily: 'Gilroy',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      );

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return SizedBox(
        width: iconSize,
        height: iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.grey[400],
        ),
      );
    }

    return PopupMenuButton<DownloadFormat>(
      enabled: enabled,
      tooltip: tooltip,
      padding: EdgeInsets.zero, // Remove default padding
      icon: icon ??
          Icon(
            Icons.more_vert,
            color: enabled ? Colors.grey[400] : Colors.grey[300],
            size: iconSize,
          ),
      color: Colors.white,
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      offset: offset,
      itemBuilder: (BuildContext context) => formats
          .map(
            (format) => PopupMenuItem<DownloadFormat>(
          value: format,
          child: Row(
            children: [
              Icon(
                format.icon,
                size: 18,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 12),
              Text(
                format.label,
                style: textStyle ?? _defaultTextStyle,
              ),
            ],
          ),
        ),
      )
          .toList(),
      onSelected: onDownload,
    );
  }
}

class DownloadHandler {
  static Future<void> handleDownload(
    DownloadFormat format, {
    required String filename,
    dynamic data,
    BuildContext? context,
  }) async {
    switch (format) {
      case DownloadFormat.svg:
        await _downloadSvg(filename, data);
        break;
      case DownloadFormat.png:
        await _downloadPng(filename, data);
        break;
      case DownloadFormat.csv:
        await _downloadCsv(filename, data);
        break;
    }

    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${format.label} downloaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  static Future<void> _downloadSvg(String filename, dynamic data) async {
    // Implement SVG download logic
    await Future.delayed(const Duration(seconds: 1)); // Simulate download
    print('Downloading SVG: $filename');
  }

  static Future<void> _downloadPng(String filename, dynamic data) async {
    // Implement PNG download logic
    await Future.delayed(const Duration(seconds: 1)); // Simulate download
    print('Downloading PNG: $filename');
  }

  static Future<void> _downloadCsv(String filename, dynamic data) async {
    // Implement CSV download logic
    await Future.delayed(const Duration(seconds: 1)); // Simulate download
    print('Downloading CSV: $filename');
  }
}
