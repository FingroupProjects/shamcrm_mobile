import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../api/service/http_log_model.dart';
import '../../api/service/http_logger.dart';
import 'http_request_detail_screen.dart';
import 'theme_controller.dart';
import 'animated_theme_toggle.dart';

/// Современный HTTP Inspector с поддержкой тем
class HttpInspectorScreen extends StatefulWidget {
  const HttpInspectorScreen({Key? key}) : super(key: key);

  @override
  State<HttpInspectorScreen> createState() => _HttpInspectorScreenState();
}

class _HttpInspectorScreenState extends State<HttpInspectorScreen> {
  final HttpLogger _logger = HttpLogger();
  final TextEditingController _searchController = TextEditingController();
  final ThemeController _themeController = ThemeController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _themeController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(HttpLogModel log) {
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

  void _handleThemeToggle() {
    HapticFeedback.mediumImpact();
    _themeController.toggleTheme();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _themeController.isDarkMode;
    final bgColor = isDark ? DarkThemeColors.background : LightThemeColors.background;
    final surfaceColor = isDark ? DarkThemeColors.surface : LightThemeColors.surface;
    final textColor = isDark ? DarkThemeColors.onSurface : LightThemeColors.onSurface;
    final textSecondary = isDark ? DarkThemeColors.onSurfaceVariant : LightThemeColors.onSurfaceVariant;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(isDark, surfaceColor, textColor, textSecondary),
          _buildSearchField(isDark, surfaceColor, textColor, textSecondary),
          _buildRequestsList(isDark, surfaceColor, textColor, textSecondary),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isDark, Color surfaceColor, Color textColor, Color textSecondary) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: (isDark ? DarkThemeColors.background : LightThemeColors.background).withOpacity(0.95),
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
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(
            Icons.close_rounded,
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
                      const Color(0xFF6366F1).withOpacity(0.2),
                      DarkThemeColors.background,
                    ]
                  : [
                      const Color(0xFF6366F1).withOpacity(0.1),
                      LightThemeColors.background,
                    ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 20,
                right: 40,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF6366F1).withOpacity(isDark ? 0.3 : 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.radar,
                  color: DarkThemeColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'HTTP Inspector',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        // Переключатель темы
        GestureDetector(
          onTap: _handleThemeToggle,
          child: Container(
            margin: const EdgeInsets.all(8),
            child: AnimatedThemeToggle(
              isDarkMode: isDark,
              onToggle: _handleThemeToggle,
            ),
          ),
        ),
        const SizedBox(width: 4),
        // Кнопка удаления
        Container(
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
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(
              Icons.delete_sweep_outlined,
              color: Color(0xFFFF6B6B),
              size: 20,
            ),
            onPressed: () => _showClearDialog(isDark, surfaceColor, textColor),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchField(bool isDark, Color surfaceColor, Color textColor, Color textSecondary) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDark
                ? DarkThemeColors.surface.withOpacity(0.6)
                : LightThemeColors.surface,
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : LightThemeColors.border,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(isDark ? 0.1 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Search requests...',
              hintStyle: TextStyle(
                color: textSecondary.withOpacity(0.6),
                fontSize: 15,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: const Color(0xFF6366F1).withOpacity(0.8),
                size: 22,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRequestsList(bool isDark, Color surfaceColor, Color textColor, Color textSecondary) {
    return StreamBuilder<List<HttpLogModel>>(
      stream: _logger.logsStream,
      initialData: _logger.logs,
      builder: (context, snapshot) {
        final logs = _searchQuery.isEmpty
            ? (snapshot.data ?? [])
            : _logger.filterLogs(_searchQuery);

        if (logs.isEmpty) {
          return SliverFillRemaining(
            child: _buildEmptyState(isDark, textColor, textSecondary),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return TweenAnimationBuilder(
                  duration: Duration(milliseconds: 300 + (index * 50)),
                  tween: Tween<double>(begin: 0, end: 1),
                  curve: Curves.easeOutCubic,
                  builder: (context, double value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: _buildModernLogCard(logs[index], isDark, surfaceColor, textColor, textSecondary),
                );
              },
              childCount: logs.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernLogCard(HttpLogModel log, bool isDark, Color surfaceColor, Color textColor, Color textSecondary) {
    final statusColor = _getStatusColor(log);
    final methodColor = _getMethodColor(log.method);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark
            ? DarkThemeColors.surface.withOpacity(0.6)
            : LightThemeColors.surface,
        border: Border.all(
          color: statusColor.withOpacity(isDark ? 0.3 : 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(isDark ? 0.1 : 0.08),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    HttpRequestDetailScreen(log: log),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.1),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: child,
                    ),
                  );
                },
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            methodColor,
                            methodColor.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: methodColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        log.method,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (log.statusCode != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(isDark ? 0.2 : 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: statusColor.withOpacity(isDark ? 0.5 : 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: statusColor.withOpacity(0.5),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${log.statusCode}',
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    if (log.duration != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.speed_rounded,
                              size: 12,
                              color: textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${log.duration!.inMilliseconds}ms',
                              style: TextStyle(
                                fontSize: 11,
                                color: textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  log.shortUrl,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : LightThemeColors.border.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.link_rounded,
                        size: 14,
                        color: textSecondary.withOpacity(0.6),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          log.url,
                          style: TextStyle(
                            fontSize: 11,
                            color: textSecondary.withOpacity(0.7),
                            fontFamily: 'monospace',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: textSecondary.withOpacity(0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatTime(log.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (log.error != null) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B6B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFFF6B6B).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                size: 14,
                                color: Color(0xFFFF6B6B),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  log.error!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFFF6B6B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color textColor, Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF6366F1).withOpacity(isDark ? 0.2 : 0.15),
                  Colors.transparent,
                ],
              ),
            ),
            child: Center(
              child: Icon(
                Icons.radar,
                size: 60,
                color: const Color(0xFF6366F1).withOpacity(isDark ? 0.5 : 0.4),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isEmpty ? 'No Requests Yet' : 'No Results Found',
            style: TextStyle(
              fontSize: 22,
              color: textColor,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isEmpty
                ? 'Make a request to see it here'
                : 'Try a different search query',
            style: TextStyle(
              fontSize: 15,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showClearDialog(bool isDark, Color surfaceColor, Color textColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? DarkThemeColors.surface : LightThemeColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : LightThemeColors.border,
          ),
        ),
        title: Text(
          'Clear All Logs?',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This will delete all HTTP request logs',
          style: TextStyle(
            color: isDark
                ? DarkThemeColors.onSurfaceVariant
                : LightThemeColors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark
                    ? DarkThemeColors.onSurfaceVariant
                    : LightThemeColors.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _logger.clearLogs();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('All logs cleared'),
                  backgroundColor: const Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}