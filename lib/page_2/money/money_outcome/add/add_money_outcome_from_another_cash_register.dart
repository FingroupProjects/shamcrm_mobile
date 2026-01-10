// import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
// import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
// import 'package:crm_task_manager/models/cash_register_list_model.dart';
// import 'package:crm_task_manager/page_2/money/widgets/cash_register_radio_group.dart';
// import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:intl/intl.dart';
// import '../../../../bloc/money_outcome/money_outcome_bloc.dart';
// import '../money_outcome_operation_type.dart';
//
// class AddMoneyOutcomeAnotherCashRegister extends StatefulWidget {
//   const AddMoneyOutcomeAnotherCashRegister({super.key});
//
//   @override
//   _AddMoneyOutcomeAnotherCashRegisterState createState() => _AddMoneyOutcomeAnotherCashRegisterState();
// }
//
// class _AddMoneyOutcomeAnotherCashRegisterState extends State<AddMoneyOutcomeAnotherCashRegister> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _dateController = TextEditingController();
//   final TextEditingController _commentController = TextEditingController();
//   final TextEditingController _amountController = TextEditingController();
//   CashRegisterData? selectedCashRegister;
//   CashRegisterData? selectedSenderCashRegister;
//   bool _isLoading = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _dateController.text = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
//   }
//
//   void _createDocument({bool approve = false}) {
//     if (!_formKey.currentState!.validate()) return;
//
//     if (selectedCashRegister == null) {
//       _showSnackBar(
//         AppLocalizations.of(context)!.translate('select_sender_cash_register') ?? 'Пожалуйста, выберите кассу-отправителя',
//         false,
//       );
//       return;
//     }
//
//     if (selectedSenderCashRegister == null) {
//       _showSnackBar(
//         AppLocalizations.of(context)!.translate('select_cash_register') ?? 'Пожалуйста, выберите кассу',
//         false,
//       );
//       return;
//     }
//
//     setState(() => _isLoading = true);
//
//     String? isoDate;
//
//     try {
//       DateTime? parsedDate = DateFormat('dd/MM/yyyy HH:mm').parse(_dateController.text);
//       isoDate = DateFormat("yyyy-MM-ddTHH:mm:ss.SSS'Z'").format(parsedDate);
//     } catch (e) {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//       _showSnackBar(
//         AppLocalizations.of(context)!.translate('enter_valid_datetime') ?? 'Введите корректную дату и время',
//         false,
//       );
//       return;
//     }
//
//     if (selectedCashRegister!.id  == selectedSenderCashRegister!.id) {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//       _showSnackBar(
//         AppLocalizations.of(context)!.translate('cash_registers_must_be_different') ?? 'Касса-отправитель и касса-получатель должны быть разными',
//         false,
//       );
//       return;
//     }
//
//
//     final bloc = context.read<MoneyOutcomeBloc>();
//     bloc.add(CreateMoneyOutcome(
//       date: isoDate,
//       amount: double.parse(_amountController.text.trim()),
//       cashRegisterId: selectedCashRegister!.id,
//       senderCashRegisterId: selectedSenderCashRegister?.id,
//       comment: _commentController.text.trim(),
//       operationType: MoneyOutcomeOperationType.send_another_cash_register.name,
//       approve: approve,
//     ));
//   }
//
//   void _showSnackBar(String message, bool isSuccess) {
//     if (!mounted) return;
//
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!mounted) return;
//
//       final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
//       if (scaffoldMessenger == null) return;
//
//       scaffoldMessenger.showSnackBar(
//         SnackBar(
//           content: Text(
//             message,
//             style: const TextStyle(
//               fontFamily: 'Gilroy',
//               fontSize: 16,
//               fontWeight: FontWeight.w500,
//               color: Colors.white,
//             ),
//           ),
//           backgroundColor: isSuccess ? Colors.green : Colors.red,
//           behavior: SnackBarBehavior.floating,
//           margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           duration: const Duration(seconds: 3),
//         ),
//       );
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final localizations = AppLocalizations.of(context)!;
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: _buildAppBar(localizations),
//       body: MultiBlocListener(
//         listeners: [
//           BlocListener<MoneyOutcomeBloc, MoneyOutcomeState>(
//             listener: (context, state) {
//               WidgetsBinding.instance.addPostFrameCallback((_) {
//                 if (!mounted) return;
//
//                 if (state is MoneyOutcomeCreateSuccess) {
//                   setState(() => _isLoading = false);
//                   Navigator.pop(context, true);
//                 } else if (state is MoneyOutcomeCreateError) {
//                   setState(() => _isLoading = false);
//                   _showSnackBar(state.message, false);
//                 }
//               });
//             },
//           ),
//         ],
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               Expanded(
//                 child: SingleChildScrollView(
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const SizedBox(height: 8),
//                       CashRegisterGroupWidget(
//                         title: AppLocalizations.of(context)!.translate('sender_cash_register') ?? 'Касса-отправитель',
//                         selectedCashRegisterId: selectedSenderCashRegister?.id.toString(),
//                         onSelectCashRegister: (CashRegisterData selectedRegionData) {
//                           try {
//                             setState(() {
//                               selectedSenderCashRegister = selectedRegionData;
//                             });
//                           } catch (e) {
//                             debugPrint('Error selecting sender cash register: $e');
//                             _showSnackBar(
//                                 AppLocalizations.of(context)!.translate('error_selecting_cash_register') ?? 'Ошибка выбора кассы',
//                                 false);
//                           }
//                         },
//                       ),
//                       const SizedBox(height: 16),
//                       _buildDateField(localizations),
//                       const SizedBox(height: 16),
//                       CashRegisterGroupWidget(
//                         title: AppLocalizations.of(context)!.translate('receiver_cash_register') ?? 'Касса-получатель',
//                         selectedCashRegisterId: selectedCashRegister?.id.toString(),
//                         onSelectCashRegister: (CashRegisterData selectedRegionData) {
//                           try {
//                             setState(() {
//                               selectedCashRegister = selectedRegionData;
//                             });
//                           } catch (e) {
//                             debugPrint('Error selecting receiver cash register: $e');
//                             _showSnackBar(
//                                 AppLocalizations.of(context)!.translate('error_selecting_cash_register') ?? 'Ошибка выбора кассы',
//                                 false);
//                           }
//                         },
//                       ),
//                       const SizedBox(height: 16),
//                       _buildAmountField(localizations),
//                       const SizedBox(height: 16),
//                       _buildCommentField(localizations),
//                       const SizedBox(height: 16),
//                     ],
//                   ),
//                 ),
//               ),
//               _buildActionButtons(localizations),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   AppBar _buildAppBar(AppLocalizations localizations) {
//     return AppBar(
//       backgroundColor: Colors.white,
//       forceMaterialTransparency: true,
//       elevation: 0,
//       leading: IconButton(
//         icon: const Icon(Icons.arrow_back_ios, color: Color(0xff1E2E52), size: 24),
//         onPressed: () => Navigator.pop(context),
//       ),
//       title: Text(
//         AppLocalizations.of(context)!.translate('create_outcoming_document') ?? 'Создать расход',
//         style: const TextStyle(
//           fontSize: 20,
//           fontFamily: 'Gilroy',
//           fontWeight: FontWeight.w600,
//           color: Color(0xff1E2E52),
//         ),
//       ),
//       centerTitle: true,
//     );
//   }
//
//   Widget _buildDateField(AppLocalizations localizations) {
//     return CustomTextFieldDate(
//       controller: _dateController,
//       label: AppLocalizations.of(context)!.translate('date') ?? 'Дата',
//       withTime: true,
//       onDateSelected: (date) {
//         if (mounted) {
//           setState(() {
//             _dateController.text = date;
//           });
//         }
//       },
//     );
//   }
//
//   Widget _buildCommentField(AppLocalizations localizations) {
//     return CustomTextField(
//       controller: _commentController,
//       label: AppLocalizations.of(context)!.translate('comment') ?? 'Комментарий',
//       hintText: AppLocalizations.of(context)!.translate('enter_comment') ?? 'Введите комментарий',
//       maxLines: 3,
//       keyboardType: TextInputType.multiline,
//     );
//   }
//
//   Widget _buildAmountField(AppLocalizations localizations) {
//     return CustomTextField(
//         controller: _amountController,
//         label: AppLocalizations.of(context)!.translate('amount') ?? 'Сумма',
//         hintText: AppLocalizations.of(context)!.translate('enter_amount') ?? 'Введите сумму',
//         maxLines: 1,
//         keyboardType: TextInputType.number,
//         validator: (value) {
//           if (value == null || value.isEmpty) {
//             return AppLocalizations.of(context)!.translate('enter_amount') ?? 'Введите сумму';
//           }
//
//           final doubleValue = double.tryParse(value.trim());
//           if (doubleValue == null) {
//             return AppLocalizations.of(context)!.translate('enter_valid_amount') ?? 'Введите корректную сумму';
//           }
//
//           if (doubleValue <= 0) {
//             return AppLocalizations.of(context)!.translate('amount_must_be_greater_than_zero') ?? 'Сумма должна быть больше нуля';
//           }
//
//           return null;
//         }
//     );
//   }
//
//
//   // Новый метод для сохранения и проведения
//   void _createAndApproveDocument() {
//     _createDocument(approve: true);
//   }
//
//   // Обновленный метод для обычного сохранения
//   void _saveDocument() {
//     _createDocument(approve: false);
//   }
//
//   // Обновленный виджет кнопок действий (+ "Сохранить и провести")
//   Widget _buildActionButtons(AppLocalizations localizations) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 3,
//             offset: const Offset(0, -1),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Container(
//             width: double.infinity,
//             height: 48,
//             decoration: BoxDecoration(
//               border: Border.all(color: const Color(0xff4CAF50), width: 1.5),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Material(
//               color: Colors.transparent,
//               child: InkWell(
//                 borderRadius: BorderRadius.circular(12),
//                 onTap: _isLoading ? null : _createAndApproveDocument,
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 16),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(
//                         Icons.check_circle_outline,
//                         size: 20,
//                         color: _isLoading ? const Color(0xff99A4BA) : const Color(0xff4CAF50),
//                       ),
//                       const SizedBox(width: 8),
//                       Text(
//                         localizations.translate('save_and_approve') ?? 'Сохранить и провести',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontFamily: 'Gilroy',
//                           fontWeight: FontWeight.w600,
//                           color: _isLoading ? const Color(0xff99A4BA) : const Color(0xff4CAF50),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           SizedBox(height: 16),
//           Row(
//             children: [
//               Expanded(
//                 child: ElevatedButton(
//                   onPressed: _isLoading ? null : () => Navigator.pop(context),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xffF4F7FD),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     padding: const EdgeInsets.symmetric(vertical: 12),
//                     elevation: 0,
//                   ),
//                   child: Text(
//                     localizations.translate('close') ?? 'Отмена',
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontFamily: 'Gilroy',
//                       fontWeight: FontWeight.w500,
//                       color: Colors.black,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: ElevatedButton(
//                   onPressed: _isLoading ? null : _saveDocument,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xff4759FF),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     padding: const EdgeInsets.symmetric(vertical: 12),
//                     elevation: 0,
//                   ),
//                   child: _isLoading
//                       ? const SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                     ),
//                   )
//                       : Text(
//                     localizations.translate('save') ?? 'Сохранить',
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontFamily: 'Gilroy',
//                       fontWeight: FontWeight.w500,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _dateController.dispose();
//     _amountController.dispose();
//     _commentController.dispose();
//     super.dispose();
//   }
// }