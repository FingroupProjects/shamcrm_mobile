import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_event.dart';
import 'package:crm_task_manager/bloc/task/task_state.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_details/role_list.dart';
import 'package:crm_task_manager/screens/task/task_details/task_status_list.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

class TaskStatusEditScreen extends StatefulWidget {
  final int taskStatusId;

  const TaskStatusEditScreen({
    Key? key,
    required this.taskStatusId,
  }) : super(key: key);

  @override
  _TaskStatusEditScreenState createState() => _TaskStatusEditScreenState();
}

class _TaskStatusEditScreenState extends State<TaskStatusEditScreen> {
  late TextEditingController _titleController;
  bool needsPermission = false;
  bool finalStep = false;
  bool checkingStep = false;
  bool isUnassembled = false;
  late TaskBloc _taskBloc;
  bool _dataLoaded = false;
  List<int> selectedRoleIds = [];
  int? selectedStatusNameId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _taskBloc = TaskBloc(ApiService());
    _loadTaskStatus();
  }

  void _loadTaskStatus() {
    _taskBloc.add(FetchTaskStatus(widget.taskStatusId));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _taskBloc.close();
    super.dispose();
  }

  void _saveChanges() {
    final taskBloc = BlocProvider.of<TaskBloc>(context);
    taskBloc.add(FetchTaskStatuses());
    final localizations = AppLocalizations.of(context);
    if (localizations != null) {
      _taskBloc.add(
        UpdateTaskStatusEdit(
          taskStatusId: widget.taskStatusId,
          name: _titleController.text,
          needsPermission: needsPermission,
          finalStep: finalStep,
          checkingStep: checkingStep,
          isUnassembled: isUnassembled,
          roleIds: selectedRoleIds,
          localizations: localizations,
        ),
      );
    }
  }

  static Future<void> show(BuildContext context, int taskStatusId) {
    return showDialog(
      context: context,
      builder: (context) => TaskStatusEditScreen(
        taskStatusId: taskStatusId,
      ),
    ).then((_) {
      final taskBloc = BlocProvider.of<TaskBloc>(context, listen: false);
      taskBloc.add(FetchTaskStatuses());
      taskBloc.add(FetchTasks(taskStatusId));
    });
  }

  Widget _buildCheckbox(
    BuildContext context,
    String label,
    bool value,
    Function(bool?) onChanged,
  ) {
    final colors = context.appColors;
    return Row(
      children: [
        Transform.scale(
          scale: 0.9,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: colors.buttonPrimaryBg,
            checkColor: colors.buttonPrimaryFg,
            side: BorderSide(color: colors.borderSubtle),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        Text(label, style: _textStyle().copyWith(color: colors.textPrimary)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TaskBloc, TaskState>(
      bloc: _taskBloc,
      listener: (context, state) {
        final colors = context.appColors;
        if (state is TaskStatusLoaded && !_dataLoaded) {
          setState(() {
            _titleController.text = state.taskStatus.taskStatus!.name;
            needsPermission = state.taskStatus.needsPermission;
            finalStep = state.taskStatus.finalStep;
            checkingStep = state.taskStatus.checkingStep;
            isUnassembled = state.taskStatus.isUnassembled;
            selectedRoleIds =
                (state.taskStatus.roles ?? []).map((e) => e as int).toList();
            _dataLoaded = true;
          });
        } else if (state is TaskStatusUpdatedEdit) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate(state.message),
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colors.textInverse,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: colors.success,
              elevation: 3,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              duration: Duration(seconds: 3),
            ),
          );
          final taskBloc = BlocProvider.of<TaskBloc>(context, listen: false);
          taskBloc.add(FetchTaskStatuses());
          taskBloc.add(FetchTasks(widget.taskStatusId));
          Navigator.of(context).pop();
        } else if (state is TaskError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate(state.message),
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colors.textInverse,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: colors.error,
              elevation: 3,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
      builder: (context, state) {
        return Dialog(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 400,
            height: needsPermission ? 530 : 420,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.appColors.surfacePrimary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: context.appColors.borderSubtle.withValues(alpha: 0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.appColors.shadow.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Изменение статуса',
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w600,
                            color: context.appColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 24,
                            color: context.appColors.textSecondary,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: state is TaskLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                color: context.appColors.buttonPrimaryBg,
                              ),
                            )
                          : SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  StatusList(
                                    selectedTaskStatus:
                                        selectedStatusNameId?.toString(),
                                    onChanged:
                                        (String? statusName, int? statusId) {
                                      setState(() {
                                        selectedStatusNameId = statusId;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  _buildCheckbox(
                                    context,
                                    'С доступом',
                                    needsPermission,
                                    (value) {
                                      if (value != null) {
                                        setState(() {
                                          needsPermission = value;
                                          if (!value) {
                                            selectedRoleIds.clear();
                                          }
                                        });
                                      }
                                    },
                                  ),
                                  _buildCheckbox(
                                    context,
                                    'Завершающий этап',
                                    finalStep,
                                    (value) {
                                      if (value != null) {
                                        setState(() {
                                          finalStep = value;
                                        });
                                      }
                                    },
                                  ),
                                  _buildCheckbox(
                                    context,
                                    'Проверяющий этап',
                                    checkingStep,
                                    (value) {
                                      if (value != null) {
                                        setState(() {
                                          checkingStep = value;
                                        });
                                      }
                                    },
                                  ),
                                  _buildCheckbox(
                                    context,
                                    'Неразобранные',
                                    isUnassembled,
                                    (value) {
                                      if (value != null) {
                                        setState(() {
                                          isUnassembled = value;
                                        });
                                      }
                                    },
                                  ),
                                  if (needsPermission) ...[
                                    const SizedBox(height: 16),
                                    RoleSelectionWidget(
                                      selectedRoleIds: selectedRoleIds,
                                      onRolesChanged: (roleIds) {
                                        setState(() {
                                          selectedRoleIds = roleIds;
                                        });
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                    ),
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: context.appColors.buttonPrimaryBg,
                          boxShadow: [
                            BoxShadow(
                              color: context.appColors.buttonPrimaryBg
                                  .withValues(alpha: 0.22),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: _saveChanges,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 10,
                            ),
                          ),
                          child: Text(
                            'Сохранить',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w500,
                              color: context.appColors.buttonPrimaryFg,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextFieldWithLabel({
    required String label,
    required TextEditingController controller,
    bool isRequired = true,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: controller,
          hintText: hintText ?? '',
          label: label,
          validator: isRequired
              ? (value) => value!.isEmpty ? 'Поле обязательно' : null
              : null,
          keyboardType: keyboardType ?? TextInputType.text,
          inputFormatters: formatters,
        ),
      ],
    );
  }

  TextStyle _textStyle() => TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w500,
        color: context.appColors.textPrimary,
        overflow: TextOverflow.ellipsis,
      );
}
