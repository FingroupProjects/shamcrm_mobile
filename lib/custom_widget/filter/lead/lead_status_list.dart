// import 'package:animated_custom_dropdown/custom_dropdown.dart';
// import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
// import 'package:crm_task_manager/bloc/lead/lead_event.dart';
// import 'package:crm_task_manager/bloc/lead/lead_state.dart';
// import 'package:crm_task_manager/models/lead_model.dart';
// import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
//
// class LeadStatusRadioGroupWidget extends StatefulWidget {
//   final String? selectedStatus;
//   final Function(LeadStatus) onSelectStatus;
//
//   LeadStatusRadioGroupWidget({
//     Key? key,
//     required this.onSelectStatus,
//     this.selectedStatus,
//   }) : super(key: key);
//
//   @override
//   State<LeadStatusRadioGroupWidget> createState() =>
//       _LeadStatusRadioGroupWidgetState();
// }
//
// class _LeadStatusRadioGroupWidgetState
//     extends State<LeadStatusRadioGroupWidget> {
//   List<LeadStatus> statusList = [];
//   LeadStatus? selectedStatusData;
//
//   final TextStyle statusTextStyle = const TextStyle(
//     fontSize: 16,
//     fontWeight: FontWeight.w500,
//     fontFamily: 'Gilroy',
//     color: Color(0xff1E2E52),
//   );
//
//   @override
//   void initState() {
//     super.initState();
//     context.read<LeadBloc>().add(FetchLeadStatuses()); // Без изменений: Инициализация загрузки статусов
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return FormField<LeadStatus>( // Изменено: Обёрнуто в FormField для валидации
//       validator: (value) {
//         if (selectedStatusData == null) {
//           return AppLocalizations.of(context)!.translate('field_required_project');
//         }
//         return null;
//       },
//       builder: (FormFieldState<LeadStatus> field) {
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               AppLocalizations.of(context)!.translate('lead_statuses'),
//               style: statusTextStyle.copyWith(
//                 fontWeight: FontWeight.w400,
//                 fontSize: 16,
//               ), // Изменено: Унифицирован стиль заголовка
//             ),
//             const SizedBox(height: 8), // Изменено: Увеличен отступ до 8
//             Container(
//               decoration: BoxDecoration( // Добавлено: Стилизация бордера с учетом ошибок
//                 color: const Color(0xFFF4F7FD),
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(
//                   width: 1,
//                   color: field.hasError ? Colors.red : const Color(0xFFE5E7EB),
//                 ),
//               ),
//               child: BlocBuilder<LeadBloc, LeadState>(
//                 builder: (context, state) {
//                   if (state is LeadLoaded) {
//                     statusList = state.leadStatuses;
//                     if (statusList.length == 1 && selectedStatusData == null) {
//                       WidgetsBinding.instance.addPostFrameCallback((_) {
//                         widget.onSelectStatus(statusList[0]);
//                         setState(() {
//                           selectedStatusData = statusList[0];
//                         });
//                         field.didChange(statusList[0]); // Добавлено: Обновление состояния FormField
//                       });
//                     } else if (widget.selectedStatus != null && statusList.isNotEmpty) {
//                       try {
//                         selectedStatusData = statusList.firstWhere(
//                           (status) => status.id.toString() == widget.selectedStatus,
//                         );
//                       } catch (e) {
//                         selectedStatusData = null;
//                       }
//                     }
//                   }
//
//                   return CustomDropdown<LeadStatus>.search(
//                     closeDropDownOnClearFilterSearch: true,
//                     items: statusList,
//                     searchHintText: AppLocalizations.of(context)!.translate('search'),
//                     overlayHeight: 400,
//                     decoration: CustomDropdownDecoration( // Изменено: Унифицированы стили декорации
//                       closedFillColor: const Color(0xffF4F7FD),
//                       expandedFillColor: Colors.white,
//                       closedBorder: Border.all(
//                         color: Colors.transparent,
//                         width: 1,
//                       ),
//                       closedBorderRadius: BorderRadius.circular(12),
//                       expandedBorder: Border.all(
//                         color: const Color(0xFFE5E7EB),
//                         width: 1,
//                       ),
//                       expandedBorderRadius: BorderRadius.circular(12),
//                     ),
//                     listItemBuilder: (context, item, isSelected, onItemSelect) {
//                       return Padding( // Изменено: Заменено на GestureDetector для соответствия AuthorMultiSelectWidget
//                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                         child: GestureDetector(
//                           onTap: onItemSelect,
//                           child: Row(
//                             children: [
//                               Container(
//                                 width: 18,
//                                 height: 18,
//                                 decoration: BoxDecoration(
//                                   border: Border.all(
//                                     color: const Color(0xff1E2E52),
//                                     width: 1,
//                                   ),
//                                   borderRadius: BorderRadius.circular(4),
//                                   color: isSelected ? const Color(0xff1E2E52) : Colors.transparent,
//                                 ),
//                                 child: isSelected
//                                     ? const Icon(
//                                         Icons.check,
//                                         color: Colors.white,
//                                         size: 14,
//                                       )
//                                     : null,
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: Text(
//                                   item.title,
//                                   style: statusTextStyle,
//                                   maxLines: 1,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                     headerBuilder: (context, selectedItem, enabled) {
//                       return Text(
//                         selectedItem?.title ?? AppLocalizations.of(context)!.translate('select_status'),
//                         style: statusTextStyle,
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       );
//                     },
//                     hintBuilder: (context, hint, enabled) => Text(
//                       AppLocalizations.of(context)!.translate('select_status'),
//                       style: statusTextStyle.copyWith(fontSize: 14),
//                     ),
//                     excludeSelected: false,
//                     initialItem: statusList.contains(selectedStatusData) ? selectedStatusData : null,
//                     onChanged: (value) {
//                       if (value != null) {
//                         widget.onSelectStatus(value);
//                         setState(() {
//                           selectedStatusData = value;
//                         });
//                         field.didChange(value); // Добавлено: Обновление состояния FormField
//                         FocusScope.of(context).unfocus();
//                       }
//                     },
//                   );
//                 },
//               ),
//             ),
//             if (field.hasError) // Добавлено: Отображение текста ошибки
//               Padding(
//                 padding: const EdgeInsets.only(top: 4, left: 0),
//                 child: Text(
//                   field.errorText!,
//                   style: const TextStyle(
//                     color: Colors.red,
//                     fontSize: 14,
//                     fontWeight: FontWeight.w400,
//                   ),
//                 ),
//               ),
//           ],
//         );
//       },
//     );
//   }
// }