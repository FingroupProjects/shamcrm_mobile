import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/organization/organization_bloc.dart';
import 'package:crm_task_manager/bloc/organization/organization_state.dart';

class OrganizationWidget extends StatefulWidget {
  final String? selectedOrganization;
  final ValueChanged<String?> onChanged;

  const OrganizationWidget({
    super.key,
    required this.selectedOrganization,
    required this.onChanged,
  });

  @override
  State<OrganizationWidget> createState() => _OrganizationWidgetState();
}

class _OrganizationWidgetState extends State<OrganizationWidget> {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return BlocBuilder<OrganizationBloc, OrganizationState>(
      builder: (context, state) {
        List<DropdownMenuItem<String>> dropdownItems = [];

        if (state is OrganizationLoading) {
          dropdownItems = [
            DropdownMenuItem(
              value: null,
              child: Text(
                localizations.translate('loading'),
                style: context.appTextStyles.bodySm.copyWith(
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textPrimary,
                ),
              ),
            ),
          ];
        } else if (state is OrganizationLoaded) {
          if (state.organizations.isEmpty) {
            dropdownItems = [
              DropdownMenuItem(
                value: null,
                child: Text(
                  localizations.translate('no_organizations'),
                  style: context.appTextStyles.bodySm.copyWith(
                    fontWeight: FontWeight.w500,
                    color: context.appColors.textPrimary,
                  ),
                ),
              ),
            ];
          } else {
            dropdownItems = state.organizations
                .map<DropdownMenuItem<String>>((organization) {
              return DropdownMenuItem<String>(
                value: organization.id.toString(),
                child: Text(
                  organization.name,
                  style: context.appTextStyles.bodySm.copyWith(
                    fontWeight: FontWeight.w500,
                    color: context.appColors.textPrimary,
                  ),
                ),
              );
            }).toList();
          }
        } else if (state is OrganizationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: context.appTextStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textInverse,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: context.appColors.error,
              elevation: 3,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              duration: const Duration(seconds: 3),
            ),
          );
        }

        String? selectedOrganization = widget.selectedOrganization;

        if (selectedOrganization != null &&
            !dropdownItems.any((item) => item.value == selectedOrganization)) {
          selectedOrganization =
              dropdownItems.isNotEmpty ? dropdownItems.first.value : null;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.zero,
              child: Text(
                localizations.translate('organizations'),
                style: context.appTextStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textPrimary,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.appColors.surfacePrimary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.appColors.borderSubtle),
                boxShadow: context.appShadows.card,
              ),
              child: DropdownButtonFormField<String>(
                initialValue: selectedOrganization,
                isDense: true,
                isExpanded: true,
                hint: Text(
                  "",
                  style: context.appTextStyles.bodySm.copyWith(
                    fontWeight: FontWeight.w500,
                    color: context.appColors.textPrimary,
                  ),
                ),
                items: dropdownItems,
                onChanged: widget.onChanged,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.only(
                    left: 12,
                    right: 12,
                    top: 12,
                    bottom: 12,
                  ),
                  filled: true,
                  fillColor: context.appColors.fieldBg,
                  labelStyle: TextStyle(color: context.appColors.fieldHint),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                dropdownColor: context.appColors.surfacePrimary,
                icon: Transform.translate(
                  offset: const Offset(8, 0),
                  child: SizedBox(
                    width: 20,
                    height: 16,
                    child: Center(
                      child: Transform.rotate(
                        angle: 90 * (3.1415926535897932 / 180),
                        child: Image.asset(
                          'assets/icons/arrow-right.png',
                          width: 16,
                          height: 16,
                        ),
                      ),
                    ),
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
