import 'package:crm_task_manager/models/organization_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:crm_task_manager/bloc/data_1c/data_1c_bloc.dart';
import 'package:crm_task_manager/bloc/data_1c/data_1c_event.dart';
import 'package:crm_task_manager/bloc/data_1c/data_1c_state.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/profile_settings_tile.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';

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
            : null);
  }

  @override
  void dispose() {
    _controller.dispose();
    lastUpdatedNotifier.dispose(); // Освобождение ресурсов
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations =
        AppLocalizations.of(context)!; // Получение локализации
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
          showCustomSnackBar(
            context: context,
            message: localizations.translate('data_updated_successfully'),
            isSuccess: true,
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

          showCustomSnackBar(
            context: context,
            message: state.message,
            isSuccess: false,
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
                text: localizations.translate('update_1c_data'),
              ),
            ValueListenableBuilder<String?>(
              valueListenable: lastUpdatedNotifier,
              builder: (context, lastUpdated, child) {
                if (organization.is1cIntegration && lastUpdated != null) {
                  return Center(
                    child: Text(
                      '${localizations.translate('last_update_1c')}: $lastUpdated',
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption({required String text}) {
    return ProfileSettingsTile(
      title: text,
      icon: Icons.sync_alt_rounded,
      trailing: isLoading
          ? RotationTransition(
              turns: Tween<double>(begin: 0, end: -1).animate(_controller),
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : null,
    );
  }
}
