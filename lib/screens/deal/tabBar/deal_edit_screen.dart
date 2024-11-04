import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/deal/deal_state.dart';
import 'package:crm_task_manager/bloc/region/region_bloc.dart';
import 'package:crm_task_manager/bloc/region/region_event.dart';
import 'package:crm_task_manager/screens/deal/tabBar/manager_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';

class DealEditScreen extends StatefulWidget {
  final int dealId;
  final String dealName;
  final String dealStatus;
  final String? manager;
  final String? description;
  final int statusId;

  DealEditScreen({
    required this.dealId,
    required this.dealName,
    required this.dealStatus,
    required this.statusId,
    this.manager,
    this.description,
  });

  @override
  _DealEditScreenState createState() => _DealEditScreenState();
}

class _DealEditScreenState extends State<DealEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String? selectedManager;
  bool isUpdated = false;

  @override
  void initState() {
    super.initState();
    titleController.text = widget.dealName;
    descriptionController.text = widget.description ?? '';
    selectedManager = widget.manager;

    context.read<RegionBloc>().add(FetchRegions());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/arrow-left.png',
            width: 24,
            height: 24,
          ),
          onPressed: () => Navigator.pop(context, null),
        ),
        title: const Text(
          'Редактирование Сделки',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
      ),
      body: BlocListener<DealBloc, DealState>(
        listener: (context, state) {
          if (state is DealError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                duration: const Duration(seconds: 3),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is DealSuccess) {
            isUpdated = true;
            final updatedDeal = {
              'dealName': titleController.text,
              'dealStatus': widget.dealStatus,
              'statusId': widget.statusId,
              'manager': selectedManager,
              'description': descriptionController.text,
            };
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Сделка успешно обновлен'),
                duration: const Duration(seconds: 3),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, updatedDeal);
          }
        },
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        controller: titleController,
                        hintText: 'Введите название',
                        label: 'Название',
                        validator: (value) => value!.isEmpty
                            ? 'Поле обязательно для заполнения'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      ManagerWidget(
                        selectedManager: selectedManager,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedManager = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: descriptionController,
                        hintText: 'Введите описание',
                        label: 'Описание',
                        maxLines: 5,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        buttonText: 'Отмена',
                        buttonColor: const Color(0xffF4F7FD),
                        textColor: Colors.black,
                        onPressed: () => Navigator.pop(context, null),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        buttonText: 'Сохранить',
                        buttonColor: const Color(0xff4759FF),
                        textColor: Colors.white,
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            DateTime? startDate;
                            DateTime? endDtate;
                            // if (birthdayController.text.isNotEmpty) {
                            //   try {
                            //     birthday = DateFormat('dd/MM/yyyy')
                            //         .parse(birthdayController.text);
                            //   } catch (e) {
                            //     ScaffoldMessenger.of(context).showSnackBar(
                            //       SnackBar(
                            //         content: Text('Ошибка: ${e.toString()}'),
                            //       ),
                            //     );
                            //     return;
                            //   }
                            // }

                            // final leadBloc = context.read<DealBloc>();
                            // context.read<DealBloc>().add(FetchDealStatuses());
                            // leadBloc.add(UpdateDeal(
                            //   dealId: widget.dealId,
                            //   name: titleController.text,
                            //   managerId: selectedManager != null
                            //       ? int.parse(selectedManager!)
                            //       : null,
                            //   description: descriptionController.text,
                            //   dealStatusId: widget.statusId,
                            //   organizationId: 1,
                            // ));
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
