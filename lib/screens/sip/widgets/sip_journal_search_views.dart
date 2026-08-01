part of 'package:crm_task_manager/screens/sip/sip_screen.dart';

extension _SipJournalSearchViewsExtension on _SipScreenState {
  Widget _journalView(BuildContext context, SipUiState state) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.appColors;
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
                placeholder: l10n.translate('telephony_search_calls'),
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
                          style: TextStyle(
                            color: colors.textSecondary,
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
                                          style: TextStyle(
                                            color: colors.textPrimary,
                                            fontFamily: 'Gilroy',
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          item['year'] ?? '',
                                          style: TextStyle(
                                            color: colors.textMuted,
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
    final colors = context.appColors;
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
                        color: colors.surfaceElevated.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: colors.borderSubtle),
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
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? _TelephonyVisualColors.blue.withValues(
                  alpha: isDark ? 0.24 : 0.14,
                )
              : colors.surfacePrimary.withValues(alpha: isDark ? 0.68 : 0.82),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? _TelephonyVisualColors.blue.withValues(alpha: 0.55)
                : colors.borderSubtle,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: isDark ? 0.18 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? _TelephonyVisualColors.blue : colors.textPrimary,
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
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = _callLogAccentColor(item);
    final fillColor = _callLogFillColor(item);
    final logIcon = _callLogIcon(item);

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
        style: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        _buildCallLogSubtitle(item, compact: compact),
        style: TextStyle(
          color: colors.textSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
      trailing: compact
          ? CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () async {
                _openDialerWithNumber(item.dialTarget);
                await _startDialCall();
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
              style: TextStyle(
                color: colors.textMuted,
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
          color: colors.surfacePrimary.withValues(alpha: isDark ? 0.66 : 0.88),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: isDark ? 0.18 : 0.06),
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
                            onTap: () => _openDialerWithNumber(item.dialTarget),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _callActionButton(
                            label: 'Добавить',
                            icon: CupertinoIcons.add_circled,
                            onTap: () => _showAddNumberSheetFor(
                              item.dialTarget,
                              suggestedName: item.target == item.dialTarget
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
      direction: DismissDirection.startToEnd,
      dismissThresholds: const {DismissDirection.startToEnd: 0.32},
      confirmDismiss: (_) async {
        _openDialerWithNumber(item.dialTarget);
        await _startDialCall();
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
      secondaryBackground: const SizedBox.shrink(),
      child: card,
    );
  }

  Widget _searchView(BuildContext context, SipUiState state) {
    final l10n = AppLocalizations.of(context)!;
    // Loading changes SipScreen state, so it must begin after this build frame.
    // Calling it here synchronously causes "setState() called during build".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_contactsEnabled && !_contactsLoaded) {
        unawaited(_loadContacts());
      }
      if (_searchSource == _SipSearchSource.calls &&
          _unifiedCallSearchPage == 0 &&
          !_isUnifiedCallSearchLoading) {
        unawaited(_loadUnifiedCallResults(reset: true));
      }
      if (_searchSource == _SipSearchSource.leads &&
          _unifiedLeadSearchPage == 0 &&
          !_isLeadSearchLoading) {
        unawaited(_loadUnifiedLeadResults(reset: true));
      }
    });

    final query = _searchViewQuery.trim();
    final lowerQuery = query.toLowerCase();
    final queryDigits = _digitsOnly(query);
    final availableSources = _availableSearchSources();
    final callEntries = _unifiedCallResults;

    final contactResults = _displayContacts.where((contact) {
      return query.isEmpty ||
          contact.name.toLowerCase().contains(lowerQuery) ||
          (queryDigits.isNotEmpty &&
              (contact.normalizedPhone.contains(queryDigits) ||
                  _nameToT9Digits(contact.name).contains(queryDigits)));
    }).toList(growable: false);

    final journalResults = callEntries.where((item) {
      final target = item.target.toLowerCase();
      final targetDigits = _digitsOnly(item.dialTarget);
      final phoneMatch =
          queryDigits.isNotEmpty && targetDigits.contains(queryDigits);
      return query.isEmpty || target.contains(lowerQuery) || phoneMatch;
    }).toList(growable: false);

    final leadResults = _searchLeadResults;
    final isSourceLoading = switch (_searchSource) {
      _SipSearchSource.calls => _isUnifiedCallSearchLoading,
      _SipSearchSource.contacts => _contactsEnabled && _isContactsLoading,
      _SipSearchSource.leads => _isLeadSearchLoading,
    };
    final selectedResultsCount = switch (_searchSource) {
      _SipSearchSource.calls => journalResults.length,
      _SipSearchSource.contacts => contactResults.length,
      _SipSearchSource.leads => leadResults.length,
    };
    final noResults = !isSourceLoading && selectedResultsCount == 0;

    return Column(
      key: const ValueKey('search'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: _cleanSearchField(
            placeholder: l10n.translate('telephony_search'),
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
          child: noResults
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
              : NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.pixels >=
                        notification.metrics.maxScrollExtent - 120) {
                      _loadMoreUnifiedSearchResults();
                    }
                    return false;
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                    children: [
                      if (isSourceLoading)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Center(
                            child: CircularProgressIndicator.adaptive(),
                          ),
                        ),
                      if (_searchSource == _SipSearchSource.calls) ...[
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
                        ...leadResults.map(
                          (lead) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _leadSearchTile(lead),
                          ),
                        ),
                      ],
                      if (_isUnifiedCallSearchLoadingMore ||
                          _isUnifiedLeadSearchLoadingMore)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: CircularProgressIndicator.adaptive(),
                          ),
                        ),
                    ],
                  ),
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
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final label = switch (source) {
      _SipSearchSource.calls => l10n.translate('telephony_calls'),
      _SipSearchSource.contacts => l10n.translate('telephony_contacts'),
      _SipSearchSource.leads => l10n.translate('telephony_leads'),
    };

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? _TelephonyVisualColors.blue.withValues(
                  alpha: isDark ? 0.24 : 0.14,
                )
              : colors.surfacePrimary.withValues(alpha: isDark ? 0.68 : 0.82),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? _TelephonyVisualColors.blue.withValues(alpha: 0.55)
                : colors.borderSubtle,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: isDark ? 0.18 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? _TelephonyVisualColors.blue : colors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _buildCallLogSubtitle(SipCallLogEntry item, {required bool compact}) {
    final label = _resolvedCallLogLabel(context, item);
    final time = _formatTime(item.timestamp);
    final duration = item.isMissed ? null : _formatDuration(item.duration);

    if (compact) {
      if (item.dialTarget == item.target) {
        return '$label • $time';
      }
      return '${item.dialTarget} • $time';
    }

    if (item.dialTarget == item.target) {
      return duration == null ? '$label • $time' : '$label • $duration';
    }

    return duration == null
        ? '$label • ${item.dialTarget}'
        : '$label • $duration • ${item.dialTarget}';
  }

  Widget _callActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        height: 74,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: colors.iconPrimary),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textPrimary,
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
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final phone = (lead.phone ?? '').trim();

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          color: colors.surfacePrimary.withValues(alpha: isDark ? 0.66 : 0.88),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: isDark ? 0.18 : 0.06),
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
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              CupertinoIcons.person_crop_circle,
              color: colors.iconSecondary,
              size: 22,
            ),
          ),
          title: Text(
            lead.name.trim().isEmpty ? 'Без имени' : lead.name,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            phone.isEmpty ? 'Нет телефона' : phone,
            style: TextStyle(
              color: colors.textSecondary,
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
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasText = controller?.text.trim().isNotEmpty ?? false;

    return Container(
      decoration: BoxDecoration(
        color: colors.fieldBg.withValues(alpha: isDark ? 0.72 : 0.88),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: isDark ? 0.18 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: colors.fieldBorder),
      ),
      child: CupertinoTextField(
        controller: controller,
        autofocus: autofocus,
        textInputAction: TextInputAction.search,
        decoration: const BoxDecoration(),
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        placeholderStyle: TextStyle(
          color: colors.fieldHint,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        prefix: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 10, 0),
          child: Icon(
            CupertinoIcons.search,
            color: colors.iconSecondary,
            size: 18,
          ),
        ),
        suffix: hasText && onClear != null
            ? CupertinoButton(
                padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 12, 0),
                minimumSize: Size.zero,
                onPressed: onClear,
                child: Icon(
                  CupertinoIcons.xmark_circle_fill,
                  color: colors.iconSecondary,
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
