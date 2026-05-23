import 'package:cached_network_image/cached_network_image.dart';
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
  final TextEditingController _totalController = TextEditingController();
  final FocusNode _quantityFocusNode = FocusNode();
  final FocusNode _totalFocusNode = FocusNode();
  _EditField _activeField = _EditField.quantity;
  _EditField _panelField = _EditField.quantity;
  late RmkGood _good;
  bool _isSaving = false;
  bool _isProgrammaticEdit = false;

  double get _quantity => double.tryParse(_quantityController.text) ?? 0;

  double get _baseTotal => _quantity * _good.price;

  double get _calculatedTotal => _baseTotal;

  double get _total {
    final manualTotal = double.tryParse(_totalController.text);
    if (_totalController.text.isNotEmpty && manualTotal != null) {
      return manualTotal;
    }
    return _calculatedTotal;
  }

  @override
  void initState() {
    super.initState();
    _good = widget.good;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _selectField(_EditField.quantity);
    });
    widget.repository.getCartItem(widget.good.id).then((item) {
      if (!mounted || item == null) return;
      setState(() {
        _setText(_quantityController, _formatInput(item.quantity));
        final customTotal = item.customTotal;
        if (customTotal != null) {
          _setText(_totalController, _formatInput(customTotal));
        }
      });
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _totalController.dispose();
    _quantityFocusNode.dispose();
    _totalFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveAndPop() async {
    if (_isSaving) return;
    if (_quantity > _good.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'На складе доступно только ${_formatQuantity(_good.quantity)}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    _isSaving = true;
    await widget.repository.upsertCartItem(
      good: _good,
      quantity: _quantity,
      price: _good.price,
      customTotal: _totalController.text.isNotEmpty ? _total : null,
    );
    if (mounted) Navigator.pop(context);
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
        return;
      }
      if (key == 'C') {
        _setText(controller, '');
        return;
      }
      _insertAtCursor(controller, key);
    });
  }

  TextEditingController get _currentController {
    switch (_activeField) {
      case _EditField.quantity:
        return _quantityController;
      case _EditField.total:
        return _totalController;
    }
  }

  void _insertAtCursor(TextEditingController controller, String value) {
    final text = controller.text;
    if (value == '.' && text.contains('.')) return;

    final selection = controller.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final nextText = text.replaceRange(start, end, value);
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

  void _selectField(_EditField field) {
    setState(() {
      _activeField = field;
      if (field != _EditField.total) {
        _panelField = field;
      }
    });
    switch (field) {
      case _EditField.quantity:
        _quantityFocusNode.requestFocus();
        return;
      case _EditField.total:
        if (_totalController.text.isEmpty) {
          _setText(_totalController, _formatInput(_calculatedTotal));
        }
        _totalFocusNode.requestFocus();
        return;
    }
  }

  void _handleFieldChanged(_EditField field) {
    if (_isProgrammaticEdit) return;
    if (field == _EditField.quantity) {
      _totalController.clear();
    }
    setState(() {
      _activeField = field;
      if (field != _EditField.total) {
        _panelField = field;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          forceMaterialTransparency: true,
          title: const Text(
            'О товаре',
            style: TextStyle(
              color: Color(0xff1E2E52),
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w700,
              fontSize: 20,
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
              _ProductHeader(good: _good),
              _TotalRow(
                total: _total,
                selected: _activeField == _EditField.total,
                controller: _totalController,
                focusNode: _totalFocusNode,
                onTap: () => _selectField(_EditField.total),
                onChanged: () => _handleFieldChanged(_EditField.total),
              ),
              _ActiveFieldPanel(
                activeField: _panelField,
                quantityController: _quantityController,
                totalController: _totalController,
                quantityFocusNode: _quantityFocusNode,
                totalFocusNode: _totalFocusNode,
                onSelect: _selectField,
                onChanged: _handleFieldChanged,
              ),
              Expanded(child: _NumberPad(onTap: _tapKey)),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff1E2E52),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const RoundedRectangleBorder(),
                  ),
                  onPressed: _saveAndPop,
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
}

enum _EditField { quantity, total }

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({required this.good});

  final RmkGood good;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xff1E2E52),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 96,
              height: 96,
              child: _ProductImage(url: good.imageUrl),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  good.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Gilroy',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                _InfoLine('Остаток', _formatQuantity(good.quantity)),
                _InfoLine('Продажная цена', _formatMoney(good.price)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatQuantity(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        '$label: $value',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Gilroy',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return const ColoredBox(
        color: Colors.white,
        child: Icon(
          Icons.image_outlined,
          color: Color(0xff99A4BA),
          size: 42,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      memCacheWidth: 320,
      placeholder: (_, __) => const ColoredBox(color: Colors.white),
      errorWidget: (_, __, ___) => const ColoredBox(
        color: Colors.white,
        child: Icon(
          Icons.image_outlined,
          color: Color(0xff99A4BA),
          size: 42,
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.total,
    required this.selected,
    required this.controller,
    required this.focusNode,
    required this.onTap,
    required this.onChanged,
  });

  final double total;
  final bool selected;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onTap;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected
                    ? const Color(0xff1E2E52)
                    : const Color(0xffD9E1EC),
                width: selected ? 2 : 1,
              ),
            ),
          ),
          child: Row(
            children: [
              const Text(
                'Всего:',
                style: TextStyle(
                  color: Color(0xff1E2E52),
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 150,
                child: selected
                    ? _NumberField(
                        controller: controller,
                        focusNode: focusNode,
                        selected: true,
                        hint: _formatMoney(total),
                        textAlign: TextAlign.right,
                        onTap: onTap,
                        onChanged: onChanged,
                      )
                    : Text(
                        _formatMoney(total),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Color(0xff1E2E52),
                          fontFamily: 'Gilroy',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveFieldPanel extends StatelessWidget {
  const _ActiveFieldPanel({
    required this.activeField,
    required this.quantityController,
    required this.totalController,
    required this.quantityFocusNode,
    required this.totalFocusNode,
    required this.onSelect,
    required this.onChanged,
  });

  final _EditField activeField;
  final TextEditingController quantityController;
  final TextEditingController totalController;
  final FocusNode quantityFocusNode;
  final FocusNode totalFocusNode;
  final ValueChanged<_EditField> onSelect;
  final ValueChanged<_EditField> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xffE5EAF2)),
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 160),
        child: switch (activeField) {
          _EditField.quantity => _PanelNumberField(
              key: const ValueKey('quantity'),
              label: 'Количество',
              controller: quantityController,
              focusNode: quantityFocusNode,
              suffix: 'шт',
              onTap: () => onSelect(_EditField.quantity),
              onChanged: () => onChanged(_EditField.quantity),
            ),
          _EditField.total => _PanelNumberField(
              key: const ValueKey('total'),
              label: 'Всего',
              controller: totalController,
              focusNode: totalFocusNode,
              suffix: '',
              onTap: () => onSelect(_EditField.total),
              onChanged: () => onChanged(_EditField.total),
            ),
        },
      ),
    );
  }
}

class _PanelNumberField extends StatelessWidget {
  const _PanelNumberField({
    super.key,
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.suffix,
    required this.onTap,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String suffix;
  final VoidCallback onTap;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xff718096),
              fontFamily: 'Gilroy',
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(
          width: 160,
          child: _NumberField(
            controller: controller,
            focusNode: focusNode,
            selected: true,
            hint: '',
            suffix: suffix,
            onTap: onTap,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.focusNode,
    required this.selected,
    required this.hint,
    required this.onTap,
    required this.onChanged,
    this.suffix,
    this.textAlign = TextAlign.center,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool selected;
  final String hint;
  final String? suffix;
  final TextAlign textAlign;
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
      textAlign: textAlign,
      onTap: onTap,
      onChanged: (_) => onChanged(),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      maxLines: 1,
      cursorColor: const Color(0xff1E2E52),
      style: const TextStyle(
        color: Color(0xff1E2E52),
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        isDense: true,
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        hintText: hint,
        suffixText: suffix,
        suffixStyle: const TextStyle(
          color: Color(0xff1E2E52),
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w700,
        ),
        hintStyle: const TextStyle(
          color: Color(0xff1E2E52),
          fontSize: 16,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NumberPad extends StatelessWidget {
  const _NumberPad({required this.onTap});

  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', '⌫'];
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.45,
      ),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final key = keys[index];
        return _KeyButton(
          label: key,
          onTap: () => onTap(key),
        );
      },
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xffE5EAF2), width: 0.5),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xff1E2E52),
                fontSize: 26,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _formatMoney(double value) {
  if (value == value.roundToDouble()) return '${value.toInt()}';
  return value.toStringAsFixed(2);
}

String _formatQuantity(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(2);
}
