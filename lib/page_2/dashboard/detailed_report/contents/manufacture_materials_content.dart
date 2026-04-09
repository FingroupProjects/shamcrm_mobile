import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/manufacture_materials/sales_dashboard_manufacture_materials_bloc.dart';
import 'package:crm_task_manager/models/page_2/dashboard/manufacture_report_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/global_fun.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManufactureMaterialsContent extends StatelessWidget {
  const ManufactureMaterialsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesDashboardManufactureMaterialsBloc,
        SalesDashboardManufactureMaterialsState>(
      builder: (context, state) {
        if (state is SalesDashboardManufactureMaterialsLoading) {
          return const _ManufactureMaterialsLoading();
        }
        if (state is SalesDashboardManufactureMaterialsError) {
          return _ManufactureMaterialsError(
            message: state.message,
            onRetry: () {
              context
                  .read<SalesDashboardManufactureMaterialsBloc>()
                  .add(const LoadManufactureMaterialsReport());
            },
          );
        }
        if (state is SalesDashboardManufactureMaterialsLoaded) {
          if (state.result.data.isEmpty) {
            return _ManufactureMaterialsEmpty(
              titleKey: 'no_manufacture_materials_data',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.result.data.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = state.result.data[index];
              return _ManufactureMaterialsCard(item: item);
            },
          );
        }
        return _ManufactureMaterialsEmpty(
          titleKey: 'no_manufacture_materials_data',
        );
      },
    );
  }
}

class _ManufactureMaterialsCard extends StatelessWidget {
  final ManufactureMaterialsReportItem item;

  const _ManufactureMaterialsCard({required this.item});

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
          Text(
            item.rawMaterial,
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xff1E2E52),
            ),
          ),
          const SizedBox(height: 12),
          _ReportLine(
            label: localizations.translate('quantity_used'),
            value: '${_formatNumber(item.quantityUsed)} ${item.unit}',
          ),
          _ReportLine(
            label: localizations.translate('price_without_dots'),
            value: parseNumberToString(item.price.toString()),
          ),
          _ReportLine(
            label: localizations.translate('sum_without_dots'),
            value: parseNumberToString(item.sum.toString()),
            isHighlighted: true,
          ),
        ],
      ),
    );
  }
}

class _ManufactureMaterialsLoading extends StatelessWidget {
  const _ManufactureMaterialsLoading();

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

class _ManufactureMaterialsEmpty extends StatelessWidget {
  final String titleKey;

  const _ManufactureMaterialsEmpty({required this.titleKey});

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
              Icons.science_outlined,
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

class _ManufactureMaterialsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ManufactureMaterialsError({
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
