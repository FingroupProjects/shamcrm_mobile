import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class AnalyticsFilterSheet extends StatefulWidget {
  final String selectedPeriod;
  final String selectedManager;
  final String selectedFunnel;
  final String selectedSource;
  final Function(String, String, String, String) onApply;

  const AnalyticsFilterSheet({
    Key? key,
    required this.selectedPeriod,
    required this.selectedManager,
    required this.selectedFunnel,
    required this.selectedSource,
    required this.onApply,
  }) : super(key: key);

  @override
  _AnalyticsFilterSheetState createState() => _AnalyticsFilterSheetState();
}

class _AnalyticsFilterSheetState extends State<AnalyticsFilterSheet> {
  late String _period;
  late String _manager;
  late String _funnel;
  late String _source;

  @override
  void initState() {
    super.initState();
    _period = widget.selectedPeriod;
    _manager = widget.selectedManager;
    _funnel = widget.selectedFunnel;
    _source = widget.selectedSource;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xffE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations?.translate('analytics_filters') ?? 'Фильтры',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff1E2E52),
                    fontFamily: 'Golos',
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  color: const Color(0xff64748B),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Filters
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterSection(
                    label: localizations?.translate('analytics_period') ??
                        'Период',
                    value: _period,
                    items: [
                      localizations?.translate('period_7_days') ??
                          'Последние 7 дней',
                      localizations?.translate('period_30_days') ??
                          'Последние 30 дней',
                      localizations?.translate('period_90_days') ??
                          'Последние 90 дней',
                      localizations?.translate('period_current_year') ??
                          'Текущий год',
                      localizations?.translate('period_last_year') ??
                          'Прошлый год',
                    ],
                    onChanged: (value) => setState(() => _period = value!),
                  ),
                  const SizedBox(height: 20),
                  _buildFilterSection(
                    label: localizations?.translate('analytics_manager') ??
                        'Менеджер',
                    value: _manager,
                    items: [
                      localizations?.translate('all_managers') ??
                          'Все менеджеры',
                      'Иван Петров',
                      'Анна Смирнова',
                      'Дмитрий Козлов',
                      'Елена Васильева',
                    ],
                    onChanged: (value) => setState(() => _manager = value!),
                  ),
                  const SizedBox(height: 20),
                  _buildFilterSection(
                    label: localizations?.translate('analytics_funnel') ??
                        'Воронка',
                    value: _funnel,
                    items: [
                      localizations?.translate('all_funnels') ?? 'Все воронки',
                      localizations?.translate('funnel_sales') ?? 'Продажи',
                      localizations?.translate('funnel_consultations') ??
                          'Консультации',
                      localizations?.translate('funnel_vip') ?? 'VIP клиенты',
                    ],
                    onChanged: (value) => setState(() => _funnel = value!),
                  ),
                  const SizedBox(height: 20),
                  _buildFilterSection(
                    label: localizations?.translate('analytics_source') ??
                        'Источник',
                    value: _source,
                    items: [
                      localizations?.translate('all_sources') ??
                          'Все источники',
                      'Instagram',
                      'WhatsApp',
                      'Telegram',
                      localizations?.translate('source_website') ?? 'Сайт',
                    ],
                    onChanged: (value) => setState(() => _source = value!),
                  ),
                ],
              ),
            ),
          ),
          // Actions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: const Color(0xffE2E8F0)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _period = localizations?.translate('period_30_days') ??
                            'Последние 30 дней';
                        _manager = localizations?.translate('all_managers') ??
                            'Все менеджеры';
                        _funnel = localizations?.translate('all_funnels') ??
                            'Все воронки';
                        _source = localizations?.translate('all_sources') ??
                            'Все источники';
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xffE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      localizations?.translate('reset') ?? 'Сбросить',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff1E2E52),
                        fontFamily: 'Golos',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(_period, _manager, _funnel, _source);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xff1E2E52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      localizations?.translate('apply') ?? 'Применить',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'Golos',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xff64748B),
            fontFamily: 'Golos',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xffE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: Color(0xff64748B)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              borderRadius: BorderRadius.circular(12),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xff0F172A),
                      fontFamily: 'Golos',
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
