import 'package:crm_task_manager/models/organization_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/widgets/pin_adaptive_contrast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:crm_task_manager/bloc/data_1c/data_1c_bloc.dart';
import 'package:crm_task_manager/bloc/data_1c/data_1c_event.dart';
import 'package:crm_task_manager/bloc/data_1c/data_1c_state.dart';

class UpdateWidget1C extends StatefulWidget {
  final Organization organization;

  const UpdateWidget1C({
    super.key,
    required this.organization,
  });

  @override
  State<UpdateWidget1C> createState() => _UpdateWidget1CState();
}

class _UpdateWidget1CState extends State<UpdateWidget1C>
    with SingleTickerProviderStateMixin {
  bool isLoading = false;
  late ValueNotifier<String?> lastUpdatedNotifier;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    // Инициализация ValueNotifier с текущим значением времени
    lastUpdatedNotifier = ValueNotifier<String?>(
      widget.organization.last1cUpdate != null
          ? DateFormat('dd.MM.yyyy HH:mm')
              .format(DateTime.parse(widget.organization.last1cUpdate!))
          : null,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    lastUpdatedNotifier.dispose(); // Освобождение ресурсов
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final organization = widget.organization;

    return BlocListener<Data1CBloc, Data1CState>(
      listener: (context, state) {
        if (state is Data1CLoading) {
          setState(() {
            isLoading = true;
          });
          _controller.repeat();
        } else if (state is Data1CLoaded) {
          setState(() {
            isLoading = false;
            final updatedOrganization = state.data1C.firstWhere(
              (org) => org.id == widget.organization.id,
              orElse: () => widget.organization,
            );
            final updatedTime = updatedOrganization.last1cUpdate != null
                ? DateFormat('dd.MM.yyyy HH:mm')
                    .format(DateTime.parse(updatedOrganization.last1cUpdate!))
                : null;

            // Обновление значения в ValueNotifier
            lastUpdatedNotifier.value = updatedTime;
          });
          _controller.stop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                localizations.translate('data_updated_successfully'),
                style: context.appTextStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.appColors.textInverse,
                ),
              ),
              backgroundColor: context.appColors.success,
            ),
          );
        } else if (state is Data1CError) {
          setState(() {
            isLoading = false;
          });
          _controller.stop();

          // Обновление времени при ошибке
          final errorTime =
              DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now());
          lastUpdatedNotifier.value = errorTime;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                localizations.translate('data_updated_successfully'),
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
              backgroundColor: context.appColors.success,
              elevation: 3,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: GestureDetector(
        onTap: organization.is1cIntegration
            ? () {
                context.read<Data1CBloc>().add(FetchData1C());
              }
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (organization.is1cIntegration)
              _buildProfileOption(
                context: context,
                iconPath: 'assets/icons/1c/5.png',
                text: localizations.translate('update_1c_data'),
              ),
            ValueListenableBuilder<String?>(
              valueListenable: lastUpdatedNotifier,
              builder: (context, lastUpdated, child) {
                if (organization.is1cIntegration && lastUpdated != null) {
                  final bottomLum =
                      WallpaperAdaptiveScope.of(context).bottomLuminance;
                  return Center(
                    child: Text(
                      '${localizations.translate('last_update_1c')}: $lastUpdated',
                      style: context.appTextStyles.bodySm.copyWith(
                        fontWeight: FontWeight.w400,
                        color: context.wallpaperSecondary(luminance: bottomLum),
                        shadows: context.wallpaperShadows(luminance: bottomLum),
                      ),
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required BuildContext context,
    required String iconPath,
    required String text,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.surfacePrimary.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.appColors.borderSubtle.withValues(alpha: 0.42),
        ),
        boxShadow: context.appShadows.card,
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: context.appColors.surfaceAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: isLoading
                ? RotationTransition(
                    turns:
                        Tween<double>(begin: 0, end: -1).animate(_controller),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.asset(
                        iconPath,
                        width: 50,
                        height: 50,
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: Image.asset(
                      iconPath,
                      width: 40,
                      height: 40,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: context.appTextStyles.bodyMd.copyWith(
                fontWeight: FontWeight.w500,
                color: context.appColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
