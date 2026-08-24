import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/page_2/dashboard/cash_balance_model.dart';
import 'package:crm_task_manager/models/page_2/dashboard/cash_register_details_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/global_fun.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CashRegisterDetailsScreen extends StatefulWidget {
  final CashRegisters cashRegister;

  const CashRegisterDetailsScreen({
    super.key,
    required this.cashRegister,
  });

  @override
  State<CashRegisterDetailsScreen> createState() =>
      _CashRegisterDetailsScreenState();
}

class _CashRegisterDetailsScreenState extends State<CashRegisterDetailsScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  CashRegisterDetailsInfo? _details;
  List<CashRegisterHistoryItem> _history = [];
  CashRegisterDetailsMeta? _meta;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadDetails();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || _isLoading) return;
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent * 0.9) return;
    if (!(_meta != null &&
        (_meta!.currentPage ?? 1) < (_meta!.lastPage ?? 1))) {
      return;
    }
    _loadDetails(page: (_meta!.currentPage ?? 1) + 1);
  }

  Future<void> _loadDetails({int page = 1}) async {
    final id = widget.cashRegister.id;
    if (id == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'ID кассы не найден';
      });
      return;
    }

    setState(() {
      if (page == 1) {
        _isLoading = true;
        _errorMessage = null;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      final response = await _apiService.getCashRegisterDetails(
        id,
        page: page,
        perPage: 20,
      );
      if (!mounted) return;
      setState(() {
        _details = response.cashRegister;
        _meta = response.meta;
        if (page == 1) {
          _history = response.checkingAccounts;
        } else {
          _history = [..._history, ...response.checkingAccounts];
        }
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '—';
    try {
      return DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(raw).toLocal());
    } catch (_) {
      return raw;
    }
  }

  String _operationTypeLabel(
    AppLocalizations localizations,
    CashRegisterHistoryItem item,
  ) {
    final type = item.operationType;
    if (type == 'send_another_cash_register') {
      return item.isIncome
          ? localizations.translate('receive_another_cash_register')
          : localizations.translate('send_another_cash_register');
    }

    const localeKeys = {
      'client_payment': 'client_payment',
      'other_incomes': 'other_income',
      'other_income': 'other_income',
      'return_supplier': 'supplier_return',
      'supplier_return': 'supplier_return',
      'other_expenses': 'other_expenses',
      'supplier_payment': 'supplier_payment',
      'client_return': 'client_return',
      'salary_payment': 'salary_payment',
    };

    final key = localeKeys[type];
    if (key != null) return localizations.translate(key);
    if (type == null || type.isEmpty) {
      return localizations.translate('not_specified');
    }
    return type;
  }

  String get _registerName {
    final fromApi = _details?.name?.trim();
    if (fromApi != null && fromApi.isNotEmpty) return fromApi;
    return widget.cashRegister.name?.trim().isNotEmpty == true
        ? widget.cashRegister.name!
        : '—';
  }

  String get _currencyLabel {
    final fromApi = _details?.currencyLabel;
    if (fromApi != null && fromApi.isNotEmpty) return fromApi;
    return widget.cashRegister.currencyName?.trim().isNotEmpty == true
        ? widget.cashRegister.currencyName!
        : '';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: colors.surfacePrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colors.iconPrimary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          localizations.translate('cash_balance'),
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: _buildBody(localizations),
    );
  }

  Widget _buildBody(AppLocalizations localizations) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: colors.textPrimary),
      );
    }

    if (_errorMessage != null && _history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: colors.error),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: textStyles.bodyMd.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadDetails(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.buttonPrimaryBg,
                  foregroundColor: colors.buttonPrimaryFg,
                  elevation: 0,
                ),
                child: Text(localizations.translate('retry')),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadDetails(),
      color: colors.textPrimary,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSummaryCard(localizations),
                _buildHistoryHeader(localizations),
                if (_history.isEmpty)
                  _buildEmptyHistory(localizations)
                else
                  ..._history.map(
                    (item) => _buildHistoryCard(localizations, item),
                  ),
                if (_isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(AppLocalizations localizations) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    final balance = widget.cashRegister.balance ?? 0;
    final isPositive = balance >= 0;
    final currency = _currencyLabel;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfacePrimary.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: context.appShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.translate('cash_register_column').toUpperCase(),
            style: textStyles.bodySm.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _registerName,
            style: textStyles.titleMd.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            localizations.translate('cash_balance').toUpperCase(),
            style: textStyles.bodySm.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            [
              parseNumberToString(balance, nullValue: '0'),
              if (currency.isNotEmpty) currency,
            ].join(' '),
            style: textStyles.titleMd.copyWith(
              fontWeight: FontWeight.w700,
              color: isPositive ? colors.success : colors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryHeader(AppLocalizations localizations) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    final total = _meta?.total ?? _history.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              localizations.translate('cash_register_history').toUpperCase(),
              style: textStyles.bodySm.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Text(
            '$total ${localizations.translate('quantity')}',
            style: textStyles.bodySm.copyWith(color: colors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistory(AppLocalizations localizations) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: colors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            localizations.translate('no_cash_history'),
            textAlign: TextAlign.center,
            style: textStyles.bodyMd.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(
    AppLocalizations localizations,
    CashRegisterHistoryItem item,
  ) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    final isIncome = item.isIncome;
    final amountPrefix = isIncome ? '+' : '-';
    final amountColor = isIncome ? colors.success : colors.error;
    final typeLabel = (item.type ?? '').toUpperCase();
    final comment = item.comment?.trim();
    final author = item.author?.displayName ?? '';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfacePrimary.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: context.appShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '#${item.docNumber ?? item.id ?? '—'}',
                  style: textStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (typeLabel.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: amountColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    typeLabel,
                    style: textStyles.bodySm.copyWith(
                      fontWeight: FontWeight.w700,
                      color: amountColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatDate(item.date),
            style: textStyles.bodySm.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            _operationTypeLabel(localizations, item),
            style: textStyles.bodyMd.copyWith(color: colors.textPrimary),
          ),
          if (author.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              author,
              style: textStyles.bodySm.copyWith(color: colors.textSecondary),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            '$amountPrefix${parseNumberToString(item.amountValue, nullValue: '0')} $_currencyLabel',
            style: textStyles.bodyMd.copyWith(
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
          if (comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              comment,
              style: textStyles.bodySm.copyWith(color: colors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
