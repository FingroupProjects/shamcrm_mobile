import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PrintTemplateSettings {
  final String layout;
  final String paperSize;
  final double customWidthMm;
  final double customHeightMm;
  final String customTitle;
  final String headerText;
  final String footerText;
  final double fontScale;
  final String goodsColumnTitle;
  final String quantityColumnTitle;
  final String priceColumnTitle;
  final String sumColumnTitle;
  final bool showClient;
  final bool showClientPhone;
  final bool showClientInn;
  final bool showStorage;
  final bool showAuthor;
  final bool showComment;
  final bool showSignatures;
  final bool showPrices;
  final bool showSums;
  final bool showCurrency;
  final bool showStatus;
  final bool showTotalQuantity;

  const PrintTemplateSettings({
    this.layout = 'standard',
    this.paperSize = 'a4',
    this.customWidthMm = 210,
    this.customHeightMm = 297,
    this.customTitle = '',
    this.headerText = '',
    this.footerText = '',
    this.fontScale = 1,
    this.goodsColumnTitle = 'Товар',
    this.quantityColumnTitle = 'Кол-во',
    this.priceColumnTitle = 'Цена',
    this.sumColumnTitle = 'Сумма',
    this.showClient = true,
    this.showClientPhone = true,
    this.showClientInn = true,
    this.showStorage = true,
    this.showAuthor = true,
    this.showComment = true,
    this.showSignatures = true,
    this.showPrices = true,
    this.showSums = true,
    this.showCurrency = true,
    this.showStatus = true,
    this.showTotalQuantity = true,
  });

  static const prefix = 'print_template_settings';

  PrintTemplateSettings copyWith({
    String? layout,
    String? paperSize,
    double? customWidthMm,
    double? customHeightMm,
    String? customTitle,
    String? headerText,
    String? footerText,
    double? fontScale,
    String? goodsColumnTitle,
    String? quantityColumnTitle,
    String? priceColumnTitle,
    String? sumColumnTitle,
    bool? showClient,
    bool? showClientPhone,
    bool? showClientInn,
    bool? showStorage,
    bool? showAuthor,
    bool? showComment,
    bool? showSignatures,
    bool? showPrices,
    bool? showSums,
    bool? showCurrency,
    bool? showStatus,
    bool? showTotalQuantity,
  }) {
    return PrintTemplateSettings(
      layout: layout ?? this.layout,
      paperSize: paperSize ?? this.paperSize,
      customWidthMm: customWidthMm ?? this.customWidthMm,
      customHeightMm: customHeightMm ?? this.customHeightMm,
      customTitle: customTitle ?? this.customTitle,
      headerText: headerText ?? this.headerText,
      footerText: footerText ?? this.footerText,
      fontScale: fontScale ?? this.fontScale,
      goodsColumnTitle: goodsColumnTitle ?? this.goodsColumnTitle,
      quantityColumnTitle: quantityColumnTitle ?? this.quantityColumnTitle,
      priceColumnTitle: priceColumnTitle ?? this.priceColumnTitle,
      sumColumnTitle: sumColumnTitle ?? this.sumColumnTitle,
      showClient: showClient ?? this.showClient,
      showClientPhone: showClientPhone ?? this.showClientPhone,
      showClientInn: showClientInn ?? this.showClientInn,
      showStorage: showStorage ?? this.showStorage,
      showAuthor: showAuthor ?? this.showAuthor,
      showComment: showComment ?? this.showComment,
      showSignatures: showSignatures ?? this.showSignatures,
      showPrices: showPrices ?? this.showPrices,
      showSums: showSums ?? this.showSums,
      showCurrency: showCurrency ?? this.showCurrency,
      showStatus: showStatus ?? this.showStatus,
      showTotalQuantity: showTotalQuantity ?? this.showTotalQuantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'layout': layout,
      'paperSize': paperSize,
      'customWidthMm': customWidthMm,
      'customHeightMm': customHeightMm,
      'customTitle': customTitle,
      'headerText': headerText,
      'footerText': footerText,
      'fontScale': fontScale,
      'goodsColumnTitle': goodsColumnTitle,
      'quantityColumnTitle': quantityColumnTitle,
      'priceColumnTitle': priceColumnTitle,
      'sumColumnTitle': sumColumnTitle,
      'showClient': showClient,
      'showClientPhone': showClientPhone,
      'showClientInn': showClientInn,
      'showStorage': showStorage,
      'showAuthor': showAuthor,
      'showComment': showComment,
      'showSignatures': showSignatures,
      'showPrices': showPrices,
      'showSums': showSums,
      'showCurrency': showCurrency,
      'showStatus': showStatus,
      'showTotalQuantity': showTotalQuantity,
    };
  }

  factory PrintTemplateSettings.fromJson(Map<String, dynamic> json) {
    return PrintTemplateSettings(
      layout: json['layout'] as String? ?? 'standard',
      paperSize: json['paperSize'] as String? ?? 'a4',
      customWidthMm: (json['customWidthMm'] as num?)?.toDouble() ?? 210,
      customHeightMm: (json['customHeightMm'] as num?)?.toDouble() ?? 297,
      customTitle: json['customTitle'] as String? ?? '',
      headerText: json['headerText'] as String? ?? '',
      footerText: json['footerText'] as String? ?? '',
      fontScale: (json['fontScale'] as num?)?.toDouble() ?? 1,
      goodsColumnTitle: json['goodsColumnTitle'] as String? ?? 'Товар',
      quantityColumnTitle: json['quantityColumnTitle'] as String? ?? 'Кол-во',
      priceColumnTitle: json['priceColumnTitle'] as String? ?? 'Цена',
      sumColumnTitle: json['sumColumnTitle'] as String? ?? 'Сумма',
      showClient: json['showClient'] as bool? ?? true,
      showClientPhone: json['showClientPhone'] as bool? ?? true,
      showClientInn: json['showClientInn'] as bool? ?? true,
      showStorage: json['showStorage'] as bool? ?? true,
      showAuthor: json['showAuthor'] as bool? ?? true,
      showComment: json['showComment'] as bool? ?? true,
      showSignatures: json['showSignatures'] as bool? ?? true,
      showPrices: json['showPrices'] as bool? ?? true,
      showSums: json['showSums'] as bool? ?? true,
      showCurrency: json['showCurrency'] as bool? ?? true,
      showStatus: json['showStatus'] as bool? ?? true,
      showTotalQuantity: json['showTotalQuantity'] as bool? ?? true,
    );
  }

  static Future<PrintTemplateSettings> load(String templateKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey(templateKey));
    if (raw == null || raw.isEmpty) return const PrintTemplateSettings();

    try {
      final data = jsonDecode(raw);
      if (data is Map<String, dynamic>) {
        return PrintTemplateSettings.fromJson(data);
      }
    } catch (_) {
      return const PrintTemplateSettings();
    }
    return const PrintTemplateSettings();
  }

  Future<void> save(String templateKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey(templateKey), jsonEncode(toJson()));
  }

  static Future<void> reset(String templateKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey(templateKey));
  }

  static String _storageKey(String templateKey) => '$prefix.$templateKey';
}
