import 'package:crm_task_manager/models/deal/deal_model.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_state.dart';

class DealStatusWidget extends StatefulWidget {
  final String? selectedDealStatus;
  final ValueChanged<String?> onChanged;

  const DealStatusWidget({
    super.key,
    required this.selectedDealStatus,
    required this.onChanged,
  });

  @override
  State<DealStatusWidget> createState() => _DealStatusWidgetState();
}

class _DealStatusWidgetState extends State<DealStatusWidget> {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return BlocBuilder<DealBloc, DealState>(
      builder: (context, state) {
        List<DropdownMenuItem<String>> dropdownItems = [];
        if (state is DealLoading) {
          dropdownItems = [
            DropdownMenuItem(
              value: null,
                child: Text(
                  AppLocalizations.of(context)!.translate('loading'),
                  style: textStyles.bodyMd.copyWith(color: colors.textPrimary),
                ),
              ),
          ];
        } else if (state is DealLoaded) {
          if (state.dealStatuses.isEmpty) {
            dropdownItems = [
              DropdownMenuItem(
                value: null,
                child: Text(
                  AppLocalizations.of(context)!.translate('no_deal_status'),
                  style: textStyles.bodyMd.copyWith(color: colors.textPrimary),
                ),
              ),
            ];
          } else {
            dropdownItems = state.dealStatuses.map<DropdownMenuItem<String>>((DealStatus status) {
              return DropdownMenuItem<String>(
                value: status.id.toString(),
                child: Text(
                  status.title,
                  style: textStyles.bodyMd.copyWith(color: colors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList();
            if (state.dealStatuses.length == 1) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                widget.onChanged(state.dealStatuses.first.id.toString());
              });
            }
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('deal_status'),
              style: textStyles.bodyLg.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
                initialValue: dropdownItems.any((item) => item.value == widget.selectedDealStatus)
                    ? widget.selectedDealStatus
                    : null,
                hint: Text(
                  AppLocalizations.of(context)!.translate('select_deal_status'),
                  style: textStyles.bodyMd.copyWith(color: colors.fieldHint),
                ),
                items: dropdownItems,
                onChanged: widget.onChanged,
                validator: (value) {
                  if (value == null) {
                    return AppLocalizations.of(context)!.translate('field_required');
                  }
                  return null;
                },
                decoration: InputDecoration(
                  filled: true, 
                  fillColor: colors.fieldBg,
                  labelStyle: textStyles.bodyMd.copyWith(color: colors.fieldHint),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: colors.fieldBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: colors.fieldBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: colors.buttonPrimaryBg),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: colors.error, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: colors.error, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  errorStyle: textStyles.bodySm.copyWith(
                    color: colors.error,
                  ),
                ),
                dropdownColor: colors.surfacePrimary,
                icon: Padding(
                  padding: const EdgeInsets.only(right: 6), 
                  child: Transform.rotate(
                    angle: 90 * 3.1415926535 / 180,
                    child: Image.asset(
                      'assets/icons/arrow_down.png',
                      width: 10,
                      height: 10,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
