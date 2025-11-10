import 'package:animated_custom_dropdown/custom_dropdown.dart';
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

class CallRatingWidget extends StatefulWidget {
  final String? selectedRating;
  final ValueChanged<String?> onChanged;

  const CallRatingWidget({
    Key? key,
    required this.selectedRating,
    required this.onChanged,
  }) : super(key: key);

  @override
  _CallRatingWidgetState createState() => _CallRatingWidgetState();
}

class _CallRatingWidgetState extends State<CallRatingWidget> {
  Rating? selectedRatingData;

  // Локальный список оценок
  final List<Rating> ratingsList = [
    Rating(id: '5', name: '5 - Отлично'),
    Rating(id: '4', name: '4 - Хорошо'),
    Rating(id: '3', name: '3 - Нормально'),
    Rating(id: '2', name: '2 - Плохо'),
    Rating(id: '1', name: '1 - Очень плохо'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.selectedRating != null) {
      try {
        selectedRatingData = ratingsList.firstWhere(
          (rating) => rating.id == widget.selectedRating,
        );
      } catch (e) {
        selectedRatingData = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              selectedItem?.name ??
                  AppLocalizations.of(context)!.translate('select_rating'),
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
          initialItem: selectedRatingData,
          onChanged: (value) {
            if (value != null) {
              widget.onChanged(value.id);
              setState(() {
                selectedRatingData = value;
              });
              FocusScope.of(context).unfocus();
            }
          },
        ),
      ],
    );
  }
}
