// import 'package:crm_task_manager/api/service/api_service.dart';
// import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_bloc.dart';
// import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_by_id/catgeoryById_bloc.dart';
// import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_by_id/catgeoryById_event.dart';
// import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_by_id/catgeoryById_state.dart';
// import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
// import 'package:crm_task_manager/models/page_2/subCategoryById.dart';
// import 'package:crm_task_manager/page_2/category/category_details/subCategory/subCategory_add_screen.dart';
// import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// class UnifiedCategoryScreen extends StatefulWidget {
//   final int categoryId;
//   final String categoryName;
//   final bool isRoot;

//   const UnifiedCategoryScreen({
//     Key? key,
//     required this.categoryId,
//     required this.categoryName,
//     this.isRoot = false,
//   }) : super(key: key);

//   @override
//   _UnifiedCategoryScreenState createState() => _UnifiedCategoryScreenState();
// }

// class _UnifiedCategoryScreenState extends State<UnifiedCategoryScreen> {
//   final ApiService _apiService = ApiService();
//   String? baseUrl;
//   bool isCreateSubCategory = false;

//   @override
//   void initState() {
//     super.initState();
//     context.read<CategoryByIdBloc>().add(FetchCategoryByIdEvent(categoryId: widget.categoryId));
//     _initializeBaseUrl();
//   }

//   Future<void> _initializeBaseUrl() async {
//     try {
//       final enteredDomainMap = await _apiService.getEnteredDomain();
//       String? enteredMainDomain = enteredDomainMap['enteredMainDomain'];
//       String? enteredDomain = enteredDomainMap['enteredDomain'];
//       setState(() {
//         baseUrl = 'https://$enteredDomain-back.$enteredMainDomain/storage';
//       });
//     } catch (error) {
//       setState(() {
//         baseUrl = 'https://shamcrm.com/storage/';
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocListener<CategoryBloc, CategoryState>(
//       listener: (context, state) {
//         if (isCreateSubCategory && state is CategorySuccess) {
//           setState(() {
//             isCreateSubCategory = false;
//           });
//           context.read<CategoryByIdBloc>().add(FetchCategoryByIdEvent(categoryId: widget.categoryId));
//         }
//       },
//       child: BlocBuilder<CategoryByIdBloc, CategoryByIdState>(
//         builder: (context, state) {
//           if (state is CategoryByIdLoading) {
//             return const Center(child: CircularProgressIndicator(color: Color(0xff1E2E52)));
//           } else if (state is CategoryByIdError) {
//             return Center(child: Text(state.message));
//           } else if (state is CategoryByIdLoaded) {
//             return _buildCategoryContent(state.category.categories);
//           } else {
//             return Center(child: Text(AppLocalizations.of(context)!.translate("no_data_to_display")));
//           }
//         },
//       ),
//     );
//   }

//   Widget _buildCategoryContent(List<CategoryDataById> categories) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _buildTitleRow(AppLocalizations.of(context)!.translate('subcategories')),
//         const SizedBox(height: 8),
//         if (categories.isEmpty)
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 8),
//             child: Container(
//               decoration: TaskCardStyles.taskCardDecoration,
//               child: Center(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Text(
//                     AppLocalizations.of(context)!.translate('empty'),
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontFamily: 'Gilroy',
//                       fontWeight: FontWeight.w500,
//                       color: Color(0xff1E2E52),
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//               ),
//             ),
//           )
//         else
//           SizedBox(
//             height: MediaQuery.of(context).size.height * 0.75,
//             child: ListView.builder(
//               itemCount: categories.length,
//               itemBuilder: (context, index) {
//                 return _buildCategoryItem(categories[index]);
//               },
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildCategoryItem(CategoryDataById category) {
//     return GestureDetector(
//       onTap: () => _navigateToCategoryDetails(category),
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 8),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(12),
//           color: const Color(0xffF4F7FD),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 width: 100,
//                 height: 100,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(8),
//                   color: Colors.white,
//                 ),
//                 child: category.image != null
//                     ? ClipRRect(
//                         borderRadius: BorderRadius.circular(8),
//                         child: Image.network(
//                           '$baseUrl/${category.image}',
//                           fit: BoxFit.cover,
//                           errorBuilder: (_, __, ___) => _buildNoPhotoPlaceholder(),
//                         ),
//                       )
//                     : _buildNoPhotoPlaceholder(),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       category.name,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                         color: Color(0xff1E2E52),
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const SizedBox(height: 8),
//                     if (category.attributes.isNotEmpty)
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             AppLocalizations.of(context)!.translate('characteristics'),
//                             style: const TextStyle(
//                               fontSize: 12,
//                               color: Color(0xff99A4BA),
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Wrap(
//                             spacing: 4,
//                             runSpacing: 4,
//                             children: [
//                               ...category.attributes.take(4).map((attr) => Container(
//                                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                     decoration: BoxDecoration(
//                                       color: Colors.white,
//                                       borderRadius: BorderRadius.circular(4),
//                                     ),
//                                     child: Text(
//                                       attr.name.length > 10 ? '${attr.name.substring(0, 7)}...' : attr.name,
//                                       style: const TextStyle(
//                                         fontSize: 10,
//                                         color: Color(0xff1E2E52),
//                                       ),
//                                     ),
//                                   )),
//                               if (category.attributes.length > 3)
//                                 Container(
//                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                   decoration: BoxDecoration(
//                                     color: Colors.white,
//                                     borderRadius: BorderRadius.circular(4),
//                                   ),
//                                   child: Text(
//                                     '+${category.attributes.length - 3}',
//                                     style: const TextStyle(
//                                       fontSize: 10,
//                                       color: Color(0xff1E2E52),
//                                     ),
//                                   ),
//                                 ),
//                             ],
//                           ),
//                         ],
//                       ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildNoPhotoPlaceholder() {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         const Icon(Icons.photo_camera, size: 30, color: Color(0xff99A4BA)),
//         const SizedBox(height: 4),
//         Text(
//           AppLocalizations.of(context)!.translate("no_photo"),
//           style: const TextStyle(
//             fontSize: 12,
//             color: Color(0xff99A4BA),
//             fontFamily: 'Gilroy',
//           ),
//         ),
//       ],
//     );
//   }

//   void _navigateToCategoryDetails(CategoryDataById category) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => SubCategoryDetailsScreen(
//           ctgId: category.id,
//           category: category,
//         ),
//       ),
//     );
//   }

//   Row _buildTitleRow(String title) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           title,
//           style: TaskCardStyles.titleStyle.copyWith(
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         TextButton(
//           onPressed: () {
//             SubCategoryAddBottomSheet.show(context, widget.categoryId);
//             setState(() {
//               isCreateSubCategory = true;
//             });
//           },
//           style: TextButton.styleFrom(
//             foregroundColor: Colors.white,
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             backgroundColor: const Color(0xff1E2E52),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//           child: Text(
//             AppLocalizations.of(context)!.translate('add'),
//             style: const TextStyle(
//               fontSize: 16,
//               fontFamily: 'Gilroy',
//               fontWeight: FontWeight.w500,
//               color: Colors.white,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }