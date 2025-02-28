import 'package:crm_task_manager/bloc/history_lead_notice_deal/history_lead_notice_deal_bloc.dart';
import 'package:crm_task_manager/bloc/history_lead_notice_deal/history_lead_notice_deal_event.dart';
import 'package:crm_task_manager/bloc/history_lead_notice_deal/history_lead_notice_deal_state.dart';
import 'package:crm_task_manager/models/lead_history_model.dart';
import 'package:crm_task_manager/models/notice_history_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HistoryDialog extends StatefulWidget {
  final int leadId;

  const HistoryDialog({Key? key, required this.leadId}) : super(key: key);

  @override
  _HistoryDialogState createState() => _HistoryDialogState();
}

class _HistoryDialogState extends State<HistoryDialog> {
  int _selectedTab = 0;
  int? expandedItemId;
Set<int> expandedNoticeIds = {};
Set<int> expandedDealIds = {};
  @override
  void initState() {
    super.initState();
    context.read<HistoryLeadsBloc>().add(FetchLeadHistory(widget.leadId));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildTabs(),
            const SizedBox(height: 16),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
         Text(
            AppLocalizations.of(context)!.translate('history'),
          style: TextStyle(
            fontSize: 20,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Color(0xff1E2E52)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FD),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildTab(AppLocalizations.of(context)!.translate('lead'), 0),
          _buildTab(AppLocalizations.of(context)!.translate('notes'), 1),
          _buildTab(AppLocalizations.of(context)!.translate('deals'), 2),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTab = index);
          switch (index) {
            case 0:
              context
                  .read<HistoryLeadsBloc>()
                  .add(FetchLeadHistory(widget.leadId));
              break;
            case 1:
              context
                  .read<HistoryLeadsBloc>()
                  .add(FetchNoticeHistory(widget.leadId));
              break;
            case 2:
              context
                  .read<HistoryLeadsBloc>()
                  .add(FetchDealHistory(widget.leadId));
              break;
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xff1E2E52) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xff1E2E52),
            ),
          ),
        ),
      ),
    );
  }

 List<Widget> _buildLeadChanges(Changes changes) {
  final Map<String, dynamic> body = {
    "lead_status": {
      "previous_value": changes.leadStatusPreviousValue,
      "new_value": changes.leadStatusNewValue
    },
    "name": {
      "previous_value": changes.historyNamePreviousValue,
      "new_value": changes.historyNameNewValue
    },
    "phone": {
      "previous_value": changes.phonePreviousValue,
      "new_value": changes.phoneNewValue
    },
    "email": {
      "previous_value": changes.emailPreviousValue,
      "new_value": changes.emailNewValue
    },
    "region": {
      "previous_value": changes.regionPreviousValue,
      "new_value": changes.regionNewValue
    },
    "manager": {
      "previous_value": changes.managerPreviousValue,
      "new_value": changes.managerNewValue
    },
    "tg_nick": {
      "previous_value": changes.tgNickPreviousValue,
      "new_value": changes.tgNickNewValue
    },
    "birthday": {
      "previous_value": changes.birthdayPreviousValue,
      "new_value": changes.birthdayNewValue
    },
    "description": {
      "previous_value": changes.descriptionPreviousValue,
      "new_value": changes.descriptionNewValue
    },
    "insta_login": {
      "previous_value": changes.instaLoginPreviousValue,
      "new_value": changes.instaLoginNewValue
    },
    "facebook_login": {
      "previous_value": changes.facebookLoginPreviousValue,
      "new_value": changes.facebookLoginNewValue
    }
  };

  // Словарь переводов ключей
  final Map<String, String> translations = {
    "name": "Название",
    "phone": "Телефон",
    "email": "Email",
    "region": "Регион",
    "manager": "Менеджер",
    "tg_nick": "Telegram",
    "birthday": "День рождения",
    "description": "Описание",
    "insta_login": "Instagram",
    "facebook_login": "Facebook",
    "lead_status": "Статус"
  };

  String formatDateIfNeeded(String key, dynamic value) {
    if (key == 'birthday' && value != null && value.toString().isNotEmpty) {
      try {
        DateTime date;
        String dateStr = value.toString();
        
        // Пробуем распарсить дату, даже если она в разных форматах
        if (dateStr.contains('T')) {
          date = DateTime.parse(dateStr);
        } else {
          // Для простых строк без времени
          date = DateTime.parse(dateStr);
        }
        
        return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
      } catch (e) {
        return value.toString();
      }
    }
    return value?.toString() ?? '-';
  }

  return body.entries.map((entry) {
    final previous = entry.value['previous_value'];
    final newValue = entry.value['new_value'];

    if (previous == null && newValue == null) {
      return const SizedBox.shrink();
    }

    final String translatedKey = translations[entry.key] ?? entry.key;
    
    final formattedPrevious = formatDateIfNeeded(entry.key, previous);
    final formattedNewValue = formatDateIfNeeded(entry.key, newValue);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        '$translatedKey: $formattedPrevious → $formattedNewValue',
        style: const TextStyle(
          fontSize: 14,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w400,
          color: Color(0xff8F9BB3),
        ),
      ),
    );
  }).toList();
}

//И здесь name, phone, email, region, manager, tg_nick, birthday, description, insta_login, facebook_login
  Widget _buildHistoryItem(LeadHistory item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
        color: const Color(0xFFF4F7FD),
          borderRadius: BorderRadius.circular(8),
          
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.black.withOpacity(0.05),
          //     blurRadius: 4,
          //     offset: const Offset(0, 2),
          //   ),
          // ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.status,
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w600,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                ),
                Text(
                  _formatDate(item.date),
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w400,
                    color: Color(0xff8F9BB3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.user.name,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
                color: Color(0xff1E2E52),
              ),
            ),
            if (item.changes != null) ..._buildLeadChanges(item.changes!),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FD),
        borderRadius: BorderRadius.circular(8),
      ),
      child: BlocBuilder<HistoryLeadsBloc, HistoryState>(
        builder: (context, state) {
          if (state is HistoryLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xff1E2E52)),
            );
          } else if (state is HistoryError) {
            return Center(child: Text(state.message));
          } else if (state is LeadHistoryLoaded) {
            return _buildLeadHistoryContent(state.history);
          } else if (state is NoticeHistoryLoaded) {
            return _buildNoticeHistoryContent(state.history);
          } else if (state is DealHistoryLoaded) {
            return _buildDealHistoryContent(state.history);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLeadHistoryContent(List<LeadHistory> history) {
    return SingleChildScrollView(
      child: Column(
        children: history.map((item) => _buildHistoryItem(item)).toList(),
      ),
    );
  }

Widget _buildNoticeHistoryContent(List<NoticeHistory> notices) {
  if (notices.isEmpty) {
    return Center(
      child: Text(
        'Нет данных для отображения',
        style: const TextStyle(
          fontSize: 14,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w500,
          color: Color(0xff8F9BB3),
        ),
      ),
    );
  }
  
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: notices.map((notice) {
        final bool isExpanded = expandedNoticeIds.contains(notice.id);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    expandedNoticeIds.remove(notice.id);
                  } else {
                    expandedNoticeIds.add(notice.id);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notice.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: Color(0xff1E2E52),
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: const Color(0xff8F9BB3),
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded) ...[
              ...notice.history
                  .map((item) => _buildNoticeHistoryItem(item))
                  .toList(),
            ],
            const Divider(color: Color(0xFFE0E0E0), height: 24),
          ],
        );
      }).toList(),
    ),
  );
}

Widget _buildDealHistoryContent(List<DealHistoryLead> deals) {
  if (deals.isEmpty) {
    return Center(
      child: Text(
        'Нет данных для отображения',
        style: const TextStyle(
          fontSize: 14,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w500,
          color: Color(0xff8F9BB3),
        ),
      ),
    );
  }
  
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: deals.map((deal) {
        final bool isExpanded = expandedDealIds.contains(deal.id);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    expandedDealIds.remove(deal.id);
                  } else {
                    expandedDealIds.add(deal.id);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        deal.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: Color(0xff1E2E52),
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: const Color(0xff8F9BB3),
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded) ...[
              ...deal.history
                  .map((item) => _buildDealHistoryItem(item))
                  .toList(),
            ],
            const Divider(color: Color(0xFFE0E0E0), height: 24),
          ],
        );
      }).toList(),
    ),
  );
}
  Widget _buildNoticeHistoryItem(HistoryItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
        color: const Color(0xFFF4F7FD),
          borderRadius: BorderRadius.circular(8),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.black.withOpacity(0.05),
          //     blurRadius: 4,
          //     offset: const Offset(0, 2),
          //   ),
          // ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.status,
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w600,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                ),
                Text(
                  _formatDate(item.date),
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w400,
                    color: Color(0xff8F9BB3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.user.name,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
                color: Color(0xff1E2E52),
              ),
            ),
            if (item.changes.isNotEmpty)
              ..._buildNoticeChanges(item.changes.first),
          ],
        ),
      ),
    );
  }

  Widget _buildDealHistoryItem(HistoryItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
        color: const Color(0xFFF4F7FD),
          borderRadius: BorderRadius.circular(8),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.black.withOpacity(0.05),
          //     blurRadius: 4,
          //     offset: const Offset(0, 2),
          //   ),
          // ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.status,
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w600,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                ),
                Text(
                  _formatDate(item.date),
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w400,
                    color: Color(0xff8F9BB3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.user.name,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
                color: Color(0xff1E2E52),
              ),
            ),
            if (item.changes.isNotEmpty)
              ..._buildDealChanges(item.changes.first),
          ],
        ),
      ),
    );
  }

List<Widget> _buildNoticeChanges(ChangesLead changes) {
  final Map<String, dynamic> body = changes.body;
  if (body.isEmpty) return [];

  // Словарь переводов ключей
  final Map<String, String> translations = {
    'body': 'Описание',
    'date': 'Напоминане',
    'lead': 'Лид',
    'title': 'Тематика',
    'notifications_sent':'Отправить PUSH-уведомление'
  };

  String formatDateIfNeeded(String key, dynamic value) {
  if (key == 'date' && value != null && value.toString().isNotEmpty) {
    try {
      DateTime date;
      String dateStr = value.toString();
      
      // Парсим дату
      if (dateStr.contains('T')) {
        date = DateTime.parse(dateStr);
      } else {
        date = DateTime.parse(dateStr);
      }

      return '${date.day.toString().padLeft(2, '0')}.'
             '${date.month.toString().padLeft(2, '0')}.'
             '${date.year} ${date.hour.toString().padLeft(2, '0')}:'
             '${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return value.toString();
    }
  }
  return value?.toString() ?? 'Не указано';
}


  return body.entries.map((entry) {
    if (entry.value is Map) {
      final changeMap = Map<String, dynamic>.from(entry.value as Map);
      final String translatedKey = translations[entry.key] ?? entry.key;

      final formattedPreviousValue = formatDateIfNeeded(entry.key, changeMap['previous_value']);
      final formattedNewValue = formatDateIfNeeded(entry.key, changeMap['new_value']);

      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          '$translatedKey: $formattedPreviousValue → $formattedNewValue',
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w400,
            color: Color(0xff8F9BB3),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }).toList();
}

 List<Widget> _buildDealChanges(ChangesLead changes) {
  final Map<String, dynamic> body = changes.body;
  if (body.isEmpty) return [];
  // Словарь переводов ключей
  final Map<String, String> translations = {
    'sum': 'Сумма',
    'name': 'Название',
    'manager': 'Менеджер',
    'description': 'Описание',
    'end_date': 'Дата завершения',
    'start_date': 'Дата начала',
    'deal_status': 'Статус',
    'lead': 'Лид',
  };
  
  String formatDateIfNeeded(String key, dynamic value) {
    if ((key == 'end_date' || key == 'start_date') && value != null && value.toString().isNotEmpty) {
      try {
        final date = DateTime.parse(value.toString());
        return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
      } catch (e) {
        return value.toString();
      }
    }
    return value?.toString() ?? '-';
  }
  
  return body.entries.map((entry) {
    if (entry.value is Map) {
      final changeMap = Map<String, dynamic>.from(entry.value as Map);
      final String translatedKey = translations[entry.key] ?? entry.key;
      
      final formattedPreviousValue = formatDateIfNeeded(entry.key, changeMap['previous_value']);
      final formattedNewValue = formatDateIfNeeded(entry.key, changeMap['new_value']);
      
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          '$translatedKey: $formattedPreviousValue → $formattedNewValue',
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w400,
            color: Color(0xff8F9BB3),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }).toList();
}
String _formatDate(DateTime date) {
 return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}
}