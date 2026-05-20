import 'package:crm_task_manager/offline/db/app_database.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RmkQuantityScreen extends StatefulWidget {
  const RmkQuantityScreen({
    super.key,
    required this.good,
    required this.repository,
  });

  final RmkGood good;
  final RmkRepository repository;

  @override
  State<RmkQuantityScreen> createState() => _RmkQuantityScreenState();
}

class _RmkQuantityScreenState extends State<RmkQuantityScreen> {
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  final FocusNode _quantityFocusNode = FocusNode();
  final FocusNode _priceFocusNode = FocusNode();
  final FocusNode _totalFocusNode = FocusNode();
  _EditField _activeField = _EditField.quantity;
  bool _isSaving = false;
  bool _isProgrammaticEdit = false;

  double get _quantity => double.tryParse(_quantityController.text) ?? 0;

  double get _price =>
      double.tryParse(_priceController.text) ?? widget.good.price;

  double get _total {
    final editedTotal = double.tryParse(_totalController.text);
    if (_totalController.text.isNotEmpty && editedTotal != null) {
      return editedTotal;
    }
    return _quantity * _price;
  }

  @override
  void initState() {
    super.initState();
    _setText(_priceController, _formatInput(widget.good.price));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _selectField(_EditField.quantity);
    });
    widget.repository.getCartItem(widget.good.id).then((item) {
      if (!mounted || item == null) return;
      setState(() {
        _setText(_quantityController, _formatInput(item.quantity));
        _setText(_priceController, _formatInput(item.price));
        if (item.customTotal != null) {
          _setText(_totalController, _formatInput(item.customTotal!));
        }
      });
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _totalController.dispose();
    _quantityFocusNode.dispose();
    _priceFocusNode.dispose();
    _totalFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveAndPop() async {
    if (_isSaving) return;
    _isSaving = true;
    await widget.repository.upsertCartItem(
      good: widget.good,
      quantity: _quantity,
      price: _price,
      customTotal: _totalController.text.isEmpty ? null : _total,
    );
    if (mounted) Navigator.pop(context);
  }

  void _cancelAndPop() {
    Navigator.pop(context);
  }

  Future<void> _deleteAndPop() async {
    await widget.repository.removeCartItem(widget.good.id);
    if (mounted) Navigator.pop(context);
  }

  void _tapKey(String key) {
    setState(() {
      final controller = _currentController;
      if (key == '⌫') {
        _deleteAtCursor(controller);
        _recalculateAfterInput();
        return;
      }
      if (key == 'C') {
        _setText(controller, '');
        _recalculateAfterInput();
        return;
      }
      _insertAtCursor(controller, key);
      _recalculateAfterInput();
    });
  }

  TextEditingController get _currentController {
    switch (_activeField) {
      case _EditField.quantity:
        return _quantityController;
      case _EditField.price:
        return _priceController;
      case _EditField.total:
        return _totalController;
    }
  }

  void _insertAtCursor(TextEditingController controller, String value) {
    final text = controller.text;
    final selection = controller.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final nextText = text.replaceRange(start, end, value);
    if (value == '.' && text.contains('.')) return;
    if (!_isValidNumberInput(nextText)) return;
    controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: start + value.length),
    );
  }

  void _deleteAtCursor(TextEditingController controller) {
    final text = controller.text;
    if (text.isEmpty) return;
    final selection = controller.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    if (start != end) {
      controller.value = TextEditingValue(
        text: text.replaceRange(start, end, ''),
        selection: TextSelection.collapsed(offset: start),
      );
      return;
    }
    if (start <= 0) return;
    controller.value = TextEditingValue(
      text: text.replaceRange(start - 1, start, ''),
      selection: TextSelection.collapsed(offset: start - 1),
    );
  }

  bool _isValidNumberInput(String value) {
    if (value.isEmpty) return true;
    if (value == '.') return true;
    return RegExp(r'^\d*\.?\d*$').hasMatch(value);
  }

  void _setText(TextEditingController controller, String value) {
    _isProgrammaticEdit = true;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _isProgrammaticEdit = false;
  }

  void _focusActiveField() {
    switch (_activeField) {
      case _EditField.quantity:
        _quantityFocusNode.requestFocus();
        return;
      case _EditField.price:
        _priceFocusNode.requestFocus();
        return;
      case _EditField.total:
        _totalFocusNode.requestFocus();
        return;
    }
  }

  void _recalculateAfterInput() {
    if (_activeField == _EditField.total) {
      return;
    }
    _totalController.clear();
  }

  void _selectField(_EditField field) {
    setState(() {
      _activeField = field;
      if (field == _EditField.total && _totalController.text.isEmpty) {
        _setText(_totalController, _formatInput(_quantity * _price));
      }
    });
    _focusActiveField();
  }

  void _handleFieldChanged(_EditField field) {
    if (_isProgrammaticEdit) return;
    _activeField = field;
    setState(_recalculateAfterInput);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) _cancelAndPop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xffF8F9FB),
        appBar: AppBar(
          forceMaterialTransparency: true,
          title: Text(
            widget.good.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xff1E2E52),
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Удалить',
              onPressed: _deleteAndPop,
              icon: const Icon(
                Icons.delete_outline,
                color: Color(0xffF44336),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xffE2E7F0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Количество',
                        style: TextStyle(
                          color: Color(0xff718096),
                          fontSize: 13,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _activeField == _EditField.quantity
                                  ? const Color(0xff1E2E52)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: _NumberField(
                          controller: _quantityController,
                          focusNode: _quantityFocusNode,
                          selected: _activeField == _EditField.quantity,
                          hint: '0',
                          fontSize: 38,
                          onTap: () => _selectField(_EditField.quantity),
                          onChanged: () =>
                              _handleFieldChanged(_EditField.quantity),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCell(
                              selected: _activeField == _EditField.price,
                              onTap: () => _selectField(_EditField.price),
                              label: 'Цена',
                              controller: _priceController,
                              focusNode: _priceFocusNode,
                              onChanged: () =>
                                  _handleFieldChanged(_EditField.price),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _SummaryCell(
                              selected: _activeField == _EditField.total,
                              onTap: () => _selectField(_EditField.total),
                              label: 'Сумма',
                              controller: _totalController,
                              focusNode: _totalFocusNode,
                              fallbackText: _formatMoney(_total),
                              onChanged: () =>
                                  _handleFieldChanged(_EditField.total),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.55,
                  children: const [
                    _KeyButton('1'),
                    _KeyButton('2'),
                    _KeyButton('3'),
                    _KeyButton('4'),
                    _KeyButton('5'),
                    _KeyButton('6'),
                    _KeyButton('7'),
                    _KeyButton('8'),
                    _KeyButton('9'),
                    _KeyButton('.'),
                    _KeyButton('0'),
                    _KeyButton('⌫'),
                  ].map((button) {
                    return _KeyButton(
                      button.label,
                      onTap: () => _tapKey(button.label),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xff1E2E52),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: const BorderSide(color: Color(0xffD9E1EC)),
                        ),
                        onPressed: _cancelAndPop,
                        child: const Text('Отмена'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff1E2E52),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _saveAndPop,
                        child: const Text('Готово'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatInput(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }

  static String _formatMoney(double value) {
    if (value == value.roundToDouble()) return '${value.toInt()}';
    return value.toStringAsFixed(2);
  }
}

enum _EditField { quantity, price, total }

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.selected,
    required this.onTap,
    required this.onChanged,
    this.fallbackText,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onChanged;
  final String? fallbackText;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xffEEF3FA) : const Color(0xffF8F9FB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xff1E2E52) : const Color(0xffE2E7F0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xff718096),
                fontSize: 11,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            _NumberField(
              controller: controller,
              focusNode: focusNode,
              selected: selected,
              hint: fallbackText ?? '0',
              fontSize: 15,
              onTap: onTap,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.focusNode,
    required this.selected,
    required this.hint,
    required this.fontSize,
    required this.onTap,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool selected;
  final String hint;
  final double fontSize;
  final VoidCallback onTap;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      readOnly: false,
      showCursor: selected,
      enableInteractiveSelection: true,
      keyboardType: TextInputType.none,
      onTap: onTap,
      onChanged: (_) => onChanged(),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      maxLines: 1,
      cursorColor: const Color(0xff1E2E52),
      cursorWidth: 2,
      style: TextStyle(
        color: const Color(0xff1E2E52),
        fontSize: fontSize,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        isDense: true,
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        hintText: hint,
        hintStyle: TextStyle(
          color: const Color(0xff1E2E52),
          fontSize: fontSize,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton(this.label, {this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xff1E2E52),
              fontSize: 26,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
