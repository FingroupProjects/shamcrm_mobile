// import 'package:animated_custom_dropdown/custom_dropdown.dart';
// import 'package:crm_task_manager/bloc/my-task/my-task_bloc.dart';
// import 'package:crm_task_manager/bloc/my-task/my-task_event.dart';
// import 'package:crm_task_manager/bloc/my-task/my-task_state.dart';
// import 'package:crm_task_manager/models/my-task_model.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// class MyTaskStatusRadioGroupWidget extends StatefulWidget {
//   final String? selectedStatus;
//   final Function(MyTaskStatus) onSelectStatus;

//   MyTaskStatusRadioGroupWidget({
//     Key? key,
//     required this.onSelectStatus,
//     this.selectedStatus,
//   }) : super(key: key);

//   @override
//   State<MyTaskStatusRadioGroupWidget> createState() =>
//       _MyTaskStatusRadioGroupWidgetState();
// }

// class _MyTaskStatusRadioGroupWidgetState
//     extends State<MyTaskStatusRadioGroupWidget> {
//   List<MyTaskStatus> statusList = [];
//   MyTaskStatus? selectedStatusData;

//   final TextStyle statusTextStyle = const TextStyle(
//     fontSize: 16,
//     fontWeight: FontWeight.w500,
//     fontFamily: 'Gilroy',
//     color: Color(0xff1E2E52),
//   );

//   @override
//   void initState() {
//     super.initState();
//     context.read<MyTaskBloc>().add(FetchMyTaskStatuses());
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         BlocBuilder<MyTaskBloc, MyTaskState>(
//           builder: (context, state) {
//             if (state is MyTaskLoading) {
//               return const Center(child: CircularProgressIndicator());
//             }
//             if (state is MyTaskError) {
//               WidgetsBinding.instance.addPostFrameCallback((_) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text(
//                       state.message,
//                       style: statusTextStyle.copyWith(color: Colors.white),
//                     ),
//                     behavior: SnackBarBehavior.floating,
//                     margin: const EdgeInsets.symmetric(
//                         horizontal: 16, vertical: 8),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     backgroundColor: Colors.red,
//                     elevation: 3,
//                     padding: const EdgeInsets.symmetric(
//                         vertical: 12, horizontal: 16),
//                     duration: const Duration(seconds: 3),
//                   ),
//                 );
//               });
//             }

//             if (state is MyTaskLoaded) {
//               statusList = state.taskStatuses;

//               if (statusList.length == 1 && selectedStatusData == null) {
//                 WidgetsBinding.instance.addPostFrameCallback((_) {
//                   widget.onSelectStatus(statusList[0]);
//                   setState(() {
//                     selectedStatusData = statusList[0];
//                   });
//                 });
//               } else if (widget.selectedStatus != null &&
//                   statusList.isNotEmpty) {
//                 try {
//                   selectedStatusData = statusList.firstWhere(
//                     (status) => status.id.toString() == widget.selectedStatus,
//                   );
//                 } catch (e) {
//                   selectedStatusData = null;
//                 }
//               }

//               return Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Статусы задачи',
//                     style: statusTextStyle.copyWith(fontWeight: FontWeight.w400),
//                   ),
//                   const SizedBox(height: 4),
//                   Container(
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFF4F7FD),
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(
//                         width: 1,
//                         color: const Color(0xFFF4F7FD),
//                       ),
//                     ),
//                     child: CustomDropdown<MyTaskStatus>.search(
//                       closeDropDownOnClearFilterSearch: true,
//                       items: statusList,
//                       searchHintText: 'Поиск',
//                       overlayHeight: 400,
//                       decoration: CustomDropdownDecoration(
//                         closedFillColor: const Color(0xffF4F7FD),
//                         expandedFillColor: Colors.white,
//                         closedBorder: Border.all(
//                           color: const Color(0xffF4F7FD),
//                           width: 1,
//                         ),
//                         closedBorderRadius: BorderRadius.circular(12),
//                         expandedBorder: Border.all(
//                           color: const Color(0xffF4F7FD),
//                           width: 1,
//                         ),
//                         expandedBorderRadius: BorderRadius.circular(12),
//                       ),
//                       listItemBuilder:
//                           (context, item, isSelected, onItemSelect) {
//                         return Text(
//                           item.title ?? "",
//                           style: statusTextStyle,
//                         );
//                       },
//                       headerBuilder: (context, selectedItem, enabled) {
//                         return Text(
//                           selectedItem?.title ?? 'Выберите статус',
//                           style: statusTextStyle,
//                         );
//                       },
//                       hintBuilder: (context, hint, enabled) => Text(
//                         'Выберите статус',
//                         style: statusTextStyle.copyWith(fontSize: 14),
//                       ),
//                       excludeSelected: false,
//                       initialItem: selectedStatusData,
//                       validator: (value) {
//                         if (value == null) {
//                           return 'Поле обязательно для заполнения';
//                         }
//                         return null;
//                       },
//                       onChanged: (value) {
//                         if (value != null) {
//                           widget.onSelectStatus(value);
//                           setState(() {
//                             selectedStatusData = value;
//                           });
//                           FocusScope.of(context).unfocus();
//                         }
//                       },
//                     ),
//                   ),
//                 ],
//               );
//             }
//             return const SizedBox();
//           },
//         ),
//       ],
//     );
//   }
// }
