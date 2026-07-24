part of 'package:crm_task_manager/screens/sip/sip_screen.dart';

extension _SipJournalSearchViewsExtension on _SipScreenState {
  Widget _journalView(BuildContext context, SipUiState state) {
    final l10n = AppLocalizations.of(context)!;
    final entries =
        state.serverCallLogs.isNotEmpty ? state.serverCallLogs : state.callLogs;
    final items = _buildJournalItemsWithHeaders(entries);
    final railEntries = _buildJournalRailEntries(items);
    final filters = <(CallType?, String)>[
      (null, 'Все'),
      (CallType.incoming, 'Входящие'),
      (CallType.outgoing, 'Исходящие'),
      (CallType.missed, 'Пропущенные'),
    ];

    return Column(
      key: const ValueKey('journal'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: Column(
            children: [
              _cleanSearchField(
                placeholder: 'Поиск звонков',
                controller: _journalSearchController,
                onChanged: _handleJournalSearchChanged,
                onClear: _clearJournalSearch,
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final filter in filters) ...[
                      _journalFilterChip(
                        label: filter.$2,
                        selected: state.serverCallFilter == filter.$1,
                        onTap: () async {
                          _updateView(() {
                            _expandedCallLogId = null;
                          });
                          await _sipRuntime.refreshRecentCallLogs(
                            callType: filter.$1,
                            searchQuery: _journalSearchQuery.trim(),
                            force: true,
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: state.isServerCallLogsLoading && items.isEmpty
              ? const Padding(
                  key: ValueKey('journal_loading'),
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator.adaptive()),
                )
              : items.isEmpty
                  ? Padding(
                      key: const ValueKey('journal_empty'),
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          l10n.translate('sip_journal_empty'),
                          style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  : RefreshIndicator.adaptive(
                      onRefresh: () => _refreshJournalCalls(force: true),
                      child: Stack(
                        children: [
                          NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              if (notification.metrics.pixels >=
                                  notification.metrics.maxScrollExtent - 120) {
                                _sipRuntime.loadMoreRecentCallLogs();
                              }
                              return false;
                            },
                            child: ListView.builder(
                              controller: _journalListController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 6, 40, 10),
                              itemCount: items.length +
                                  (state.isServerCallLogsLoadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index >= items.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child:
                                          CircularProgressIndicator.adaptive(),
                                    ),
                                  );
                                }

                                final item = items[index];
                                if (item is Map<String, String>) {
                                  return Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(2, 12, 2, 8),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          item['date'] ?? '',
                                          style: const TextStyle(
                                            color: Color(0xFF6B7280),
                                            fontFamily: 'Gilroy',
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          item['year'] ?? '',
                                          style: const TextStyle(
                                            color: Color(0xFF9CA3AF),
                                            fontFamily: 'Gilroy',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                final callItem = item as SipCallLogEntry;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _journalLogCard(
                                    context,
                                    callItem,
                                    expanded: _expandedCallLogId == callItem.id,
                                    onTap: () {
                                      _updateView(() {
                                        _expandedCallLogId =
                                            _expandedCallLogId == callItem.id
                                                ? null
                                                : callItem.id;
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                          if (railEntries.length > 1)
                            Positioned(
                              top: 10,
                              right: 8,
                              bottom: 18,
                              child: _journalDateRail(
                                entries: railEntries,
                                items: items,
                              ),
                            ),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }

  List<_SipJournalRailEntry> _buildJournalRailEntries(List<Object> items) {
    final result = <_SipJournalRailEntry>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item is Map<String, String>) {
        final date = item['date'] ?? '';
        final year = item['year'] ?? '';
        result.add(
          _SipJournalRailEntry(
            itemIndex: i,
            label: year.isEmpty ? date : '$date, $year',
          ),
        );
      }
    }
    return result;
  }

  double _journalScrollOffsetForItemIndex(List<Object> items, int itemIndex) {
    double offset = 0;
    for (var i = 0; i < itemIndex; i++) {
      final item = items[i];
      offset += item is Map<String, String> ? 44 : 96;
    }
    return offset;
  }

  void _showJournalDateRailOverlay(String label, {double? top}) {
    _journalDateRailOverlayTimer?.cancel();
    _updateView(() {
      _journalDateRailLabel = label;
      if (top != null) {
        _journalDateRailTop = top;
      }
    });
    _journalDateRailOverlayTimer = Timer(const Duration(milliseconds: 720), () {
      if (!mounted) return;
      _updateView(() {
        _journalDateRailLabel = null;
        _journalDateRailTop = null;
      });
    });
  }

  void _jumpToJournalDateSection(
    _SipJournalRailEntry entry,
    List<Object> items, {
    double? overlayTop,
  }) {
    if (!_journalListController.hasClients) return;
    final maxExtent = _journalListController.position.maxScrollExtent;
    final targetOffset =
        _journalScrollOffsetForItemIndex(items, entry.itemIndex).clamp(
      0.0,
      maxExtent,
    );
    _journalListController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
    _showJournalDateRailOverlay(entry.label, top: overlayTop);
  }

  Widget _journalDateRail({
    required List<_SipJournalRailEntry> entries,
    required List<Object> items,
  }) {
    double overlayTop = 0;

    void handlePosition(Offset localPosition, double maxHeight) {
      if (entries.isEmpty) return;
      final slotHeight = maxHeight / entries.length;
      final index =
          (localPosition.dy / slotHeight).floor().clamp(0, entries.length - 1);
      overlayTop = (localPosition.dy - 24)
          .clamp(0.0, math.max(0.0, maxHeight - 56))
          .toDouble();
      _jumpToJournalDateSection(
        entries[index],
        items,
        overlayTop: overlayTop,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final activeLabel = _journalDateRailLabel;
        final activeIndex = activeLabel == null
            ? -1
            : entries.indexWhere((entry) => entry.label == activeLabel);
        final bubbleTop = activeIndex < 0
            ? 0.0
            : (_journalDateRailTop ?? overlayTop)
                .clamp(0.0, math.max(0.0, constraints.maxHeight - 56))
                .toDouble();

        return SizedBox(
          width: 28,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 28,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) => handlePosition(
                    details.localPosition,
                    constraints.maxHeight,
                  ),
                  onVerticalDragStart: (details) => handlePosition(
                    details.localPosition,
                    constraints.maxHeight,
                  ),
                  onVerticalDragUpdate: (details) => handlePosition(
                    details.localPosition,
                    constraints.maxHeight,
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 18,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFE3E8F1)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (final entry in entries)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              width:
                                  _journalDateRailLabel == entry.label ? 7 : 5,
                              height:
                                  _journalDateRailLabel == entry.label ? 7 : 5,
                              decoration: BoxDecoration(
                                color: _journalDateRailLabel == entry.label
                                    ? const Color(0xFF1E2E52)
                                    : const Color(0xFF9DAABE),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (activeIndex >= 0)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOutCubic,
                  top: bubbleTop,
                  right: 24,
                  child: IgnorePointer(
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey(_journalDateRailLabel),
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 140),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.scale(
                            scale: lerpDouble(0.92, 1.0, value)!,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 76),
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2E52),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1E2E52)
                                  .withValues(alpha: 0.18),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _journalDateRailLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Gilroy',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<Object> _buildJournalItemsWithHeaders(List<SipCallLogEntry> calls) {
    final sorted = [...calls]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final result = <Object>[];
    DateTime? lastDate;

    for (final call in sorted) {
      final dateOnly = DateTime(
        call.timestamp.year,
        call.timestamp.month,
        call.timestamp.day,
      );
      if (lastDate == null || dateOnly != lastDate) {
        result.add(_formatJournalDateHeader(call.timestamp));
        lastDate = dateOnly;
      }
      result.add(call);
    }

    return result;
  }

  Map<String, String> _formatJournalDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(itemDate).inDays;

    if (difference == 0) {
      return {'date': 'Сегодня', 'year': '${date.year}'};
    }
    if (difference == 1) {
      return {'date': 'Вчера', 'year': '${date.year}'};
    }

    final months = <int, String>{
      1: 'января',
      2: 'февраля',
      3: 'марта',
      4: 'апреля',
      5: 'мая',
      6: 'июня',
      7: 'июля',
      8: 'августа',
      9: 'сентября',
      10: 'октября',
      11: 'ноября',
      12: 'декабря',
    };

    return {
      'date': '${date.day} ${months[date.month] ?? ''}',
      'year': '${date.year}',
    };
  }

  Widget _journalFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFF111827) : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF111827).withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF111827),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _journalLogCard(
    BuildContext context,
    SipCallLogEntry item, {
    required bool expanded,
    required VoidCallback onTap,
    bool compact = false,
  }) {
    final accentColor = _callLogAccentColor(item);
    final fillColor = _callLogFillColor(item);
    final logIcon = _callLogIcon(item);
    final callDialTarget = _callLogDialTarget(item);

    final tile = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      onTap: onTap,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(logIcon, color: accentColor, size: 18),
      ),
      title: Text(
        item.target,
        style: const TextStyle(
          color: Color(0xFF111827),
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        _buildCallLogSubtitle(item, compact: compact),
        style: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
      trailing: compact
          ? CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () async {
                _openDialerWithNumber(callDialTarget);
                await _startDialCall(fallbackNumber: callDialTarget);
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  CupertinoIcons.phone_fill,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            )
          : Text(
              _formatTime(item.timestamp),
              style: const TextStyle(
                color: Color(0xFFD1D5DB),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
    );

    final card = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF111827).withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            tile,
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 180),
              crossFadeState: expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _callActionButton(
                            label: 'В набор',
                            icon: CupertinoIcons.circle_grid_3x3_fill,
                            onTap: () => _openDialerWithNumber(callDialTarget),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _callActionButton(
                            label: 'Добавить',
                            icon: CupertinoIcons.add_circled,
                            onTap: () => _showAddNumberSheetFor(
                              callDialTarget,
                              suggestedName: item.target == callDialTarget
                                  ? null
                                  : item.target,
                              leadId: item.serverLeadId,
                              showCreateLead: false,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _callActionButton(
                            label: 'История',
                            icon: CupertinoIcons.clock,
                            onTap: () => _openCallLogHistory(item),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _callActionButton(
                            label: 'Инфо',
                            icon: CupertinoIcons.info_circle,
                            onTap: () => _openCallLogDetails(item),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Dismissible(
      key: ValueKey('swipe_call_${item.id}_${compact ? 'compact' : 'full'}'),
      direction: DismissDirection.horizontal,
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.32,
        DismissDirection.endToStart: 0.32,
      },
      confirmDismiss: (_) async {
        _openDialerWithNumber(callDialTarget);
        await _startDialCall(fallbackNumber: callDialTarget);
        return false;
      },
      background: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF22C55E),
          borderRadius: BorderRadius.circular(22),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.centerLeft,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.phone_fill, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text(
              'Позвонить',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Gilroy',
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF22C55E),
          borderRadius: BorderRadius.circular(22),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.centerRight,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Позвонить',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Gilroy',
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 10),
            Icon(CupertinoIcons.phone_fill, color: Colors.white, size: 22),
          ],
        ),
      ),
      child: card,
    );
  }

  Widget _searchView(BuildContext context, SipUiState state) {
    if (_contactsEnabled && !_contactsLoaded) {
      unawaited(_loadContacts());
    }

    final query = _searchViewQuery.trim();
    final lowerQuery = query.toLowerCase();
    final queryDigits = _digitsOnly(query);
    final availableSources = _availableSearchSources();
    final callEntries =
        state.serverCallLogs.isNotEmpty ? state.serverCallLogs : state.callLogs;
    final recentCalls = callEntries.take(12).toList(growable: false);

    final contactResults = (query.isEmpty
            ? const <_SipContactSuggestion>[]
            : _displayContacts.where((contact) {
                return contact.name.toLowerCase().contains(lowerQuery) ||
                    (queryDigits.isNotEmpty &&
                        (contact.normalizedPhone.contains(queryDigits) ||
                            _nameToT9Digits(contact.name)
                                .contains(queryDigits)));
              }).toList(growable: false))
        .take(8)
        .toList(growable: false);

    final journalResults = query.isEmpty
        ? const <SipCallLogEntry>[]
        : callEntries
            .where((item) {
              final target = item.target.toLowerCase();
              final targetDigits = _digitsOnly(_callLogDialTarget(item));
              final phoneMatch =
                  queryDigits.isNotEmpty && targetDigits.contains(queryDigits);
              return target.contains(lowerQuery) || phoneMatch;
            })
            .take(10)
            .toList(growable: false);

    final leadResults = query.isEmpty
        ? const <Lead>[]
        : _searchLeadResults.where((lead) {
            final name = lead.name.toLowerCase();
            final phone = (lead.phone ?? '').trim();
            final phoneDigits = _digitsOnly(phone);
            return name.contains(lowerQuery) ||
                (queryDigits.isNotEmpty && phoneDigits.contains(queryDigits));
          }).toList(growable: false);

    final isEmpty = query.isEmpty;
    final noResults = !isEmpty &&
        contactResults.isEmpty &&
        journalResults.isEmpty &&
        (!_leadSearchEnabled || (!_isLeadSearchLoading && leadResults.isEmpty));

    return Column(
      key: const ValueKey('search'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: _cleanSearchField(
            placeholder: 'Поиск',
            autofocus: true,
            controller: _searchViewController,
            onChanged: _handleUnifiedSearchChanged,
          ),
        ),
        if (availableSources.length > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final source in availableSources) ...[
                    _searchSourceChip(
                      source: source,
                      selected: _searchSource == source,
                      onTap: () => _selectSearchSource(source),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
        Expanded(
          child: isEmpty
              ? recentCalls.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Недавних звонков пока нет',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                      children: [
                        Row(
                          children: const [
                            Text(
                              'Недавние звонки',
                              style: TextStyle(
                                color: Color(0xFF111827),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...recentCalls.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _journalLogCard(
                              context,
                              item,
                              compact: true,
                              expanded: _expandedCallLogId == item.id,
                              onTap: () {
                                _updateView(() {
                                  _expandedCallLogId =
                                      _expandedCallLogId == item.id
                                          ? null
                                          : item.id;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    )
              : noResults
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Ничего не найдено',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                      children: [
                        if (_searchSource == _SipSearchSource.calls) ...[
                          _sectionHeader('Вызовы', journalResults.length),
                          const SizedBox(height: 10),
                          ...journalResults.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _journalLogCard(
                                context,
                                item,
                                compact: true,
                                expanded: _expandedCallLogId == item.id,
                                onTap: () {
                                  _updateView(() {
                                    _expandedCallLogId =
                                        _expandedCallLogId == item.id
                                            ? null
                                            : item.id;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                        if (_searchSource == _SipSearchSource.contacts &&
                            _contactsEnabled) ...[
                          _sectionHeader('Контакты', contactResults.length),
                          const SizedBox(height: 10),
                          ...contactResults.map(
                            (contact) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _contactTile(
                                suggestion: contact,
                                onTap: () {
                                  _fillContactNumber(contact);
                                  _updateView(() => _bottomTabIndex = 0);
                                },
                                onCallTap: () async {
                                  _updateView(() => _bottomTabIndex = 0);
                                  await _fillAndCallContact(contact);
                                },
                              ),
                            ),
                          ),
                        ],
                        if (_searchSource == _SipSearchSource.leads &&
                            _leadSearchEnabled) ...[
                          _sectionHeader('Лиды', leadResults.length),
                          const SizedBox(height: 10),
                          if (_isLeadSearchLoading)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Center(
                                child: CircularProgressIndicator.adaptive(),
                              ),
                            ),
                          ...leadResults.map(
                            (lead) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _leadSearchTile(lead),
                            ),
                          ),
                        ],
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _searchSourceChip({
    required _SipSearchSource source,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final label = switch (source) {
      _SipSearchSource.calls => 'Вызовы',
      _SipSearchSource.contacts => 'Контакты',
      _SipSearchSource.leads => 'Лиды',
    };

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFF111827) : const Color(0xFFF0F0F0),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF111827).withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF111827),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  String _buildCallLogSubtitle(SipCallLogEntry item, {required bool compact}) {
    final label = _resolvedCallLogLabel(context, item);
    final time = _formatTime(item.timestamp);
    final duration = item.isMissed ? null : _formatDuration(item.duration);
    final dialTarget = _callLogDialTarget(item);

    if (compact) {
      if (dialTarget == item.target) {
        return '$label • $time';
      }
      return '$dialTarget • $time';
    }

    if (dialTarget == item.target) {
      return duration == null ? '$label • $time' : '$label • $duration';
    }

    return duration == null
        ? '$label • $dialTarget'
        : '$label • $duration • $dialTarget';
  }

  Widget _callActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        height: 74,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF111827).withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: const Color(0xFF374151)),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontFamily: 'Gilroy',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _leadSearchTile(Lead lead) {
    final phone = (lead.phone ?? '').trim();

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF111827).withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          onTap: () => _fillLeadPhone(lead),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              CupertinoIcons.person_crop_circle,
              color: Color(0xFF6B7280),
              size: 22,
            ),
          ),
          title: Text(
            lead.name.trim().isEmpty ? 'Без имени' : lead.name,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            phone.isEmpty ? 'Нет телефона' : phone,
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          trailing: phone.isEmpty
              ? null
              : CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () async => _callLead(lead),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      CupertinoIcons.phone_fill,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _cleanSearchField({
    required String placeholder,
    TextEditingController? controller,
    required ValueChanged<String> onChanged,
    bool autofocus = false,
    VoidCallback? onClear,
  }) {
    final hasText = controller?.text.trim().isNotEmpty ?? false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF111827).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: CupertinoTextField(
        controller: controller,
        autofocus: autofocus,
        textInputAction: TextInputAction.search,
        decoration: const BoxDecoration(),
        style: const TextStyle(
          color: Color(0xFF111827),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        placeholderStyle: const TextStyle(
          color: Color(0xFFD1D5DB),
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        prefix: const Padding(
          padding: EdgeInsetsDirectional.fromSTEB(14, 0, 10, 0),
          child: Icon(
            CupertinoIcons.search,
            color: Color(0xFF9CA3AF),
            size: 18,
          ),
        ),
        suffix: hasText && onClear != null
            ? CupertinoButton(
                padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 12, 0),
                minimumSize: Size.zero,
                onPressed: onClear,
                child: const Icon(
                  CupertinoIcons.xmark_circle_fill,
                  color: Color(0xFF9CA3AF),
                  size: 18,
                ),
              )
            : const SizedBox(width: 12),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
        placeholder: placeholder,
        onChanged: onChanged,
      ),
    );
  }

  String _declineSearchResultsLabel(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod10 == 1 && mod100 != 11) {
      return 'результат';
    }
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return 'результата';
    }
    return 'результатов';
  }

  Widget _bottomSwitcher(BuildContext context, {bool embedded = false}) {
    if (embedded) return const SizedBox.shrink();
    return _ios26LiquidNavBar(context);
  }
}

class _SipJournalRailEntry {
  final int itemIndex;
  final String label;

  const _SipJournalRailEntry({
    required this.itemIndex,
    required this.label,
  });
}
