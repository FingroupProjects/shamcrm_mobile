import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../api/service/http_log_model.dart';
import 'theme_controller.dart';

/// Детальный экран с поддержкой тем
class HttpRequestDetailScreen extends StatefulWidget {
  final HttpLogModel log;

  const HttpRequestDetailScreen({Key? key, required this.log})
      : super(key: key);

  @override
  State<HttpRequestDetailScreen> createState() =>
      _HttpRequestDetailScreenState();
}

class _HttpRequestDetailScreenState extends State<HttpRequestDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ThemeController _themeController = ThemeController();
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() => _currentTab = _tabController.index);
    });
    _themeController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    final log = widget.log;
    if (log.error != null) return const Color(0xFFFF6B6B);
    if (log.statusCode == null) return const Color(0xFF64748B);
    if (log.statusCode! >= 200 && log.statusCode! < 300) {
      return const Color(0xFF10B981);
    }
    if (log.statusCode! >= 300 && log.statusCode! < 400) {
      return const Color(0xFFF59E0B);
    }
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _themeController.isDarkMode;
    final bgColor =
        isDark ? DarkThemeColors.background : LightThemeColors.background;
    final surfaceColor =
        isDark ? DarkThemeColors.surface : LightThemeColors.surface;
    final textColor =
        isDark ? DarkThemeColors.onSurface : LightThemeColors.onSurface;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(isDark, surfaceColor, textColor),
          _buildTabBar(isDark),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(isDark, surfaceColor, textColor),
                _buildRequestTab(isDark, surfaceColor, textColor),
                _buildPayloadTab(isDark, surfaceColor, textColor),
                _buildResponseTab(isDark, surfaceColor, textColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isDark, Color surfaceColor, Color textColor) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor:
          (isDark ? DarkThemeColors.background : LightThemeColors.background)
              .withOpacity(0.95),
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? DarkThemeColors.surface.withOpacity(0.5)
              : LightThemeColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : LightThemeColors.border,
            width: 1.5,
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: textColor,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      _getMethodColor(widget.log.method).withOpacity(0.3),
                      DarkThemeColors.background,
                    ]
                  : [
                      _getMethodColor(widget.log.method).withOpacity(0.15),
                      LightThemeColors.background,
                    ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getMethodColor(widget.log.method),
                          _getMethodColor(widget.log.method).withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _getMethodColor(widget.log.method)
                              .withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      widget.log.method,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.log.shortUrl,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverTabBarDelegate(
        TabBar(
          controller: _tabController,
          labelColor: isDark ? Colors.white : LightThemeColors.onSurface,
          unselectedLabelColor: isDark
              ? Colors.white.withOpacity(0.5)
              : LightThemeColors.onSurfaceVariant,
          indicatorColor: _getStatusColor(),
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Request'),
            Tab(text: 'Payload'),
            Tab(text: 'Response'),
          ],
        ),
        isDark,
      ),
    );
  }

  Widget _buildOverviewTab(bool isDark, Color surfaceColor, Color textColor) {
    final log = widget.log;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModernInfoCard(
            isDark: isDark,
            icon: Icons.public_rounded,
            label: 'Endpoint',
            value: log.url,
            copyable: true,
            color: const Color(0xFF6366F1),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildModernInfoCard(
                  isDark: isDark,
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Status',
                  value: log.statusCode?.toString() ?? 'Pending',
                  color: _getStatusColor(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildModernInfoCard(
                  isDark: isDark,
                  icon: Icons.speed_rounded,
                  label: 'Duration',
                  value: log.duration != null
                      ? '${log.duration!.inMilliseconds}ms'
                      : 'N/A',
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildModernInfoCard(
            isDark: isDark,
            icon: Icons.access_time_rounded,
            label: 'Timestamp',
            value: _formatFullTime(log.timestamp),
            color: const Color(0xFF8B5CF6),
          ),
          if (log.error != null) ...[
            const SizedBox(height: 16),
            _buildModernInfoCard(
              isDark: isDark,
              icon: Icons.error_outline_rounded,
              label: 'Error',
              value: log.error!,
              color: const Color(0xFFFF6B6B),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequestTab(bool isDark, Color surfaceColor, Color textColor) {
    final log = widget.log;
    final queryParams = _extractQueryParams(log.url);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(isDark, 'Endpoint', Icons.public_rounded),
          const SizedBox(height: 12),
          _buildModernInfoCard(
            isDark: isDark,
            icon: Icons.link_rounded,
            label: 'URL',
            value: log.url,
            copyable: true,
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(
              isDark, 'Query Params', Icons.tune_rounded),
          const SizedBox(height: 12),
          _buildModernHeadersCard(isDark, queryParams),
          const SizedBox(height: 24),
          _buildSectionHeader(isDark, 'Headers', Icons.label_outline_rounded),
          const SizedBox(height: 12),
          _buildModernHeadersCard(isDark, log.requestHeaders),
        ],
      ),
    );
  }

  Widget _buildPayloadTab(bool isDark, Color surfaceColor, Color textColor) {
    final log = widget.log;
    final payloadToShow = _resolvePayload(log);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
              isDark, 'Request Payload', Icons.description_outlined),
          const SizedBox(height: 12),
          _buildModernBodyCard(isDark, payloadToShow, 'request'),
        ],
      ),
    );
  }

  Widget _buildResponseTab(bool isDark, Color surfaceColor, Color textColor) {
    final log = widget.log;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(isDark, 'Headers', Icons.label_outline_rounded),
          const SizedBox(height: 12),
          _buildModernHeadersCard(isDark, log.responseHeaders),
          const SizedBox(height: 24),
          _buildSectionHeader(isDark, 'Body', Icons.description_outlined),
          const SizedBox(height: 12),
          _buildModernBodyCard(isDark, log.responseBody, 'response'),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(bool isDark, String title, IconData icon) {
    final textColor =
        isDark ? DarkThemeColors.onSurface : LightThemeColors.onSurface;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6366F1).withOpacity(isDark ? 0.2 : 0.15),
                const Color(0xFF6366F1).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF6366F1),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildModernInfoCard({
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool copyable = false,
  }) {
    final textColor =
        isDark ? DarkThemeColors.onSurface : LightThemeColors.onSurface;
    final textSecondary = isDark
        ? DarkThemeColors.onSurfaceVariant
        : LightThemeColors.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? DarkThemeColors.surface.withOpacity(0.6)
            : LightThemeColors.surface,
        border: Border.all(
          color: color.withOpacity(isDark ? 0.3 : 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isDark ? 0.1 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(isDark ? 0.2 : 0.15),
                      color.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (copyable)
                IconButton(
                  icon: Icon(
                    Icons.copy_rounded,
                    size: 18,
                    color: textSecondary,
                  ),
                  onPressed: () => _copyToClipboard(value),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(
            value,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeadersCard(bool isDark, Map<String, String>? headers) {
    if (headers == null || headers.isEmpty) {
      return _buildEmptyCard(isDark, 'No headers available');
    }

    final textSecondary = isDark
        ? DarkThemeColors.onSurfaceVariant
        : LightThemeColors.onSurfaceVariant;
    final textColor =
        isDark ? DarkThemeColors.onSurface : LightThemeColors.onSurface;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? DarkThemeColors.surface.withOpacity(0.6)
            : LightThemeColors.surface,
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.1) : LightThemeColors.border,
          width: 1,
        ),
        boxShadow: !isDark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFF6366F1).withOpacity(isDark ? 0.2 : 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${headers.length} headers',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6366F1),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.copy_all_rounded,
                  size: 18,
                  color: textSecondary,
                ),
                onPressed: () => _copyToClipboard(
                  headers.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...headers.entries.map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : LightThemeColors.border.withOpacity(0.5),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6366F1),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: SelectableText(
                      entry.value,
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor.withOpacity(0.8),
                        fontFamily: 'monospace',
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildModernBodyCard(bool isDark, String? body, String type) {
    if (body == null || body.isEmpty) {
      return _buildEmptyCard(isDark, 'No body content');
    }

    String formattedBody = body;
    bool isJson = false;
    try {
      final decoded = json.decode(body);
      formattedBody = const JsonEncoder.withIndent('  ').convert(decoded);
      isJson = true;
    } catch (e) {
      // Not JSON
    }

    final textSecondary = isDark
        ? DarkThemeColors.onSurfaceVariant
        : LightThemeColors.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? DarkThemeColors.surface.withOpacity(0.6)
            : LightThemeColors.surface,
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.1) : LightThemeColors.border,
          width: 1,
        ),
        boxShadow: !isDark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF10B981).withOpacity(isDark ? 0.2 : 0.15),
                      const Color(0xFF10B981).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isJson ? Icons.code_rounded : Icons.text_fields_rounded,
                      size: 14,
                      color: const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isJson ? 'JSON' : 'Text',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.copy_all_rounded,
                  size: 18,
                  color: textSecondary,
                ),
                onPressed: () => _copyToClipboard(formattedBody),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(isDark ? 0.2 : 0.15),
                width: 1,
              ),
            ),
            child: SelectableText(
              formattedBody,
              style: TextStyle(
                fontSize: 13,
                color:
                    isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
                fontFamily: 'monospace',
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(bool isDark, String message) {
    final textSecondary = isDark
        ? DarkThemeColors.onSurfaceVariant
        : LightThemeColors.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? DarkThemeColors.surface.withOpacity(0.3)
            : LightThemeColors.surfaceVariant,
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.05) : LightThemeColors.border,
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: textSecondary.withOpacity(0.6),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return const Color(0xFF3B82F6);
      case 'POST':
        return const Color(0xFF10B981);
      case 'PUT':
        return const Color(0xFFF59E0B);
      case 'PATCH':
        return const Color(0xFF8B5CF6);
      case 'DELETE':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  Map<String, String>? _extractQueryParams(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.queryParametersAll.isEmpty) return null;
      return uri.queryParametersAll.map(
        (key, values) => MapEntry(key, values.join(', ')),
      );
    } catch (_) {
      return null;
    }
  }

  String? _resolvePayload(HttpLogModel log) {
    if (log.requestBody != null && log.requestBody!.isNotEmpty) {
      return log.requestBody;
    }
    final queryParams = _extractQueryParams(log.url);
    if (queryParams == null || queryParams.isEmpty) {
      return null;
    }
    return json.encode(queryParams);
  }

  String _formatFullTime(DateTime time) {
    return '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text(
              'Copied to clipboard',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final bool isDark;

  _SliverTabBarDelegate(this.tabBar, this.isDark);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? DarkThemeColors.background.withOpacity(0.95)
            : LightThemeColors.background.withOpacity(0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : LightThemeColors.border,
            width: 1,
          ),
        ),
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return isDark != oldDelegate.isDark;
  }
}
