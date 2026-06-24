import 'package:crm_task_manager/bloc/page_2_BLOC/document/storage/bloc/storage_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/storage/bloc/storage_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/storage/bloc/storage_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/models/page_2/storage_model.dart';
import 'package:crm_task_manager/page_2/warehouse/ware_house/warehouse_multiuser_select.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddWarehouseScreen extends StatefulWidget {
  const AddWarehouseScreen({Key? key}) : super(key: key);

  @override
  _AddWarehouseScreenState createState() => _AddWarehouseScreenState();
}

class _AddWarehouseScreenState extends State<AddWarehouseScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();

  bool _isWarehouseVisible = true;
  List<int> ids = [];

  Future<void> _toggleWarehouseVisibility(bool value) async {
    setState(() {
      _isWarehouseVisible = value;
    });
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    final colors = context.appColors;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colors.textInverse,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: colors.error,
          elevation: 3,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: colors.surfacePrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colors.iconPrimary, size: 24),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          AppLocalizations.of(context)!.translate('add_warehouse') ??
              'Добавить склад',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: BlocListener<WareHouseBloc, WareHouseState>(
        listener: (context, state) {
          if (state is WareHouseError) {
            _showErrorSnackBar(
                context,
                AppLocalizations.of(context)!.translate(state.message) ??
                    state.message);
          }
          if (state is WareHouseSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!
                          .translate('warehouse_created_successfully') ??
                      'Склад успешно создан',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colors.textInverse,
                  ),
                ),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: colors.success,
                elevation: 3,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                duration: const Duration(seconds: 3),
              ),
            );
            Navigator.pop(context);
          }
        },
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      FocusScope.of(context).unfocus();
                    },
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomTextField(
                            controller: nameController,
                            hintText: AppLocalizations.of(context)!
                                    .translate('enter_warehouse_name') ??
                                'Введите название склада',
                            label: AppLocalizations.of(context)!
                                    .translate('title_without_dots') ??
                                'Название',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLocalizations.of(context)!
                                        .translate('field_required') ??
                                    'Поле обязательно';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          WarehouseMultiUser(
                            selectedUsers: const [],
                            onSelectUsers: (selectedUsers) {
                              setState(() {
                                ids = selectedUsers.map((e) => e.id).toList();
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)!
                                    .translate('warehouse_visibility') ??
                                'Показывать склад в интернет магазине  как филиал',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Gilroy',
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: colors.backgroundSecondary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Transform.scale(
                                  scale: 0.9,
                                  child: Switch(
                                    value: _isWarehouseVisible,
                                    onChanged: _toggleWarehouseVisibility,
                                    activeThumbColor: colors.buttonPrimaryFg,
                                    inactiveThumbColor: colors.textInverse,
                                    activeTrackColor: colors.buttonPrimaryBg,
                                    inactiveTrackColor: colors.borderSubtle
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _isWarehouseVisible
                                        ? AppLocalizations.of(context)!
                                                .translate(
                                                    'warehouse_visible_on') ??
                                            'Показывать склад: Вкл'
                                        : AppLocalizations.of(context)!
                                                .translate(
                                                    'warehouse_visible_off') ??
                                            'Показывать склад: Выкл',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Gilroy',
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          buttonText: AppLocalizations.of(context)!
                                  .translate('close') ??
                              'Отмена',
                          buttonColor: colors.backgroundSecondary,
                          textColor: colors.textPrimary,
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: BlocBuilder<WareHouseBloc, WareHouseState>(
                          builder: (context, state) {
                            if (state is WareHouseLoading) {
                              return Center(
                                child: CircularProgressIndicator(
                                  color: colors.buttonPrimaryBg,
                                ),
                              );
                            }
                            return CustomButton(
                              buttonText: AppLocalizations.of(context)!
                                      .translate('save') ??
                                  'Сохранить',
                              buttonColor: colors.buttonPrimaryBg,
                              textColor: colors.textInverse,
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  final warehouse = WareHouse(
                                    id: 0,
                                    name: nameController.text,
                                    showOnSite: _isWarehouseVisible,
                                    createdAt: DateTime.now().toIso8601String(),
                                    updatedAt: DateTime.now().toIso8601String(),
                                  );
                                  context
                                      .read<WareHouseBloc>()
                                      .add(CreateWareHouse(warehouse, ids));
                                }
                              },
                            );
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
      ),
    );
  }
}
