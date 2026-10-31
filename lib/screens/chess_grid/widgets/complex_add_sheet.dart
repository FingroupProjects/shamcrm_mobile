import 'dart:io';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_phone_number_input.dart';
import 'package:crm_task_manager/screens/chess_grid/controllers/chess_grid_controller.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/complex_map_picker_screen.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/work_schedule_selector.dart';
import 'package:crm_task_manager/widgets/required_field_slot.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

class ComplexAddSheet extends StatefulWidget {
  const ComplexAddSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: const ComplexAddSheet(),
      ),
    );
  }

  @override
  State<ComplexAddSheet> createState() => _ComplexAddSheetState();
}

class _ComplexAddSheetState extends State<ComplexAddSheet> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _buildingCountController = TextEditingController();
  final _salesAddressController = TextEditingController();
  final _salesPhoneController = TextEditingController();
  String _formattedPhone = '';
  final _salesEmailController = TextEditingController();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  String _workingHoursSummary = 'Пн–Пт: 09:00 – 18:00';

  // TZ Section 1: Geolocation & Photos
  final _latController = TextEditingController(text: '41.311081');
  final _lngController = TextEditingController(text: '69.240562');
  final List<String> _photos = [];
  // Required fields validation like LeadAddScreen
  Set<String> _missingFields = {};
  String? _firstMissingField;
  int _fieldErrorPulse = 0;

  bool _isLocating = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _buildingCountController.dispose();
    _salesAddressController.dispose();
    _salesPhoneController.dispose();
    _salesEmailController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _detectCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          showCustomSnackBar(
            context: context,
            message: 'Разрешите доступ к геолокации в настройках',
            isSuccess: false,
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        setState(() {
          _latController.text = pos.latitude.toStringAsFixed(6);
          _lngController.text = pos.longitude.toStringAsFixed(6);
        });
        showCustomSnackBar(
          context: context,
          message: 'Координаты определены',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          context: context,
          message: 'Не удалось определить координаты: $e',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _pickPhotos() async {
    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _photos.addAll(images.map((img) => img.path));
        });
      }
    } catch (e) {
      debugPrint('Error picking photos: $e');
    }
  }

  Future<void> _pickFromMap() async {
    final lat = double.tryParse(_latController.text) ?? 41.311081;
    final lng = double.tryParse(_lngController.text) ?? 69.240562;
    final result = await ComplexMapPickerScreen.show(
      context: context,
      initialLat: lat,
      initialLng: lng,
      initialAddress: _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : null,
    );

    if (result != null && mounted) {
      setState(() {
        _latController.text = result.latitude.toStringAsFixed(6);
        _lngController.text = result.longitude.toStringAsFixed(6);
        if (_addressController.text.trim().isEmpty && result.address != null) {
          _addressController.text = result.address!;
        }
      });
      showCustomSnackBar(
        context: context,
        message: 'Точка на карте выбрана',
        isSuccess: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Добавление объекта (ЖК)',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: colors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: colors.iconSecondary),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Form fields in Lead style
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RequiredFieldSlot(
                    invalid: _missingFields.contains('name'),
                    focus: _firstMissingField == 'name',
                    pulse: _fieldErrorPulse,
                    message: 'Укажите название ЖК',
                    child: CustomTextField(
                      controller: _nameController,
                      hintText: 'Введите название ЖК',
                      label: 'Название объекта (ЖК) *',
                      hasError: _missingFields.contains('name'),
                      onChanged: (val) {
                        if (val.trim().isNotEmpty && _missingFields.contains('name')) {
                          setState(() {
                            _missingFields.remove('name');
                            if (_firstMissingField == 'name') _firstMissingField = null;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  RequiredFieldSlot(
                    invalid: _missingFields.contains('address'),
                    focus: _firstMissingField == 'address',
                    pulse: _fieldErrorPulse,
                    message: 'Укажите адрес ЖК',
                    child: CustomTextField(
                      controller: _addressController,
                      hintText: 'Введите адрес ЖК',
                      label: 'Адрес ЖК *',
                      hasError: _missingFields.contains('address'),
                      onChanged: (val) {
                        if (val.trim().isNotEmpty && _missingFields.contains('address')) {
                          setState(() {
                            _missingFields.remove('address');
                            if (_firstMissingField == 'address') _firstMissingField = null;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  CustomTextField(
                    controller: _buildingCountController,
                    hintText: 'Введите количество корпусов',
                    label: 'Количество корпусов ЖК',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),

                  // Geolocation Block (TZ Section 1: GPS & Google Satellite Map)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Геолокация объекта',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: colors.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: _isLocating ? null : _detectCurrentLocation,
                            icon: _isLocating
                                ? const SizedBox(
                                    width: 13,
                                    height: 13,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.my_location_rounded, size: 15),
                            label: const Text(
                              'GPS',
                              style: TextStyle(fontFamily: 'Gilroy', fontSize: 12),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: colors.buttonPrimaryBg,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _pickFromMap,
                            icon: const Icon(Icons.map_outlined, size: 15),
                            label: const Text(
                              'Карта',
                              style: TextStyle(fontFamily: 'Gilroy', fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.buttonPrimaryBg,
                              side: BorderSide(color: colors.buttonPrimaryBg.withValues(alpha: 0.6)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _latController,
                          label: 'Широта (Lat)',
                          hintText: '41.311081',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomTextField(
                          controller: _lngController,
                          label: 'Долгота (Lng)',
                          hintText: '69.240562',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Photos of Complex (TZ Section 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Фотографии комплекса (${_photos.length})',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: colors.textPrimary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _pickPhotos,
                        icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                        label: const Text(
                          'Добавить фото',
                          style: TextStyle(fontFamily: 'Gilroy', fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: colors.buttonPrimaryBg,
                        ),
                      ),
                    ],
                  ),
                  if (_photos.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 72,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _photos.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (ctx, idx) {
                          final path = _photos[idx];
                          final isLocal = File(path).existsSync();
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 72,
                                  height: 72,
                                  color: colors.surfaceElevated,
                                  child: isLocal
                                      ? Image.file(File(path), fit: BoxFit.cover)
                                      : Image.network(
                                          path,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(
                                            Icons.broken_image_rounded,
                                            color: colors.iconSecondary,
                                          ),
                                        ),
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () => setState(() => _photos.removeAt(idx)),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Sales Office Block (TZ Section 1)
                  Text(
                    'Данные отдела продаж',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  CustomTextField(
                    controller: _salesAddressController,
                    hintText: 'Введите адрес офиса продаж',
                    label: 'Адрес отдела продаж',
                  ),
                  const SizedBox(height: 14),

                  CustomPhoneNumberInput(
                    controller: _salesPhoneController,
                    label: 'Телефон',
                    onInputChanged: (val) {
                      _formattedPhone = val;
                    },
                  ),
                  const SizedBox(height: 14),

                  CustomTextField(
                    controller: _salesEmailController,
                    hintText: 'Введите email',
                    label: 'Электронная почта',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),

                  // Working Hours Interactive Schedule Selector
                  WorkScheduleSelector(
                    initialTimeFrom: _startTime,
                    initialTimeTo: _endTime,
                    onChanged: (summary, startTime, endTime, days) {
                      _workingHoursSummary = summary;
                      _startTime = startTime;
                      _endTime = endTime;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Submit button in Lead style
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.buttonPrimaryBg,
                        foregroundColor: colors.buttonPrimaryFg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Создать жилой комплекс',
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();

    final missing = <String>[];
    if (name.isEmpty) missing.add('name');
    if (address.isEmpty) missing.add('address');

    if (missing.isNotEmpty) {
      setState(() {
        _missingFields = missing.toSet();
        _firstMissingField = missing.first;
        _fieldErrorPulse++;
      });
      showCustomSnackBar(
        context: context,
        message: 'Заполните обязательные поля',
        isSuccess: false,
      );
      return;
    }

    if (_missingFields.isNotEmpty) {
      setState(() {
        _missingFields = {};
        _firstMissingField = null;
      });
    }

    final buildingCount = int.tryParse(_buildingCountController.text) ?? 1;

    final startTime = _formatClock(_startTime);
    final endTime = _formatClock(_endTime);
    final rawHours = _workingHoursSummary.isNotEmpty
        ? _workingHoursSummary
        : '$startTime – $endTime';

    final lat = double.tryParse(_latController.text) ?? 41.311081;
    final lng = double.tryParse(_lngController.text) ?? 69.240562;

    setState(() => _isSaving = true);

    try {
      await ChessGridController.instance.addComplex(
        name: name,
        address: address,
        buildingCount: buildingCount,
        salesAddress: _salesAddressController.text.trim(),
        phone: _formattedPhone.isNotEmpty
            ? _formattedPhone
            : _salesPhoneController.text.trim(),
        email: _salesEmailController.text.trim(),
        workingHours: rawHours,
        startTime: startTime,
        endTime: endTime,
        lat: lat,
        lng: lng,
        photos: _photos,
      );

      if (mounted) {
        Navigator.pop(context);
        showCustomSnackBar(
          context: context,
          message: 'Жилой комплекс «$name» успешно создан!',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        showCustomSnackBar(
          context: context,
          message: 'Ошибка при создании ЖК: $e',
          isSuccess: false,
        );
      }
    }
  }

  String _formatClock(TimeOfDay? time) {
    if (time == null) return '';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
