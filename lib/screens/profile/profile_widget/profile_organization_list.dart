import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/theme/theme_context_extensions.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
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
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    return BlocBuilder<OrganizationBloc, OrganizationState>(
      builder: (context, state) {
        List<DropdownMenuItem<String>> dropdownItems = [];

        if (state is OrganizationLoading) {
          dropdownItems = [
            DropdownMenuItem(
              value: null,
              child: Text(
                localizations.translate('loading'),
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
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
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
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
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  ),
                ),
              );
            }).toList();
          }
        } else if (state is OrganizationError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showCustomSnackBar(
              context: context,
              message: state.message,
              isSuccess: false,
            );
          });
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
              padding: const EdgeInsets.only(bottom: 0),
              child: Text(
                localizations.translate('organizations'),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.surfaceSecondary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.borderPrimary),
              ),
              child: DropdownButtonFormField<String>(
                value: selectedOrganization,
                hint: Text(
                  '',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  ),
                ),
                items: dropdownItems,
                onChanged: widget.onChanged,
                isExpanded: true,
                decoration: InputDecoration(
                  labelStyle: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: colors.surfaceSecondary),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: colors.surfaceSecondary),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: colors.surfaceSecondary),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: colors.surfaceSecondary,
                ),
                dropdownColor: colors.surfacePrimary,
                icon: Transform.translate(
                  offset: const Offset(4, 0),
                  child: Transform.rotate(
                    angle: 90 * (3.1415926535897932 / 180),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: colors.iconSecondary,
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
