// import 'package:crm_task_manager/api/service/api_service.dart';
// import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_bloc.dart';
// import 'package:crm_task_manager/page_2/warehouse/incoming/good_list_wiget.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:crm_task_manager/models/page_2/goods_model.dart';
// import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

// // Пример 1: Простое отображение списка товаров
// class GoodsListScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           AppLocalizations.of(context)!.translate('goods_list'),
//           style: TextStyle(
//             fontFamily: 'Gilroy',
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         backgroundColor: Colors.white,
//         foregroundColor: Color(0xff1E2E52),
//         elevation: 0,
//       ),
//       body: BlocProvider(
//         create: (context) => GoodsBloc(context.read<ApiService>()),
//         child: GoodsListWidget(),
//       ),
//     );
//   }
// }

// // Пример 2: Использование с выбором товара (как в модальном окне или для выбора)
// class GoodsSelectionDialog extends StatelessWidget {
//   final Function(Goods) onGoodsSelected;

//   const GoodsSelectionDialog({
//     Key? key,
//     required this.onGoodsSelected,
//   }) : super(key: key);

//   static Future<Goods?> show(BuildContext context) {
//     return showDialog<Goods>(
//       context: context,
//       builder: (BuildContext context) => Dialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: Container(
//           width: MediaQuery.of(context).size.width * 0.9,
//           height: MediaQuery.of(context).size.height * 0.8,
//           child: BlocProvider(
//             create: (context) => GoodsBloc(context.read<ApiService>()),
//             child: GoodsSelectionDialog(
//               onGoodsSelected: (goods) {
//                 Navigator.of(context).pop(goods);
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         // Заголовок диалога
//         Container(
//           padding: EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Color(0xff1E2E52),
//             borderRadius: BorderRadius.only(
//               topLeft: Radius.circular(16),
//               topRight: Radius.circular(16),
//             ),
//           ),
//           child: Row(
//             children: [
//               Text(
//                 AppLocalizations.of(context)!.translate('select_goods'),
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600,
//                   fontFamily: 'Gilroy',
//                   color: Colors.white,
//                 ),
//               ),
//               Spacer(),
//               IconButton(
//                 onPressed: () => Navigator.of(context).pop(),
//                 icon: Icon(Icons.close, color: Colors.white),
//               ),
//             ],
//           ),
//         ),
        
//         // Список товаров
//         Expanded(
//           child: GoodsListWidget(
//             enableSelection: true,
//             onGoodsSelected: onGoodsSelected,
//             padding: EdgeInsets.all(16),
//             searchHint: AppLocalizations.of(context)!.translate('search_and_select_goods'),
//           ),
//         ),
//       ],
//     );
//   }
// }

// // Пример 3: Использование в качестве части другого экрана
// class WarehouseScreen extends StatefulWidget {
//   @override
//   _WarehouseScreenState createState() => _WarehouseScreenState();
// }

// class _WarehouseScreenState extends State<WarehouseScreen> {
//   Goods? selectedGoods;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           AppLocalizations.of(context)!.translate('warehouse'),
//           style: TextStyle(
//             fontFamily: 'Gilroy',
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         backgroundColor: Colors.white,
//         foregroundColor: Color(0xff1E2E52),
//         elevation: 0,
//         actions: [
//           IconButton(
//             onPressed: () async {
//               final goods = await GoodsSelectionDialog.show(context);
//               if (goods != null) {
//                 setState(() {
//                   selectedGoods = goods;
//                 });
//               }
//             },
//             icon: Icon(Icons.add),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Показываем выбранный товар, если есть
//           if (selectedGoods != null) ...[
//             Container(
//               margin: EdgeInsets.all(16),
//               padding: EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Color(0xff1E2E52).withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Row(
//                 children: [
//                   Icon(
//                     Icons.check_circle,
//                     color: Colors.green,
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           AppLocalizations.of(context)!.translate('selected_goods'),
//                           style: TextStyle(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w400,
//                             fontFamily: 'Gilroy',
//                             color: Color(0xff1E2E52).withOpacity(0.7),
//                           ),
//                         ),
//                         Text(
//                           selectedGoods!.name,
//                           style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w600,
//                             fontFamily: 'Gilroy',
//                             color: Color(0xff1E2E52),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   IconButton(
//                     onPressed: () {
//                       setState(() {
//                         selectedGoods = null;
//                       });
//                     },
//                     icon: Icon(Icons.close),
//                   ),
//                 ],
//               ),
//             ),
//           ],
          
//           // Основной список товаров
//           Expanded(
//             child: BlocProvider(
//               create: (context) => GoodsBloc(context.read<ApiService>()),
//               child: GoodsListWidget(
//                 enableSelection: true,
//                 onGoodsSelected: (goods) {
//                   setState(() {
//                     selectedGoods = goods;
//                   });
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }