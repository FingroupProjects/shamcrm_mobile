import 'package:flutter/material.dart';
class CharacteristicData {
  final String title;

  CharacteristicData({required this.title});
}

List<CharacteristicData> testCharacteristics = [
  CharacteristicData(title: "Цвет"),
  CharacteristicData(title: "Размер"),
  CharacteristicData(title: "Материал"),
  CharacteristicData(title: "Вес"),
  CharacteristicData(title: "Производитель"),
];

class CharacteristicSelectionWidget extends StatefulWidget {
  final String? selectedCharacteristic;
  final Function(String) onSelectCharacteristic;

  CharacteristicSelectionWidget({
    Key? key,
    this.selectedCharacteristic,
    required this.onSelectCharacteristic,
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
    characteristicList = testCharacteristics;
    filteredList = List.from(characteristicList);
    _textController.text = widget.selectedCharacteristic ?? '';
    _textController.addListener(() {
      widget.onSelectCharacteristic(_textController.text);
    });
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text(
        //   "Характеристика", // Заголовок
        //   style: TextStyle(
        //     fontSize: 16,
        //     fontWeight: FontWeight.w500,
        //     fontFamily: 'Gilroy',
        //     color: Color(0xfff1E2E52),
        //   ),
        // ),
        const SizedBox(height: 4),
        _buildTextField(),
      ],
    );
  }

 Widget _buildTextField() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        decoration: BoxDecoration(
          color: Color(0xffF4F7FD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Color(0xffF4F7FD),
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
                  color: Color(0xff1E2E52), 
                ),
                decoration: InputDecoration(
                  hintText: "Выберите характеристику",
                  hintStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52).withOpacity(0.6),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  widget.onSelectCharacteristic(value);
                },
              ),
            ),
            IconButton(
              icon: Icon(Icons.arrow_drop_down),
              onPressed: () {
                setState(() {
                  _isDropdownVisible = !_isDropdownVisible;
                  if (!_isDropdownVisible) {
                    _searchController.clear();
                  }
                });
              },
            ),
          ],
        ),
      ),
      if (_isDropdownVisible)
        Container(
          margin: EdgeInsets.only(top: 2),
          constraints: BoxConstraints(maxHeight: 350,maxWidth: 270),
          decoration: BoxDecoration(
          color: Color(0xffF4F7FD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Color(0xffF4F7FD),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: "Поиск",
                    prefixIcon: Icon(Icons.search, color: Color(0xff1E2E52)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    filterSearchResults(value);
                  },
                ),
              ),
              Expanded(
                child: filteredList.isEmpty && _searchController.text.isNotEmpty
                    ? Center(
                        child: Text(
                          "Нет данных для отображения",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(
                              filteredList[index].title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Gilroy',
                                color: Color(0xff1E2E52), 
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