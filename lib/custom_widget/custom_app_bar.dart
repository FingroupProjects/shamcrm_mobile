import 'package:crm_task_manager/notifications_screen.dart';
import 'package:flutter/material.dart';

class CustomAppBar extends StatefulWidget {
  String title;
  Function() onClickProfileAvatar;
  FocusNode focusNode;
  TextEditingController textEditingController;
  ValueChanged<String>? onChangedSearchInput;
  Function(bool) clearButtonClick;
  bool showSearchIcon;

  CustomAppBar({
    super.key,
    required this.title,
    required this.onClickProfileAvatar,
    required this.onChangedSearchInput,
    required this.textEditingController,
    required this.focusNode,
    required this.clearButtonClick,
    this.showSearchIcon = true,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  bool _isSearching = false;
  late TextEditingController _searchController;
  late FocusNode focusNode;

  @override
  void initState() {
    _searchController = widget.textEditingController;
    focusNode = widget.focusNode;
    super.initState();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        FocusScope.of(context).requestFocus(focusNode);
      } else {
        _searchController.clear();
        focusNode.unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: kToolbarHeight,
      color: Colors.white,
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Image.asset('assets/images/avatar.png'),
              onPressed: widget.onClickProfileAvatar,
            ),
          ),
          SizedBox(width: 8),
          if (!_isSearching)
            Expanded(
              child: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (_isSearching)
            Expanded(
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: _isSearching ? 200.0 : 0.0,
                child: TextField(
                  controller: _searchController,
                  focusNode: focusNode,
                  onChanged: widget.onChangedSearchInput,
                  decoration: InputDecoration(
                    hintText: 'Поиск...',
                    border: InputBorder.none,
                  ),
                  style: TextStyle(fontSize: 16),
                  autofocus: true,
                ),
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: Image.asset(
                  'assets/icons/AppBar/notification.png',
                  width: 24,
                  height: 24,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => NotificationsScreen()),
                  );
                },
              ),
              if (widget.showSearchIcon)
                IconButton(
                  icon: _isSearching
                      ? Icon(Icons.close)
                      : Image.asset(
                          'assets/icons/AppBar/search.png',
                          width: 24,
                          height: 24,
                        ),
                  onPressed: () {
                    _toggleSearch();
                    widget.clearButtonClick(_isSearching);
                    if (_isSearching) {
                      FocusScope.of(context).requestFocus(focusNode);
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
