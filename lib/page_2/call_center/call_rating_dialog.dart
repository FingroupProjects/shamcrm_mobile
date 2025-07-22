import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/custom_widget/custom_textf.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

// Модель для оценки
class Rating {
  final String id;
  final String name;

  Rating({required this.id, required this.name});

  @override
  String toString() => name;
}

class CallRatingDialog extends StatefulWidget {
  final String? initialRating;
  final String? initialComment;
  final Function(String?, String?) onSubmit;

  const CallRatingDialog({
    Key? key,
    this.initialRating,
    this.initialComment,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _CallRatingDialogState createState() => _CallRatingDialogState();
}

class _CallRatingDialogState extends State<CallRatingDialog> {
  final TextEditingController _commentController = TextEditingController();
    final TextEditingController conclusionController = TextEditingController();

  String? _selectedRating;
  Rating? _selectedRatingData;
  bool _hasValidationError = false;
  String? _errorText;

  // Локальный список оценок
  final List<Rating> ratingsList = [
    Rating(id: '5', name: '5 - Отлично'),
    Rating(id: '4', name: '4 - Хорошо'),
    Rating(id: '3', name: '3 - Нормально'),
    Rating(id: '2', name: '2 - Плохо'),
    Rating(id: '1', name: '1 - Очень плохо'),
  ];
//  conclusionController.clear();

    bool hasValidationError = false;
    String? errorText;
  @override
  void initState() {
    super.initState();
    _selectedRating = widget.initialRating;
    _commentController.text = widget.initialComment ?? '';
    if (_selectedRating != null) {
      try {
        _selectedRatingData = ratingsList.firstWhere(
          (rating) => rating.id == _selectedRating,
        );
      } catch (e) {
        _selectedRatingData = null;
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.all(24),
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 300,
          minWidth: 280,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('rate_call'),
              style: const TextStyle(
                color: Color(0xff1E2E52),
                fontSize: 18,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.translate('rating'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            ),
            const SizedBox(height: 4),
            CustomDropdown<Rating>.search(
              closeDropDownOnClearFilterSearch: true,
              items: ratingsList,
              searchHintText: AppLocalizations.of(context)!.translate('search'),
              overlayHeight: 200,
              enabled: true,
              decoration: CustomDropdownDecoration(
                closedFillColor: Color(0xffF4F7FD),
                expandedFillColor: Colors.white,
                closedBorder: Border.all(
                  color: Color(0xffF4F7FD),
                  width: 1,
                ),
                closedBorderRadius: BorderRadius.circular(12),
                expandedBorder: Border.all(
                  color: Color(0xffF4F7FD),
                  width: 1,
                ),
                expandedBorderRadius: BorderRadius.circular(12),
              ),
              listItemBuilder: (context, item, isSelected, onItemSelect) {
                return Text(
                  item.name,
                  style: const TextStyle(
                    color: Color(0xff1E2E52),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                  ),
                );
              },
              headerBuilder: (context, selectedItem, enabled) {
                return Text(
                  selectedItem?.name ?? AppLocalizations.of(context)!.translate('select_rating'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                );
              },
              hintBuilder: (context, hint, enabled) => Text(
                AppLocalizations.of(context)!.translate('select_rating'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
              excludeSelected: false,
              initialItem: _selectedRatingData,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedRating = value.id;
                    _selectedRatingData = value;
                  });
                  FocusScope.of(context).unfocus();
                }
              },
            ),
            const SizedBox(height: 16),
                    // Using the new CustomTextFieldNoLabel component
                    Container(
                      margin: EdgeInsets.zero,
                      padding: EdgeInsets.zero,
                      child: CustomTextFieldNoLabel(
                        controller: _commentController,
                        hintText: AppLocalizations.of(context)!
                            .translate('write_comment'),
                        maxLines: 5,
                        keyboardType: TextInputType.multiline,
                        errorText: errorText, // Display validation error
                        hasError: hasValidationError, // Set error state
                        onChanged: (value) {
                          // Clear error when user types
                          if (hasValidationError) {
                            setState(() {
                              hasValidationError = false;
                              errorText = null;
                            });
                          }
                        },
                      ),
                    ),
            const SizedBox(height: 4),
            // TextField(
            //   controller: _commentController,
            //   maxLines: 4,
            //   decoration: InputDecoration(
            //     hintText: AppLocalizations.of(context)!.translate('write_comment'),
            //     hintStyle: const TextStyle(
            //       fontSize: 14,
            //       fontWeight: FontWeight.w500,
            //       fontFamily: 'Gilroy',
            //       color: Color(0xff99A4BA),
            //     ),
            //     border: OutlineInputBorder(
            //       borderRadius: BorderRadius.circular(12),
            //       borderSide: const BorderSide(color: Color(0xffF4F7FD)),
            //     ),
            //     enabledBorder: OutlineInputBorder(
            //       borderRadius: BorderRadius.circular(12),
            //       borderSide: const BorderSide(color: Color(0xffF4F7FD)),
            //     ),
            //     focusedBorder: OutlineInputBorder(
            //       borderRadius: BorderRadius.circular(12),
            //       borderSide: const BorderSide(color: Color(0xff1E2E52)),
            //     ),
            //     errorText: _hasValidationError ? _errorText : null,
            //   ),
            //   style: const TextStyle(
            //     fontSize: 14,
            //     fontWeight: FontWeight.w500,
            //     fontFamily: 'Gilroy',
            //     color: Color(0xff1E2E52),
            //   ),
            //   onChanged: (value) {
            //     if (_hasValidationError) {
            //       setState(() {
            //         _hasValidationError = false;
            //         _errorText = null;
            //       });
            //     }
            //   },
            // ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      AppLocalizations.of(context)!.translate('cancel'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Gilroy',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xff1E2E52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      if (_selectedRating == null) {
                        setState(() {
                          _hasValidationError = true;
                          _errorText = AppLocalizations.of(context)!.translate('field_required');
                        });
                        return;
                      }
                      widget.onSubmit(_selectedRating, _commentController.text);
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      AppLocalizations.of(context)!.translate('confirm'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Gilroy',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}