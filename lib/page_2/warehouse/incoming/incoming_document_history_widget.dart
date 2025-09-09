
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/incoming_document_history/incoming_document_history_bloc.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_history_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class IncomingDocumentHistoryWidget extends StatefulWidget {
  final int documentId;

  const IncomingDocumentHistoryWidget({
    Key? key,
    required this.documentId,
  }) : super(key: key);

  @override
  _IncomingDocumentHistoryWidgetState createState() => _IncomingDocumentHistoryWidgetState();
}

class _IncomingDocumentHistoryWidgetState extends State<IncomingDocumentHistoryWidget> {
  bool isHistoryExpanded = false;
  List<IncomingDocumentHistory> history = [];

  @override
  void initState() {
    super.initState();
    context.read<IncomingDocumentHistoryBloc>().add(FetchIncomingDocumentHistory(widget.documentId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IncomingDocumentHistoryBloc, IncomingDocumentHistoryState>(
      builder: (context, state) {
        if (state is IncomingDocumentHistoryLoaded) {
          history = state.history;
        } else if (state is IncomingDocumentHistoryError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.red,
              elevation: 3,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              duration: const Duration(seconds: 3),
            ),
          );
        }

        // Всегда показываем контейнер с заголовком, даже при загрузке
        return _buildExpandableHistoryContainer(
          AppLocalizations.of(context)!.translate('document_history') ?? 'История документа',
          _buildHistoryItems(history),
          isHistoryExpanded,
          () {
            setState(() {
              isHistoryExpanded = !isHistoryExpanded;
            });
          },
          isLoading: state is IncomingDocumentHistoryLoading,
        );
      },
    );
  }

  Widget _buildExpandableHistoryContainer(
    String title,
    List<String> items,
    bool isExpanded,
    VoidCallback onTap, {
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(right: 16, left: 16, top: 16, bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FD),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleRow(title),
            const SizedBox(height: 8),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: isExpanded
                  ? SizedBox(
                      height: 250,
                      child: SingleChildScrollView(
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator(color: Color(0xff1E2E52)))
                            : _buildItemList(items),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Row _buildTitleRow(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: Color(0xff1E2E52),
          ),
        ),
        Image.asset(
          'assets/icons/tabBar/dropdown.png',
          width: 16,
          height: 16,
        ),
      ],
    );
  }

  Column _buildItemList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return _buildHistoryItem(item);
      }).toList(),
    );
  }

  Widget _buildHistoryItem(String item) {
    final parts = item.split('\n');
    final status = parts[0];
    final userName = parts.length > 1 ? parts[1] : '';
    final additionalDetails = parts.sublist(2);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusRow(status, userName),
          const SizedBox(height: 10),
          if (additionalDetails.isNotEmpty) _buildAdditionalDetails(additionalDetails),
        ],
      ),
    );
  }

  Row _buildStatusRow(String status, String userName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            status,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            userName,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Column _buildAdditionalDetails(List<String> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: details.where((detail) => detail.isNotEmpty).map((detail) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                detail,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w400,
                  color: Color(0xff1E2E52),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  List<String> _buildHistoryItems(List<IncomingDocumentHistory> history) {
    return history.map((entry) {
      final formattedDate = entry.date != null
          ? DateFormat('dd.MM.yyyy HH:mm').format(entry.date!.toLocal())
          : AppLocalizations.of(context)!.translate('') ?? '';
      String historyDetail = '${entry.status ?? ''}\n${entry.user?.fullName ?? 'Unknown'} $formattedDate';

      if (entry.changes != null && entry.changes!.isNotEmpty) {
        for (var change in entry.changes!) {
          if (change.body?.approvedNewValue != null || change.body?.approvedPreviousValue != null) {
            String previous = change.body!.approvedPreviousValue == 1 ? 'Проведен' : 'Не проведен';
            String newValue = change.body!.approvedNewValue == true ? 'Проведен' : 'Не проведен';
            historyDetail += '\n${AppLocalizations.of(context)!.translate('status_history') ?? 'Статус'}: $previous > $newValue';
          }
        }
      }

      return historyDetail;
    }).toList();
  }
}