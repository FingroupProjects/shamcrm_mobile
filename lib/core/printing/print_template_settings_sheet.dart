import 'package:crm_task_manager/core/printing/print_template_settings.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';

class PrintTemplateSettingsSheet extends StatefulWidget {
  final String templateKey;
  final PrintTemplateSettings initialSettings;
  final String defaultTitle;
  final ValueChanged<String> onSaved;

  const PrintTemplateSettingsSheet({
    super.key,
    required this.templateKey,
    required this.initialSettings,
    required this.defaultTitle,
    required this.onSaved,
  });

  @override
  State<PrintTemplateSettingsSheet> createState() =>
      _PrintTemplateSettingsSheetState();
}

class _PrintTemplateSettingsSheetState
    extends State<PrintTemplateSettingsSheet> {
  late PrintTemplateSettings settings;
  late final TextEditingController titleController;
  late final TextEditingController headerController;
  late final TextEditingController footerController;
  late final TextEditingController goodsColumnController;
  late final TextEditingController quantityColumnController;
  late final TextEditingController priceColumnController;
  late final TextEditingController sumColumnController;
  late final TextEditingController widthController;
  late final TextEditingController heightController;

  @override
  void initState() {
    super.initState();
    settings = widget.initialSettings;
    titleController = TextEditingController(text: settings.customTitle);
    headerController = TextEditingController(text: settings.headerText);
    footerController = TextEditingController(text: settings.footerText);
    goodsColumnController =
        TextEditingController(text: settings.goodsColumnTitle);
    quantityColumnController =
        TextEditingController(text: settings.quantityColumnTitle);
    priceColumnController =
        TextEditingController(text: settings.priceColumnTitle);
    sumColumnController = TextEditingController(text: settings.sumColumnTitle);
    widthController =
        TextEditingController(text: _formatMm(settings.customWidthMm));
    heightController =
        TextEditingController(text: _formatMm(settings.customHeightMm));
  }

  @override
  void dispose() {
    titleController.dispose();
    headerController.dispose();
    footerController.dispose();
    goodsColumnController.dispose();
    quantityColumnController.dispose();
    priceColumnController.dispose();
    sumColumnController.dispose();
    widthController.dispose();
    heightController.dispose();
    super.dispose();
  }

  void update(PrintTemplateSettings value) {
    setState(() {
      settings = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.86,
        ),
        decoration: BoxDecoration(
          color: colors.surfacePrimary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Настройка печати',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Сбросить',
                    icon:
                        Icon(Icons.refresh_rounded, color: colors.iconPrimary),
                    onPressed: _reset,
                  ),
                  IconButton(
                    tooltip: 'Закрыть',
                    icon: Icon(Icons.close, color: colors.iconPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(color: colors.borderSubtle, height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  _sectionTitle('Размер и дизайн'),
                  _dropdown(
                    label: 'Размер бумаги',
                    value: settings.paperSize,
                    items: const [
                      DropdownMenuItem(value: 'a4', child: Text('A4')),
                      DropdownMenuItem(
                        value: 'receipt58',
                        child: Text('Чек 58 мм'),
                      ),
                      DropdownMenuItem(
                        value: 'receipt80',
                        child: Text('Чек 80 мм'),
                      ),
                      DropdownMenuItem(
                        value: 'custom',
                        child: Text('Свой размер'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      update(settings.copyWith(paperSize: value));
                    },
                  ),
                  if (settings.paperSize == 'custom')
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _textField(
                              controller: widthController,
                              label: 'Ширина, мм',
                              hint: '80',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              onChanged: (value) => update(
                                settings.copyWith(
                                  customWidthMm:
                                      _parseMm(value, settings.customWidthMm),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _textField(
                              controller: heightController,
                              label: 'Высота, мм',
                              hint: '300',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              onChanged: (value) => update(
                                settings.copyWith(
                                  customHeightMm:
                                      _parseMm(value, settings.customHeightMm),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  _dropdown(
                    label: 'Макет',
                    value: settings.layout,
                    items: const [
                      DropdownMenuItem(
                        value: 'standard',
                        child: Text('Стандартный'),
                      ),
                      DropdownMenuItem(
                        value: 'compact',
                        child: Text('Компактный'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      update(settings.copyWith(layout: value));
                    },
                  ),
                  _textField(
                    controller: titleController,
                    label: 'Заголовок документа',
                    hint: widget.defaultTitle,
                    onChanged: (value) =>
                        update(settings.copyWith(customTitle: value)),
                  ),
                  _textField(
                    controller: headerController,
                    label: 'Текст в шапке',
                    hint: 'Например: адрес, телефон, компания',
                    maxLines: 2,
                    onChanged: (value) =>
                        update(settings.copyWith(headerText: value)),
                  ),
                  _textField(
                    controller: footerController,
                    label: 'Текст в подвале',
                    hint: 'Например: спасибо за покупку',
                    maxLines: 2,
                    onChanged: (value) =>
                        update(settings.copyWith(footerText: value)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Размер текста',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        Slider(
                          value: settings.fontScale.clamp(0.85, 1.25),
                          min: 0.85,
                          max: 1.25,
                          divisions: 8,
                          activeColor: colors.buttonPrimaryBg,
                          label: '${(settings.fontScale * 100).round()}%',
                          onChanged: (value) =>
                              update(settings.copyWith(fontScale: value)),
                        ),
                      ],
                    ),
                  ),
                  _sectionTitle('Колонки таблицы'),
                  _textField(
                    controller: goodsColumnController,
                    label: 'Название колонки товара',
                    hint: 'Товар',
                    onChanged: (value) =>
                        update(settings.copyWith(goodsColumnTitle: value)),
                  ),
                  _textField(
                    controller: quantityColumnController,
                    label: 'Название колонки количества',
                    hint: 'Кол-во',
                    onChanged: (value) =>
                        update(settings.copyWith(quantityColumnTitle: value)),
                  ),
                  _textField(
                    controller: priceColumnController,
                    label: 'Название колонки цены',
                    hint: 'Цена',
                    onChanged: (value) =>
                        update(settings.copyWith(priceColumnTitle: value)),
                  ),
                  _textField(
                    controller: sumColumnController,
                    label: 'Название колонки суммы',
                    hint: 'Сумма',
                    onChanged: (value) =>
                        update(settings.copyWith(sumColumnTitle: value)),
                  ),
                  _sectionTitle('Поля документа'),
                  _switchTile('Клиент', settings.showClient,
                      (v) => update(settings.copyWith(showClient: v))),
                  _switchTile('Телефон клиента', settings.showClientPhone,
                      (v) => update(settings.copyWith(showClientPhone: v))),
                  _switchTile('ИНН клиента', settings.showClientInn,
                      (v) => update(settings.copyWith(showClientInn: v))),
                  _switchTile('Склад', settings.showStorage,
                      (v) => update(settings.copyWith(showStorage: v))),
                  _switchTile('Автор', settings.showAuthor,
                      (v) => update(settings.copyWith(showAuthor: v))),
                  _switchTile('Комментарий', settings.showComment,
                      (v) => update(settings.copyWith(showComment: v))),
                  _switchTile('Подписи', settings.showSignatures,
                      (v) => update(settings.copyWith(showSignatures: v))),
                  _switchTile('Цены', settings.showPrices,
                      (v) => update(settings.copyWith(showPrices: v))),
                  _switchTile('Суммы', settings.showSums,
                      (v) => update(settings.copyWith(showSums: v))),
                  _switchTile('Валюта', settings.showCurrency,
                      (v) => update(settings.copyWith(showCurrency: v))),
                  _switchTile('Статус', settings.showStatus,
                      (v) => update(settings.copyWith(showStatus: v))),
                  _switchTile('Общее количество', settings.showTotalQuantity,
                      (v) => update(settings.copyWith(showTotalQuantity: v))),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.buttonPrimaryBg,
                    foregroundColor: colors.textInverse,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text(
                    'Сохранить',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    await settings.save(widget.templateKey);
    if (!mounted) return;
    Navigator.pop(context);
    widget.onSaved('Настройки печати сохранены');
  }

  void _reset() {
    titleController.clear();
    headerController.clear();
    footerController.clear();
    goodsColumnController.text = 'Товар';
    quantityColumnController.text = 'Кол-во';
    priceColumnController.text = 'Цена';
    sumColumnController.text = 'Сумма';
    widthController.text = '210';
    heightController.text = '297';
    update(const PrintTemplateSettings());
  }

  Widget _sectionTitle(String title) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w700,
          color: colors.textSecondary,
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: colors.textSecondary,
            fontFamily: 'Gilroy',
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        dropdownColor: colors.surfacePrimary,
        style: TextStyle(
          color: colors.textPrimary,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(
          color: colors.textPrimary,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            color: colors.textSecondary,
            fontFamily: 'Gilroy',
          ),
          hintStyle: TextStyle(
            color: colors.fieldHint,
            fontFamily: 'Gilroy',
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colors.borderPrimary),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _switchTile(String title, bool value, ValueChanged<bool> onChanged) {
    final colors = context.appColors;
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
      ),
      value: value,
      activeThumbColor: colors.buttonPrimaryBg,
      onChanged: onChanged,
    );
  }

  double _parseMm(String value, double fallback) {
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    return parsed ?? fallback;
  }

  String _formatMm(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}
