import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_bloc.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_event.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_state.dart';

import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

class EditMyTaskStatusScreen extends StatefulWidget {
  final int myTaskStatusId;

  const EditMyTaskStatusScreen({
    Key? key,
    required this.myTaskStatusId,
  }) : super(key: key);

  @override
  _EditMyTaskStatusScreenState createState() => _EditMyTaskStatusScreenState();
}

class _EditMyTaskStatusScreenState extends State<EditMyTaskStatusScreen> {
  late TextEditingController _titleController;
  bool _needsPermission = false;
  late MyTaskBloc _myTaskBloc;
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _myTaskBloc = MyTaskBloc(ApiService());
    _loadMyTaskStatus();
  }

  void _loadMyTaskStatus() {
    _myTaskBloc.add(FetchMyTaskStatus(widget.myTaskStatusId));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _myTaskBloc.close();
    super.dispose();
  }

  void _saveChanges() {
    final myTaskBloc = BlocProvider.of<MyTaskBloc>(context);
    myTaskBloc.add(FetchMyTaskStatuses());
    final localizations = AppLocalizations.of(context);
    if (localizations != null) {
      _myTaskBloc.add(
        UpdateMyTaskStatusEdit(
          widget.myTaskStatusId,
          _titleController.text,
          localizations,
        ),
      );
    }
  }

  static Future<void> show(BuildContext context, int myTaskStatusId) {
    return showDialog(
      context: context,
      builder: (context) => EditMyTaskStatusScreen(
        myTaskStatusId: myTaskStatusId,
      ),
    ).then((_) {
      final taskBloc = BlocProvider.of<MyTaskBloc>(context, listen: false);
      taskBloc.add(FetchMyTaskStatuses());
      taskBloc.add(FetchMyTasks(myTaskStatusId));
    });
  }

  Widget _buildCheckbox(String label, bool value, Function(bool?) onChanged) {
    return Row(
      children: [
        Transform.scale(
          scale: 0.9,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xff1E2E52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        Text(label, style: _textStyle()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MyTaskBloc, MyTaskState>(
      bloc: _myTaskBloc,
      listener: (context, state) {
        if (state is MyTaskStatusLoaded && !_dataLoaded) {
          setState(() {
            _titleController.text = state.myTaskStatus.title;
            // _needsPermission = state.myTaskStatus.needsPermission!;
            _dataLoaded = true;
          });
        } else if (state is MyTaskStatusUpdatedEdit) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                          content: Text(
                            "Статус успешно обновлен!",
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          behavior: SnackBarBehavior.floating,
                          margin:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.green,
                          elevation: 3,
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          duration: Duration(seconds: 3),
                        ),
          );
          final taskBloc = BlocProvider.of<MyTaskBloc>(context, listen: false);
          taskBloc.add(FetchMyTaskStatuses());
          taskBloc.add(FetchMyTasks(widget.myTaskStatusId));
          Navigator.of(context).pop();
        } else if (state is MyTaskError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                          content: Text(
                            "Ошибка обновления статуса!",
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          behavior: SnackBarBehavior.floating,
                          margin:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.red,
                          elevation: 3,
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          duration: Duration(seconds: 3),
                        ),
          );
        }
      },
      builder: (context, state) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          insetPadding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 400,
            height: 350,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
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
                          color: Colors.black.withOpacity(0.8),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close,
                            size: 24, color: Colors.grey[600]),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: state is MyTaskLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xff1E2E52)))
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTextFieldWithLabel(
                                  label: 'Название',
                                  controller: _titleController,
                                  isRequired: true,
                                ),
                                const SizedBox(height: 20),
                                _buildCheckbox(
                                  'Завершающий этап',
                                  _needsPermission,
                                  (v) {
                                    if (v != null) {
                                      setState(() {
                                        _needsPermission = v;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                  ),
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xff1E2E52),
                      ),
                      child: TextButton(
                        onPressed: _saveChanges,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                        ),
                        child: const Text(
                          'Сохранить',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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

  TextStyle _textStyle() => const TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w500,
        color: Color.fromARGB(255, 0, 0, 0),
        overflow: TextOverflow.ellipsis,
      );
}
