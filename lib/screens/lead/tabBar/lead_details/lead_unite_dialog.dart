import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:crm_task_manager/screens/deal/tabBar/lead_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class LeadUniteDialog extends StatefulWidget {
  final int currentLeadId;

  const LeadUniteDialog({
    super.key,
    required this.currentLeadId,
  });

  @override
  State<LeadUniteDialog> createState() => _LeadUniteDialogState();
}

class _LeadUniteDialogState extends State<LeadUniteDialog> {
  final ApiService _apiService = ApiService();
  LeadData? _selectedLead;
  bool _isSubmitting = false;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
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

  Future<void> _mergeLead() async {
    if (_isSubmitting) return;

    final lead = _selectedLead;
    if (lead == null) {
      _showError(
        AppLocalizations.of(context)!.translate('lead_merge_select_required'),
      );
      return;
    }

    if (lead.id == widget.currentLeadId) {
      _showError(
        AppLocalizations.of(context)!.translate('lead_merge_self_error'),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await _apiService.uniteLead(
        widget.currentLeadId,
        unitedLeadId: lead.id,
      );

      if (!mounted) return;

      if (result['result']?.toString().toLowerCase() == 'success') {
        Navigator.of(context).pop(true);
        return;
      }

      _showError(
        result['message']?.toString() ??
            AppLocalizations.of(context)!.translate('lead_merge_error'),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(
        e.toString().replaceFirst('Exception: ', '').trim().isNotEmpty
            ? e.toString().replaceFirst('Exception: ', '').trim()
            : AppLocalizations.of(context)!.translate('lead_merge_error'),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final maxHeight = MediaQuery.of(context).size.height * 0.9;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560, maxHeight: maxHeight),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        localizations.translate('lead_merge_title'),
                        style: const TextStyle(
                          fontSize: 28,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          color: Color(0xff1E2E52),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        buttonText: localizations.translate('cancel'),
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                        buttonColor: const Color(0xffF4F7FD),
                        textColor: const Color(0xff1E2E52),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        buttonText:
                            localizations.translate('lead_merge_button'),
                        onPressed: _isSubmitting ? null : _mergeLead,
                        buttonColor: const Color(0xff3935E7),
                        textColor: Colors.white,
                        isLoading: _isSubmitting,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(height: 1, color: Color(0xffE7EAF3)),
                const SizedBox(height: 18),
                LeadRadioGroupWidget(
                  excludedLeadIds: [widget.currentLeadId],
                  labelText: localizations.translate('lead_list'),
                  hintText: localizations.translate('lead_merge_placeholder'),
                  searchHintText: localizations.translate('search'),
                  onSelectLead: (lead) {
                    setState(() {
                      _selectedLead = lead;
                    });
                  },
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
