// import 'package:crm_task_manager/api/service/api_service.dart';
// import 'package:crm_task_manager/bloc/my-task/my-task_bloc.dart';
// import 'package:crm_task_manager/bloc/my-task/my-task_event.dart';
// import 'package:crm_task_manager/bloc/my-task/my-task_state.dart';
// import 'package:crm_task_manager/custom_widget/custom_button.dart';
// import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
// import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
// import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
// import 'package:dio/dio.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:intl/intl.dart';
// import 'package:open_file/open_file.dart';
// import 'package:path_provider/path_provider.dart';

// class MyTaskEditScreen extends StatefulWidget {
//   final int taskId;
//   final String taskName;
//   final String taskStatus;
//   final int statusId;
//   final String? startDate;
//   final String? endDate;
//   final String? description;
//   final String? file;

//   MyTaskEditScreen({
//     required this.taskId,
//     required this.taskName,
//     required this.taskStatus,
//     required this.statusId,
//     this.startDate,
//     this.endDate,
//     this.description,
//     this.file,
//   });

//   @override
//   _MyTaskEditScreenState createState() => _MyTaskEditScreenState();
// }

// class _MyTaskEditScreenState extends State<MyTaskEditScreen> {
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController startDateController = TextEditingController();
//   final TextEditingController endDateController = TextEditingController();
//   final TextEditingController descriptionController = TextEditingController();

//   // Добавьте эти переменные в класс _MyTaskEditScreenState
//   String? selectedFile;
//   String? fileName;
//   String? fileSize;
//   bool isEndDateInvalid = false;
//   bool setPush = false;

//   final ApiService _apiService = ApiService();

//   @override
//   void initState() {
//     super.initState();
//     _initializeControllers();
//     _loadInitialData();

//     // Инициализируем информацию о файле, если он есть
//     if (widget.file != null) {
//       fileName = widget.file;
//     }
//   }

//   void _initializeControllers() {
//     nameController.text = widget.taskName;
//     if (widget.startDate != null) {
//       DateTime parsedStartDate = DateTime.parse(widget.startDate!);
//       startDateController.text =
//           DateFormat('dd/MM/yyyy').format(parsedStartDate);
//     }
//     if (widget.endDate != null) {
//       DateTime parsedEndDate = DateTime.parse(widget.endDate!);
//       endDateController.text = DateFormat('dd/MM/yyyy').format(parsedEndDate);
//     }
//     descriptionController.text = widget.description ?? '';
//   }

//   void _loadInitialData() {
//     context.read<MyTaskBloc>().add(FetchMyTaskStatuses());
//   }

//   InputDecoration _inputDecoration() {
//     return const InputDecoration(
//       contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       border: InputBorder.none,
//       filled: true,
//       fillColor: Color(0xFFF4F7FD),
//     );
//   }

//   Widget _buildPushNotificationCheckbox() {
//     return Padding(
//       padding: const EdgeInsets.only(top: 8),
//       child: Row(
//         children: [
//           Checkbox(
//             value: setPush,
//             onChanged: (bool? value) {
//               setState(() {
//                 setPush = value ?? true;
//               });
//             },
//             activeColor: const Color(0xff1E2E52),
//           ),
//           Text(
//             AppLocalizations.of(context)!.translate('set_push_notification'),
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w500,
//               fontFamily: 'Gilroy',
//               color: Color(0xff1E2E52),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFileSelection(MyTaskEditScreen task) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Если файл существует, отображаем информацию о нем
//         if (task.file != null && task.file!.isNotEmpty) ...[
//           Row(
//             children: [
//               Text(
//                 AppLocalizations.of(context)!.translate('file_details'),
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w500,
//                   fontFamily: 'Gilroy', // Используем шрифт Gilroy
//                   color: Color(0xff99A4BA),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               GestureDetector(
//                 onTap: () {
//                   _showFile(task.file!); // Показываем старый файл
//                 },
//                 child: Text(
//                   AppLocalizations.of(context)!.translate('link'),
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                     fontFamily: 'Gilroy', // Используем шрифт Gilroy
//                     color: Color(0xff1E2E52),
//                     decoration: TextDecoration.underline,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//         ],
//         // Отображаем надпись "Файл", если файл не выбран
//         if (task.file == null || task.file!.isEmpty) ...[
//           Text(
//             AppLocalizations.of(context)!.translate('file_details'),
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w500,
//               fontFamily: 'Gilroy', // Используем шрифт Gilroy
//               color: Color(0xff1E2E52),
//             ),
//           ),
//           const SizedBox(height: 8),
//         ],
//         // Поле выбора файла
//         GestureDetector(
//           onTap: _pickFile,
//           child: Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: const Color(0xFFF4F7FD),
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(color: const Color(0xFFF4F7FD)),
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     // Отображаем текст до выбора файла или название нового файла
//                     task.file ??
//                         AppLocalizations.of(context)!.translate('select_file'),
//                     style: TextStyle(
//                       fontFamily: 'Gilroy', // Используем шрифт Gilroy
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                       color: task.file != null
//                           ? const Color(0xff1E2E52)
//                           : const Color(0xff99A4BA),
//                     ),
//                   ),
//                 ),
//                 const Icon(
//                   Icons.attach_file,
//                   color: Color(0xff99A4BA),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Future<void> _pickFile() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles();

//     if (result != null) {
//       setState(() {
//         selectedFile = result.files.single.path;
//         fileName = result.files.single.name;
//         fileSize = '${(result.files.single.size / 1024).toStringAsFixed(2)} KB';
//       });

//       // Вывод в консоль
//       print('Файл выбран: $fileName, Путь: $selectedFile');
//     }
//   }

//   void _showFile(String fileUrl) async {
//     try {
//       print('Входящий fileUrl: $fileUrl');

//       // Получаем базовый домен из ApiService
//     final enteredDomainMap = await ApiService().getEnteredDomain();
//   // Извлекаем значения из Map
//     String? enteredMainDomain = enteredDomainMap['enteredMainDomain'];
//     String? enteredDomain = enteredDomainMap['enteredDomain']; 
//          print('Полученный базовый домен: $enteredDomain');

//       // Формируем полный URL файла
//       final fullUrl =
//           Uri.parse('https://$enteredDomain-back.$enteredMainDomain/storage/$fileUrl');
//       print('Сформированный полный URL: $fullUrl');

//       // Путь для сохранения файла
//       final directory = await getApplicationDocumentsDirectory();
//       final fileName = fileUrl.split('/').last;
//       final filePath = '${directory.path}/$fileName';

//       // Загружаем файл
//       final dio = Dio();
//       await dio.download(fullUrl.toString(), filePath);

//       print('Файл успешно скачан в $filePath');

//       // Открываем файл
//       final result = await OpenFile.open(filePath);
//       if (result.type == ResultType.error) {
//         print('Не удалось открыть файл: ${result.message}');
//         _showErrorSnackBar(
//             AppLocalizations.of(context)!.translate('failed_to_open_file'));
//       } else {
//         print('Файл открыт успешно.');
//       }
//     } catch (e) {
//       print('Ошибка при скачивании или открытии файла!');
//       _showErrorSnackBar(AppLocalizations.of(context)!
//           .translate('file_download_or_open_error'));
//     }
//   }

//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           message,
//           style: TextStyle(
//             fontFamily: 'Gilroy',
//             fontSize: 16,
//             fontWeight: FontWeight.w500,
//             color: Colors.white,
//           ),
//         ),
//         backgroundColor: Colors.red,
//         behavior: SnackBarBehavior.floating,
//         margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         forceMaterialTransparency: true,
//         backgroundColor: Colors.white,
//         elevation: 0,
//         centerTitle: false,
//         leading: IconButton(
//           icon: Image.asset(
//             'assets/icons/arrow-left.png',
//             width: 24,
//             height: 24,
//           ),
//           onPressed: () => Navigator.pop(context, null),
//         ),
//         title: Text(
//           AppLocalizations.of(context)!.translate('task_edit'),
//           style: TextStyle(
//             fontSize: 18,
//             fontFamily: 'Gilroy',
//             fontWeight: FontWeight.w600,
//             color: Color(0xff1E2E52),
//           ),
//         ),
//       ),
//       body: BlocListener<MyTaskBloc, MyTaskState>(
//         listener: (context, state) {
//           if (state is MyTaskSuccess) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(
//                   '${state.message}',
//                   style: TextStyle(
//                     fontFamily: 'Gilroy',
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.white,
//                   ),
//                 ),
//                 behavior: SnackBarBehavior.floating,
//                 margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 backgroundColor: Colors.green,
//                 elevation: 3,
//                 padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//                 duration: Duration(seconds: 3), // Установлено на 2 секунды
//               ),
//             );
//             Navigator.pop(context, true);
//           }
//         },
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               Expanded(
//                 child: SingleChildScrollView(
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       CustomTextField(
//                         controller: nameController,
//                         hintText: AppLocalizations.of(context)!
//                             .translate('enter_name_list'),
//                         label: AppLocalizations.of(context)!
//                             .translate('name_list'),
//                         validator: (value) => value!.isEmpty
//                             ? AppLocalizations.of(context)!
//                                 .translate('field_required')
//                             : null,
//                       ),
//                       const SizedBox(height: 16),
//                       CustomTextFieldDate(
//                         controller: startDateController,
//                         label: AppLocalizations.of(context)!
//                             .translate('from_list'),
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return AppLocalizations.of(context)!
//                                 .translate('field_required');
//                           }
//                           return null;
//                         },
//                       ),
//                       const SizedBox(height: 16),
//                       CustomTextFieldDate(
//                         controller: endDateController,
//                         label:
//                             AppLocalizations.of(context)!.translate('to_list'),
//                         hasError: isEndDateInvalid,
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return AppLocalizations.of(context)!
//                                 .translate('field_required');
//                           }
//                           return null;
//                         },
//                       ),
//                       const SizedBox(height: 8),
//                       CustomTextField(
//                         controller: descriptionController,
//                         hintText: AppLocalizations.of(context)!
//                             .translate('enter_description'),
//                         label: AppLocalizations.of(context)!
//                             .translate('description_list'),
//                         maxLines: 5,
//                       ),
//                       const SizedBox(height: 16),
//                       _buildFileSelection(widget),
//                       _buildPushNotificationCheckbox(), // Add this line

//                       // Добавляем виджет выбора файла
//                     ],
//                   ),
//                 ),
//               ),
//               Container(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: CustomButton(
//                         buttonText:
//                             AppLocalizations.of(context)!.translate('cancel'),
//                         buttonColor: const Color(0xffF4F7FD),
//                         textColor: Colors.black,
//                         onPressed: () => Navigator.pop(context, null),
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: BlocBuilder<MyTaskBloc, MyTaskState>(
//                         builder: (context, state) {
//                           if (state is MyTaskLoading) {
//                             return Center(
//                               child: CircularProgressIndicator(
//                                 color: Color(0xff1E2E52),
//                               ),
//                             );
//                           } else {
//                             return CustomButton(
//                               buttonText: AppLocalizations.of(context)!
//                                   .translate('save'),
//                               buttonColor: const Color(0xff4759FF),
//                               textColor: Colors.white,
//                               onPressed: () {
//                                 if (_formKey.currentState!.validate()) {
//                                   DateTime? startDate;
//                                   DateTime? endDate;

//                                   try {
//                                     if (startDateController.text.isNotEmpty) {
//                                       startDate = DateFormat('dd/MM/yyyy')
//                                           .parseStrict(
//                                               startDateController.text);
//                                     }
//                                     if (endDateController.text.isNotEmpty) {
//                                       endDate = DateFormat('dd/MM/yyyy')
//                                           .parseStrict(endDateController.text);
//                                     }
//                                     if (startDate != null &&
//                                         endDate != null &&
//                                         startDate.isAfter(endDate)) {
//                                       setState(() {
//                                         isEndDateInvalid = true;
//                                       });
//                                       ScaffoldMessenger.of(context)
//                                           .showSnackBar(
//                                         SnackBar(
//                                           content: Text(
//                                             AppLocalizations.of(context)!
//                                                 .translate(
//                                                     'start_date_after_end_date'),
//                                             style: TextStyle(
//                                               color: Colors.white,
//                                             ),
//                                           ),
//                                           backgroundColor: Colors.red,
//                                         ),
//                                       );
//                                       return;
//                                     }
//                                     final localizations = AppLocalizations.of(context)!;
//                                     context.read<MyTaskBloc>().add(
//                                           UpdateMyTask(
//                                             taskId: widget.taskId,
//                                             name: nameController.text,
//                                             taskStatusId: widget.statusId,
//                                             startDate: startDate,
//                                             endDate: endDate,
//                                             description:
//                                                 descriptionController.text,
//                                             filePath:
//                                                 selectedFile, // Добавляем путь к файлу
//                                             setPush: setPush, // Add this line
//                                             localizations: localizations,
//                                           ),
//                                         );
//                                   } catch (e) {
//                                     ScaffoldMessenger.of(context).showSnackBar(
//                                       SnackBar(
//                                         content: Text(
//                                           AppLocalizations.of(context)!
//                                               .translate('error_format_date'),
//                                         ),
//                                         backgroundColor: Colors.red,
//                                       ),
//                                     );
//                                   }
//                                 } else {
//                                   ScaffoldMessenger.of(context).showSnackBar(
//                                     SnackBar(
//                                       content: Text(
//                                          AppLocalizations.of(context)!.translate('fill_required_fields'),
//                                         style: TextStyle(
//                                           fontFamily: 'Gilroy',
//                                           fontSize: 16,
//                                           fontWeight: FontWeight.w500,
//                                           color: Colors.white,
//                                         ),
//                                       ),
//                                       behavior: SnackBarBehavior.floating,
//                                       margin: EdgeInsets.symmetric(
//                                           horizontal: 16, vertical: 8),
//                                       shape: RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.circular(12),
//                                       ),
//                                       backgroundColor: Colors.red,
//                                       elevation: 3,
//                                       padding: EdgeInsets.symmetric(
//                                           vertical: 12, horizontal: 16),
//                                       duration: Duration(seconds: 3),
//                                     ),
//                                   );
//                                 }
//                               },
//                             );
//                           }
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
