import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class CharacteristicData {
  final String title;

  CharacteristicData({
    required this.title,
  });
}

class CharacteristicSelectionWidget extends StatefulWidget {
  final String? selectedCharacteristic;
  final Function(String) onSelectCharacteristic;
  final Function(bool)? onDropdownVisibilityChanged;

  CharacteristicSelectionWidget({
    Key? key,
    this.selectedCharacteristic,
    required this.onSelectCharacteristic,
    required this.onDropdownVisibilityChanged,
  }) : super(key: key);

  @override
  State<CharacteristicSelectionWidget> createState() =>
      _CharacteristicSelectionWidgetState();
}

class _CharacteristicSelectionWidgetState
    extends State<CharacteristicSelectionWidget> {
  List<CharacteristicData> characteristicList = [];
  List<CharacteristicData> filteredList = [];
  CharacteristicData? selectedCharacteristicData;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isDropdownVisible = false;

  @override
  void initState() {
    super.initState();
    _textController.text = widget.selectedCharacteristic ?? '';
    _textController.addListener(() {
      widget.onSelectCharacteristic(_textController.text);
    });
    _loadCharacteristics();
  }

Future<void> _loadCharacteristics() async {
  try {
    final response = await ApiService().getAllCharacteristics();
    if (response.result != null) {
      setState(() {
        characteristicList = response.result!
            .map((item) => CharacteristicData(title: item.name))
            .toList();
        filteredList = List.from(characteristicList);
      });
    }
  } catch (e) {
    // silent fail
  }
}

  void filterSearchResults(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredList = List.from(characteristicList);
      } else {
        filteredList = characteristicList
            .where((item) =>
                item.title.toLowerCase().contains(query.toLowerCase().trim()))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildTextField();
  }

Widget _buildTextField() {
  final colors = context.appColors;
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // One outer border only. Theme outlines on TextField are turned off below.
      Container(
        decoration: BoxDecoration(
          color: colors.fieldBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colors.borderSubtle,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: colors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.translate('select_characteristic'),
                  hintStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: colors.textSecondary.withValues(alpha: 0.6),
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  widget.onSelectCharacteristic(value);
                },
                onTap: () {
                  _focusNode.requestFocus();
                  setState(() {
                    _isDropdownVisible = false;
                  });
                  if (widget.onDropdownVisibilityChanged != null) {
                    widget.onDropdownVisibilityChanged!(false);
                  }
                },
              ),
            ),
            IconButton(
              icon: Icon(Icons.arrow_drop_down, color: colors.textSecondary),
              onPressed: () {
                setState(() {
                  _isDropdownVisible = !_isDropdownVisible;
                  if (_isDropdownVisible) {
                    _focusNode.unfocus();
                  }
                  if (!_isDropdownVisible) {
                    _searchController.clear();
                  }
                });
                if (widget.onDropdownVisibilityChanged != null) {
                  widget.onDropdownVisibilityChanged!(_isDropdownVisible);
                }
              },
            ),
          ],
        ),
      ),
      if (_isDropdownVisible)
        Container(
          margin: const EdgeInsets.only(top: 8),
          constraints: const BoxConstraints(maxHeight: 220),
          decoration: BoxDecoration(
            color: colors.fieldBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.borderSubtle,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: colors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.translate('search'),
                    hintStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: colors.textSecondary,
                    ),
                    prefixIcon: Icon(Icons.search, color: colors.textSecondary),
                    isDense: true,
                    filled: true,
                    fillColor: colors.surfacePrimary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.borderPrimary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onChanged: (value) {
                    filterSearchResults(value);
                  },
                ),
              ),
              Flexible(
                child: filteredList.isEmpty && _searchController.text.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          AppLocalizations.of(context)!.translate('no_data_to_display'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            title: Text(
                              filteredList[index].title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Gilroy',
                                color: colors.textPrimary,
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                _textController.text = filteredList[index].title;
                                selectedCharacteristicData = filteredList[index];
                                _isDropdownVisible = false;
                                _searchController.clear();
                              });
                              widget.onSelectCharacteristic(filteredList[index].title);
                              if (widget.onDropdownVisibilityChanged != null) {
                                widget.onDropdownVisibilityChanged!(false);
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
    ],
  );
}
}
