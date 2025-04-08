// import 'package:crm_task_manager/custom_widget/custom_button.dart';
// import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
// import 'package:flutter/material.dart';

// class DeleteGoodsDialog extends StatelessWidget {
//   final int goodId;
//   final VoidCallback onDelete;

//   const DeleteGoodsDialog({
//     required this.goodId,
//     required this.onDelete,
//     super.key,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       backgroundColor: Colors.white,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Text(
//               AppLocalizations.of(context)!.translate('delete_goods'),
//               style: const TextStyle(
//                 color: Color(0xff1E2E52),
//                 fontSize: 18,
//                 fontFamily: 'Gilroy',
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Text(
//               AppLocalizations.of(context)!.translate('confirm_delete_goods'),
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                 color: Color(0xff1E2E52),
//                 fontSize: 16,
//                 fontFamily: 'Gilroy',
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: CustomButton(
//                     buttonText: AppLocalizations.of(context)!.translate('cancel'),
//                     buttonColor: const Color(0xffF4F7FD),
//                     textColor: Colors.black,
//                     onPressed: () => Navigator.pop(context),
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: CustomButton(
//                     buttonText: AppLocalizations.of(context)!.translate('delete'),
//                     buttonColor: const Color(0xffFF4D4F),
//                     textColor: Colors.white,
//                     onPressed: () {
//                       onDelete();
//                       Navigator.pop(context);
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }