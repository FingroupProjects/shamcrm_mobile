part of 'package:crm_task_manager/screens/sip/sip_screen.dart';

extension _SipContactsViewsExtension on _SipScreenState {
  Widget _contactTile({
    required _SipContactSuggestion suggestion,
    required VoidCallback onTap,
    required VoidCallback onCallTap,
    bool compact = false,
  }) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: colors.surfacePrimary.withValues(alpha: isDark ? 0.54 : 0.68),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: compact ? 18 : 20,
            backgroundColor: colors.surfaceElevated,
            backgroundImage: suggestion.photo != null
                ? MemoryImage(suggestion.photo!)
                : null,
            child: suggestion.photo == null
                ? Text(
                    suggestion.name.isEmpty
                        ? '?'
                        : suggestion.name[0].toUpperCase(),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    suggestion.phone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onCallTap,
            child: Container(
              width: compact ? 38 : 44,
              height: compact ? 38 : 44,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                CupertinoIcons.phone_fill,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactsView(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_contactsEnabled && !_contactsLoaded && !_isContactsLoading) {
      unawaited(_loadContacts());
    }

    final contacts = _displayContacts;
    final colors = context.appColors;

    final query = _contactsViewQuery.trim().toLowerCase();
    final queryDigits = _digitsOnly(_contactsViewQuery);
    final filtered = query.isEmpty && queryDigits.isEmpty
        ? contacts
        : contacts.where((contact) {
            return contact.name.toLowerCase().contains(query) ||
                contact.normalizedPhone.contains(queryDigits) ||
                _nameToT9Digits(contact.name).contains(queryDigits);
          }).toList(growable: false);
    final activeTab = _resolvedContactsTabSource();
    final contactIndexLetters = _contactIndexLetters(filtered);
    final refreshTrigger = RefreshIndicator(
      onRefresh: _refreshContactsView,
      color: _TelephonyVisualColors.blue,
      backgroundColor: colors.surfaceElevated,
      child: activeTab == _SipContactsTabSource.leads
          ? NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.pixels >=
                        notification.metrics.maxScrollExtent - 160 &&
                    _contactsLeadHasMore &&
                    !_isContactsLeadLoadingMore &&
                    !_isContactsLeadLoading) {
                  unawaited(_loadMoreContactsLeadResults());
                }
                return false;
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: _contactsLeadResults.length +
                    (_isContactsLeadLoadingMore ? 1 : 0) +
                    ((_isContactsLeadLoading && _contactsLeadResults.isEmpty)
                        ? 1
                        : 0),
                separatorBuilder: (_, index) {
                  if (index >= _contactsLeadResults.length - 1) {
                    return const SizedBox(height: 0);
                  }
                  return const SizedBox(height: 8);
                },
                itemBuilder: (context, index) {
                  if (_isContactsLeadLoading && _contactsLeadResults.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: Center(
                        child: CircularProgressIndicator.adaptive(),
                      ),
                    );
                  }

                  if (index >= _contactsLeadResults.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: CircularProgressIndicator.adaptive(),
                      ),
                    );
                  }

                  final lead = _contactsLeadResults[index];
                  final phone = (lead.phone ?? '').trim();
                  final suggestion = _SipContactSuggestion(
                    name: lead.name,
                    phone: phone,
                    normalizedPhone: _digitsOnly(phone),
                  );
                  return _contactTile(
                    suggestion: suggestion,
                    onTap: () => _fillLeadPhone(lead),
                    onCallTap: () async => _callLead(lead),
                  );
                },
              ),
            )
          : Stack(
              children: [
                ListView.builder(
                  controller: _contactsListController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 42, 16),
                  itemCount: filtered.length + (_isContactsLoading ? 1 : 0),
                  itemExtent: 84,
                  itemBuilder: (context, index) {
                    if (_isContactsLoading && filtered.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 48),
                        child: Center(
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      );
                    }

                    if (index >= filtered.length) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: CircularProgressIndicator.adaptive(),
                          ),
                        ),
                      );
                    }
                    final contact = filtered[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _contactTile(
                        suggestion: contact,
                        onTap: () {
                          _fillContactNumber(contact);
                          _updateView(() {
                            _bottomTabIndex = 0;
                          });
                        },
                        onCallTap: () async {
                          _updateView(() {
                            _bottomTabIndex = 0;
                          });
                          await _fillAndCallContact(contact);
                        },
                      ),
                    );
                  },
                ),
                if (contactIndexLetters.length > 1)
                  Positioned(
                    top: 10,
                    right: 8,
                    bottom: 18,
                    child: _contactsAlphabetRail(
                      letters: contactIndexLetters,
                      contacts: filtered,
                    ),
                  ),
              ],
            ),
    );

    return Column(
      key: const ValueKey('contacts'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Column(
            children: [
              if (_contactsEnabled || _leadSearchEnabled) ...[
                Row(
                  children: [
                    if (_contactsEnabled)
                      Expanded(
                        child: _contactsStatusChip(
                          label: l10n.translate('telephony_contacts'),
                          count: _contactsTotalCount,
                          selected: activeTab == _SipContactsTabSource.contacts,
                          onTap: () => _selectContactsTabSource(
                            _SipContactsTabSource.contacts,
                          ),
                        ),
                      ),
                    if (_contactsEnabled && _leadSearchEnabled)
                      const SizedBox(width: 8),
                    if (_leadSearchEnabled)
                      Expanded(
                        child: _contactsStatusChip(
                          label: l10n.translate('telephony_leads'),
                          count: _leadTotalCount,
                          selected: activeTab == _SipContactsTabSource.leads,
                          loading: _isLeadCountLoading,
                          onTap: () => _selectContactsTabSource(
                            _SipContactsTabSource.leads,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              _cleanSearchField(
                placeholder: activeTab == _SipContactsTabSource.contacts
                    ? l10n.translate('telephony_search_contacts')
                    : l10n.translate('telephony_search_leads'),
                onChanged: _handleContactsViewChanged,
              ),
            ],
          ),
        ),
        Expanded(child: refreshTrigger),
      ],
    );
  }

  Widget _contactsAlphabetRail({
    required List<String> letters,
    required List<_SipContactSuggestion> contacts,
  }) {
    final colors = context.appColors;
    double overlayTop = 0;

    void handlePosition(Offset localPosition, double maxHeight) {
      if (letters.isEmpty) return;
      final slotHeight = maxHeight / letters.length;
      final index =
          (localPosition.dy / slotHeight).floor().clamp(0, letters.length - 1);
      overlayTop = (localPosition.dy - 24)
          .clamp(0.0, math.max(0.0, maxHeight - 56))
          .toDouble();
      _jumpToContactsLetter(
        letters[index],
        contacts,
        overlayTop: overlayTop,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final activeLetter = _contactsIndexOverlayLetter;
        final activeIndex =
            activeLetter == null ? -1 : letters.indexOf(activeLetter);
        final bubbleTop = activeIndex < 0
            ? 0.0
            : (_contactsIndexOverlayTop ?? overlayTop)
                .clamp(0.0, math.max(0.0, constraints.maxHeight - 56))
                .toDouble();

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) =>
              handlePosition(details.localPosition, constraints.maxHeight),
          onVerticalDragStart: (details) =>
              handlePosition(details.localPosition, constraints.maxHeight),
          onVerticalDragUpdate: (details) =>
              handlePosition(details.localPosition, constraints.maxHeight),
          child: SizedBox(
            width: 82,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
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
                        for (final letter in letters)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            width:
                                _contactsIndexOverlayLetter == letter ? 7 : 5,
                            height:
                                _contactsIndexOverlayLetter == letter ? 7 : 5,
                            decoration: BoxDecoration(
                              color: _contactsIndexOverlayLetter == letter
                                  ? const Color(0xFF22C55E)
                                  : colors.iconSecondary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                      ],
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
                        key: ValueKey(_contactsIndexOverlayLetter),
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
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF22C55E),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF22C55E)
                                    .withValues(alpha: 0.22),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _contactsIndexOverlayLetter!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Gilroy',
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _contactsStatusChip({
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onTap,
    bool loading = false,
  }) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = selected
        ? _TelephonyVisualColors.blue.withValues(alpha: 0.55)
        : colors.borderSubtle;
    final labelColor =
        selected ? _TelephonyVisualColors.blue : colors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? _TelephonyVisualColors.blue.withValues(
                  alpha: isDark ? 0.20 : 0.10,
                )
              : colors.surfacePrimary.withValues(alpha: isDark ? 0.68 : 0.82),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: isDark ? 0.16 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TaskStyles.tabTextStyle(context).copyWith(
                  color: labelColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              constraints: const BoxConstraints(minWidth: 32),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: selected
                    ? _TelephonyVisualColors.blue
                    : colors.surfaceElevated,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: borderColor),
              ),
              alignment: Alignment.center,
              child: loading
                  ? SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          selected
                              ? colors.buttonPrimaryFg
                              : colors.textSecondary,
                        ),
                      ),
                    )
                  : Text(
                      '$count',
                      style: TextStyle(
                        color: selected
                            ? colors.buttonPrimaryFg
                            : colors.textSecondary,
                        fontFamily: 'Gilroy',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
