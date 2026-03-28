import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/manufacture_goods/sales_dashboard_manufacture_goods_bloc.dart';
import 'package:crm_task_manager/models/page_2/dashboard/manufacture_report_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/global_fun.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManufactureGoodsContent extends StatelessWidget {
  const ManufactureGoodsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesDashboardManufactureGoodsBloc,
        SalesDashboardManufactureGoodsState>(
      builder: (context, state) {
        if (state is SalesDashboardManufactureGoodsLoading) {
          return const _ManufactureReportLoading();
        }
        if (state is SalesDashboardManufactureGoodsError) {
          return _ManufactureReportError(
            message: state.message,
            onRetry: () {
              context
                  .read<SalesDashboardManufactureGoodsBloc>()
                  .add(const LoadManufactureGoodsReport());
            },
          );
        }
        if (state is SalesDashboardManufactureGoodsLoaded) {
          if (state.result.data.isEmpty) {
            return _ManufactureReportEmpty(
              titleKey: 'no_manufacture_goods_data',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.result.data.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = state.result.data[index];
              return _ManufactureGoodsCard(item: item);
            },
          );
        }
        return _ManufactureReportEmpty(titleKey: 'no_manufacture_goods_data');
      },
    );
  }
}

class _ManufactureGoodsCard extends StatelessWidget {
  final ManufactureGoodsReportItem item;

  const _ManufactureGoodsCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffF6F8FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.good,
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff1E2E52),
                  ),
                ),
              ),
              Text(
                item.date,
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 13,
                  color: Color(0xff64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ReportLine(
            label: localizations.translate('document_number'),
            value: item.document,
          ),
          _ReportLine(
            label: localizations.translate('quantity'),
            value: '${_formatNumber(item.quantity)} ${item.unit}',
          ),
          _ReportLine(
            label: localizations.translate('cost_price_per_unit'),
            value: parseNumberToString(item.costPricePerUnit.toString()),
          ),
          _ReportLine(
            label: localizations.translate('total_cost'),
            value: parseNumberToString(item.totalCost.toString()),
            isHighlighted: true,
          ),
          _ReportLine(
            label: localizations.translate('author'),
            value: item.author,
          ),
        ],
      ),
    );
  }
}

class _ManufactureReportLoading extends StatelessWidget {
  const _ManufactureReportLoading();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xff1E2E52)),
          const SizedBox(height: 16),
          Text(
            localizations.translate('loading_data'),
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              color: Color(0xff64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManufactureReportEmpty extends StatelessWidget {
  final String titleKey;

  const _ManufactureReportEmpty({required this.titleKey});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.precision_manufacturing_outlined,
              size: 64,
              color: Color(0xff99A4BA),
            ),
            const SizedBox(height: 16),
            Text(
              localizations.translate('no_data_to_display'),
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localizations.translate(titleKey),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 14,
                color: Color(0xff64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManufactureReportError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ManufactureReportError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xffFEF2F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffFECACA)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Color(0xffEF4444),
              ),
              const SizedBox(height: 16),
              Text(
                localizations.translate('error_loading_dialog'),
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff1E2E52),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 14,
                  color: Color(0xff64748B),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff1E2E52),
                  foregroundColor: Colors.white,
                ),
                child: Text(localizations.translate('retry')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportLine extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;

  const _ReportLine({
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 14,
                color: Color(0xff64748B),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 14,
                fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
                color: const Color(0xff1E2E52),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(2);
}
