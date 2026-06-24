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

class EditWarehouseScreen extends StatefulWidget {
  final WareHouse warehouse;
  final List<int> userIds;

  const EditWarehouseScreen({
    Key? key,
    required this.warehouse,
    required this.userIds,
  }) : super(key: key);

  @override
  _EditWarehouseScreenState createState() => _EditWarehouseScreenState();
}

class _EditWarehouseScreenState extends State<EditWarehouseScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();

  bool _isWarehouseVisible = true;

  List<String> users = [];
  List<int> ids = [];

  @override
  void initState() {
    super.initState();
    nameController.text = widget.warehouse.name ?? '';
    _isWarehouseVisible = widget.warehouse.showOnSite ?? true;
    // Initialize selected users for WarehouseMultiUser widget
    users = widget.userIds.map((id) => id.toString()).toList();
    ids = List.from(widget.userIds);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void _toggleWarehouseVisibility(bool value) {
    setState(() {
      _isWarehouseVisible = value;
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.translate('edit_warehouse') ??
              'Редактировать склад',
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
            _showSnack(
                context,
                AppLocalizations.of(context)!.translate(state.message) ??
                    state.message,
                isError: true);
          }
          if (state is WareHouseSuccess) {
            _showSnack(
              context,
              AppLocalizations.of(context)!
                      .translate('warehouse_updated_successfully') ??
                  'Склад успешно обновлен',
              isError: false,
            );
            Navigator.pop(context, true);
          }
        },
        child: SafeArea(
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
                          controller: nameController,
                          hintText: AppLocalizations.of(context)!
                                  .translate('enter_warehouse_name') ??
                              'Введите название склада',
                          label: AppLocalizations.of(context)!
                                  .translate('title_without_dots') ??
                              'Название без точек',
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
                          selectedUsers: users,
                          onSelectUsers: (selectedUsers) {
                            setState(() {
                              // Update with selected user IDs
                              ids = selectedUsers.map((e) => e.id).toList();
                              users = selectedUsers
                                  .map((e) => e.id.toString())
                                  .toList();
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!
                                  .translate('warehouse_visibility') ??
                              'Отображение склада',
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
                                      ? AppLocalizations.of(context)!.translate(
                                              'warehouse_visible_on') ??
                                          'Показывать склад: Вкл'
                                      : AppLocalizations.of(context)!.translate(
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
                          onPressed: () => Navigator.pop(context),
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
                                  'Обновить',
                              buttonColor: colors.buttonPrimaryBg,
                              textColor: colors.textInverse,
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  final updatedWarehouse = WareHouse(
                                    id: widget.warehouse.id,
                                    name: nameController.text,
                                    showOnSite: _isWarehouseVisible,
                                    createdAt: widget.warehouse.createdAt,
                                    updatedAt: DateTime.now().toIso8601String(),
                                  );
                                  // Update warehouse with new data and assigned users
                                  context.read<WareHouseBloc>().add(
                                        UpdateWareHouse(
                                          updatedWarehouse,
                                          ids, // List of user IDs to assign
                                          widget.warehouse.id,
                                        ),
                                      );
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

  void _showSnack(BuildContext context, String message,
      {bool isError = false}) {
    final colors = context.appColors;

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: isError ? colors.error : colors.success,
        elevation: 3,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
