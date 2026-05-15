part of 'package:crm_task_manager/screens/sip/sip_screen.dart';

String _normalizeHistoryPhone(String input) {
  return input.replaceAll(RegExp(r'[^0-9]'), '');
}

bool _historyPhonesMatch(String left, String right) {
  final normalizedLeft = _normalizeHistoryPhone(left);
  final normalizedRight = _normalizeHistoryPhone(right);
  if (normalizedLeft.isEmpty || normalizedRight.isEmpty) {
    return false;
  }

  return normalizedLeft == normalizedRight ||
      normalizedLeft.endsWith(normalizedRight) ||
      normalizedRight.endsWith(normalizedLeft);
}

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
  bool _isLoading = true;
  String? _error;
  List<CallLogEntry> _calls = const [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final targetPhone = widget.entry.dialTarget.trim();
    if (targetPhone.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'Не удалось определить номер для истории';
      });
      return;
    }

    try {
      final matched = <CallLogEntry>[];
      var page = 1;
      var totalPages = 1;

      do {
        final response =
            await widget.apiService.getAllCalls(page: page, perPage: 100);
        final calls = response['calls'] as List<CallLogEntry>;
        final pagination = response['pagination'] as Map<String, dynamic>;
        totalPages = pagination['total_pages'] as int? ?? page;

        matched.addAll(
          calls.where(
            (call) => _historyPhonesMatch(call.phoneNumber, targetPhone),
          ),
        );

        page++;
      } while (page <= totalPages);

      matched.sort((a, b) => b.callDate.compareTo(a.callDate));

      if (!mounted) return;
      setState(() {
        _calls = matched;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Не удалось загрузить историю: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = widget.entry.dialTarget == widget.entry.target
        ? widget.entry.dialTarget
        : '${widget.entry.target} • ${widget.entry.dialTarget}';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'История звонков',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
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
              : _calls.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'История звонков для этого номера пока не найдена',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: _calls.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final call = _calls[index];
                        final isMissed = call.callType == CallType.missed;
                        final isOutgoing = call.callType == CallType.outgoing;
                        final accentColor = isMissed
                            ? const Color(0xFFEF4444)
                            : isOutgoing
                                ? const Color(0xFF22C55E)
                                : const Color(0xFF2563EB);
                        final fillColor = isMissed
                            ? const Color(0xFFFEF2F2)
                            : isOutgoing
                                ? const Color(0xFFF0FDF4)
                                : const Color(0xFFEFF6FF);
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

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF111827)
                                    .withValues(alpha: 0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CallDetailsScreen(callEntry: call),
                                ),
                              );
                            },
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: fillColor,
                                borderRadius: BorderRadius.circular(15),
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
                              style: const TextStyle(
                                color: Color(0xFF111827),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              isMissed
                                  ? '$label • ${call.phoneNumber}'
                                  : '$label • ${_formatHistoryDuration(call.duration)} • ${call.phoneNumber}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatHistoryTime(call.callDate),
                                  style: const TextStyle(
                                    color: Color(0xFFD1D5DB),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Icon(
                                  CupertinoIcons.info_circle,
                                  size: 18,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  String _formatHistoryTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatHistoryDuration(Duration? duration) {
    if (duration == null) return '--:--';
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
