part of '../../../custom_dropdown.dart';

class _SearchField<T> extends StatefulWidget {
  final List<T> items;
  final ValueChanged<List<T>> onSearchedItems;
  final String searchHintText;
  final _SearchType? searchType;
  final Future<List<T>> Function(String)? futureRequest;
  final ValueChanged<String>? onSearchQueryChanged;
  final Duration? futureRequestDelay;
  final ValueChanged<bool>? onFutureRequestLoading, mayFoundResult;
  final SearchFieldDecoration? decoration;

  const _SearchField.forListData({
    super.key,
    required this.items,
    required this.onSearchedItems,
    required this.searchHintText,
    required this.decoration,
  })  : searchType = _SearchType.onListData,
        futureRequest = null,
        onSearchQueryChanged = null,
        futureRequestDelay = null,
        onFutureRequestLoading = null,
        mayFoundResult = null;

  const _SearchField.forRequestData({
    super.key,
    required this.items,
    required this.onSearchedItems,
    required this.searchHintText,
    required this.futureRequest,
    this.onSearchQueryChanged,
    required this.futureRequestDelay,
    required this.onFutureRequestLoading,
    required this.mayFoundResult,
    required this.decoration,
  }) : searchType = _SearchType.onRequestData;

  @override
  State<_SearchField<T>> createState() => _SearchFieldState<T>();
}

class _SearchFieldState<T> extends State<_SearchField<T>> {
  final searchCtrl = TextEditingController();
  FocusNode focusNode = FocusNode();
  Timer? _delayTimer;
  int _requestGeneration = 0;

  @override
  void initState() {
    super.initState();
    if (widget.searchType == _SearchType.onRequestData &&
        widget.items.isEmpty &&
        (widget.decoration?.autoFocus ?? true)) {
      focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    _delayTimer?.cancel();
    super.dispose();
  }

  void onSearch(String query) {
    final result = widget.items.where(
      (item) {
        if (item is CustomDropdownListFilter) {
          return item.filter(query);
        } else {
          return item.toString().toLowerCase().contains(query.toLowerCase());
        }
      },
    ).toList();
    widget.onSearchedItems(result);
  }

  void onClear() {
    if (searchCtrl.text.isNotEmpty) {
      searchCtrl.clear();
      _delayTimer?.cancel();
      if (widget.searchType == _SearchType.onRequestData &&
          widget.futureRequest != null) {
        widget.onFutureRequestLoading?.call(true);
        searchRequest('');
      } else if (widget.onSearchQueryChanged != null) {
        widget.onSearchQueryChanged!('');
      } else {
        widget.onSearchedItems(widget.items);
      }
    }
  }

  void searchRequest(String val) async {
    final requestGeneration = ++_requestGeneration;
    List<T> result = [];
    try {
      result = await widget.futureRequest!(val);
    } catch (_) {
      result = [];
    }

    if (!mounted || requestGeneration != _requestGeneration) {
      return;
    }

    widget.onFutureRequestLoading?.call(false);
    widget.onSearchedItems(result);
    widget.mayFoundResult!(result.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextField(
        focusNode: focusNode,
        style: widget.decoration?.textStyle,
        onChanged: (val) async {
          if (widget.searchType != null &&
              widget.searchType == _SearchType.onRequestData &&
              widget.onSearchQueryChanged != null) {
            _delayTimer?.cancel();
            _delayTimer = Timer(widget.futureRequestDelay ?? Duration.zero, () {
              widget.onSearchQueryChanged!(val);
            });
          } else if (widget.searchType != null &&
              widget.searchType == _SearchType.onRequestData &&
              val.isNotEmpty) {
            widget.onFutureRequestLoading?.call(true);

            _delayTimer?.cancel();
            _delayTimer = Timer(widget.futureRequestDelay ?? Duration.zero, () {
              searchRequest(val);
            });
          } else if (widget.searchType != null &&
              widget.searchType == _SearchType.onRequestData &&
              val.isEmpty) {
            _delayTimer?.cancel();
            widget.onFutureRequestLoading?.call(true);
            searchRequest(val);
          } else if (widget.searchType == _SearchType.onListData) {
            onSearch(val);
          } else {
            widget.onSearchedItems(widget.items);
          }
        },
        controller: searchCtrl,
        decoration: InputDecoration(
          filled: true,
          fillColor: widget.decoration?.fillColor ??
              SearchFieldDecoration._defaultFillColor,
          constraints: widget.decoration?.constraints ??
              const BoxConstraints.tightFor(height: 40),
          contentPadding:
              widget.decoration?.contentPadding ?? const EdgeInsets.all(8),
          hintText: widget.searchHintText,
          hintStyle: widget.decoration?.hintStyle,
          prefixIcon: widget.decoration?.prefixIcon ??
              const Icon(Icons.search, size: 22),
          suffixIcon: widget.decoration?.suffixIcon?.call(onClear) ??
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close, size: 20),
              ),
          border: widget.decoration?.border ??
              OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.grey.withOpacity(.25),
                  width: 1,
                ),
              ),
          enabledBorder: widget.decoration?.border ??
              OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.grey.withOpacity(.25),
                  width: 1,
                ),
              ),
          focusedBorder: widget.decoration?.focusedBorder ??
              OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.grey.withOpacity(.25),
                  width: 1,
                ),
              ),
        ),
      ),
    );
  }
}
