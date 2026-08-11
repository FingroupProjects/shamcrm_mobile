part of 'package:crm_task_manager/screens/sip/sip_screen.dart';

class _SipCallHistoryScreen extends StatefulWidget {
  final SipCallLogEntry entry;
  final ApiService apiService;

  const _SipCallHistoryScreen({
    required this.entry,
    required this.apiService,
  });

  @override
  State<_SipCallHistoryScreen> createState() => _SipCallHistoryScreenState();
}

class _SipCallHistoryScreenState extends State<_SipCallHistoryScreen> {
  static const int _perPage = 20;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  List<CallLogEntry> _calls = const [];
  int _currentPage = 0;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadHistory(reset: true);
  }

  Future<void> _loadHistory({required bool reset}) async {
    final leadId = widget.entry.serverLeadId;
    if (leadId == null) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _error = 'Не удалось определить id лида для истории';
      });
      return;
    }

    if (reset) {
      setState(() {
        _isLoading = true;
        _error = null;
        _currentPage = 0;
        _totalPages = 1;
      });
    } else {
      if (_isLoadingMore || _currentPage >= _totalPages) return;
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final nextPage = reset ? 1 : _currentPage + 1;
      final response = await widget.apiService.getAllCalls(
        page: nextPage,
        perPage: _perPage,
        filters: {
          'leads': [leadId],
        },
      ).timeout(const Duration(seconds: 12));

      final calls = response['calls'] as List<CallLogEntry>;
      final pagination = response['pagination'] as Map<String, dynamic>;
      final totalPages = pagination['total_pages'] as int? ?? nextPage;
      final merged = reset
          ? calls
          : <CallLogEntry>[
              ..._calls,
              ...calls,
            ];

      if (!mounted) return;
      setState(() {
        _calls = merged;
        _currentPage = nextPage;
        _totalPages = totalPages;
        _isLoading = false;
        _isLoadingMore = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _error = 'Не удалось загрузить историю: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitle = widget.entry.dialTarget == widget.entry.target
        ? widget.entry.dialTarget
        : '${widget.entry.target} • ${widget.entry.dialTarget}';

    return Scaffold(
      backgroundColor: context.appColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor:
            context.appColors.surfacePrimary.withValues(alpha: 0.82),
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'История звонков',
              style: TextStyle(
                color: context.appColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.appColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: _TelephonyBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator.adaptive())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => _loadHistory(reset: true),
                    color: _TelephonyVisualColors.blue,
                    backgroundColor: colors.surfaceElevated,
                    child: _calls.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(24),
                            children: [
                              const SizedBox(height: 180),
                              Text(
                                'История звонков для этого лида пока не найдена',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              if (notification.metrics.pixels >=
                                      notification.metrics.maxScrollExtent -
                                          160 &&
                                  !_isLoadingMore &&
                                  _currentPage < _totalPages) {
                                unawaited(_loadHistory(reset: false));
                              }
                              return false;
                            },
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding:
                                  const EdgeInsets.fromLTRB(16, 16, 16, 24),
                              itemCount:
                                  _calls.length + (_isLoadingMore ? 1 : 0),
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                if (index >= _calls.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child:
                                          CircularProgressIndicator.adaptive(),
                                    ),
                                  );
                                }

                                final call = _calls[index];
                                final isMissed =
                                    call.callType == CallType.missed;
                                final isOutgoing =
                                    call.callType == CallType.outgoing;
                                final accentColor = isMissed
                                    ? const Color(0xFFEF4444)
                                    : isOutgoing
                                        ? const Color(0xFF22C55E)
                                        : const Color(0xFF2563EB);
                                final fillColor = accentColor.withValues(
                                  alpha: isDark ? 0.18 : 0.10,
                                );
                                final icon = isMissed
                                    ? CupertinoIcons.phone_down_fill
                                    : isOutgoing
                                        ? CupertinoIcons.arrow_up_right
                                        : CupertinoIcons.arrow_down_left;
                                final label = isMissed
                                    ? 'Пропущенный'
                                    : isOutgoing
                                        ? 'Исходящий'
                                        : 'Входящий';

                                return DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colors.shadow.withValues(
                                          alpha: isDark ? 0.18 : 0.06,
                                        ),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: colors.surfacePrimary.withValues(
                                      alpha: isDark ? 0.68 : 0.88,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(22),
                                      side: BorderSide(
                                        color: colors.borderSubtle,
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 4,
                                      ),
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => CallDetailsScreen(
                                              callEntry: call,
                                            ),
                                          ),
                                        );
                                      },
                                      leading: Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: fillColor,
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        child: Icon(
                                          icon,
                                          color: accentColor,
                                          size: 18,
                                        ),
                                      ),
                                      title: Text(
                                        call.leadName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: colors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      subtitle: Text(
                                        isMissed
                                            ? '$label • ${call.phoneNumber}'
                                            : '$label • ${_formatHistoryDuration(call.duration)} • ${call.phoneNumber}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: colors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                      trailing: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            _formatHistoryTime(call.callDate),
                                            style: TextStyle(
                                              color: colors.textMuted,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (call.operatorName != null &&
                                              call.operatorName!
                                                  .trim()
                                                  .isNotEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 4),
                                              child: Text(
                                                call.operatorName!,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: colors.textSecondary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
      ),
    );
  }

  String _formatHistoryTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatHistoryDuration(Duration? duration) {
    if (duration == null) return '00:00';
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;
    if (hours > 0) {
      return '$hours:${minutes.padLeft(2, '0')}:$seconds';
    }
    return '$minutes:$seconds';
  }
}
