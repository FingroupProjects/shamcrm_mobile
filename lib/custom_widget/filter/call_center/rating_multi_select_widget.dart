import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class RatingMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedRatings;
  final Function(List<RatingData>) onSelectRatings;

  RatingMultiSelectWidget({
    super.key,
    required this.selectedRatings,
    required this.onSelectRatings,
  });

  @override
  State<RatingMultiSelectWidget> createState() => _RatingMultiSelectWidgetState();
}

class _RatingMultiSelectWidgetState extends State<RatingMultiSelectWidget> {
  // Локальный список оценок
  final List<RatingData> ratingsList = [
    RatingData(id: 5, name: '5 - Отличное'),
    RatingData(id: 4, name: '4 - Хорошее'),
    RatingData(id: 3, name: '3 - Удовлетворительное'),
    RatingData(id: 2, name: '2 - Плохое'),
    RatingData(id: 1, name: '1 - Ужасное'),
  ];

  List<RatingData> selectedRatingsData = [];

  @override
  void initState() {
    super.initState();
    // Инициализация выбранных элементов, если переданы
    if (widget.selectedRatings != null && ratingsList.isNotEmpty) {
      selectedRatingsData = ratingsList
          .where((rating) => widget.selectedRatings!.contains(rating.id.toString()))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('rating_title'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 4),
        CustomDropdown<RatingData>.multiSelectSearch(
          items: ratingsList,
          initialItems: selectedRatingsData,
          searchHintText: AppLocalizations.of(context)!.translate('search'),
          overlayHeight: 400,
          decoration:   CustomDropdownDecoration(
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
            return ListTile(
              minTileHeight: 1,
              minVerticalPadding: 2,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Padding(
                padding: EdgeInsets.zero,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xff1E2E52), width: 1),
                        color: isSelected ? const Color(0xff1E2E52) : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () {
                onItemSelect();
                FocusScope.of(context).unfocus();
              },
            );
          },
          headerListBuilder: (context, hint, enabled) {
            int selectedRatingsCount = selectedRatingsData.length;
            return Text(
              selectedRatingsCount == 0
                  ? AppLocalizations.of(context)!.translate('select_rating')
                  : '${AppLocalizations.of(context)!.translate('select_rating')} $selectedRatingsCount',
              style: const TextStyle(
                fontSize: 16,
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
          onListChanged: (values) {
            widget.onSelectRatings(values);
            setState(() {
              selectedRatingsData = values;
            });
          },
        ),
      ],
    );
  }
}

// Модель данных для оценки
class RatingData {
  final int id;
  final String name;

  RatingData({required this.id, required this.name});

  @override
  String toString() => name;
}
