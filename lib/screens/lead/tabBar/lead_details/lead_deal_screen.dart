import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/lead_by_id/leadById_bloc.dart';
import 'package:crm_task_manager/bloc/lead_by_id/leadById_state.dart';
import 'package:crm_task_manager/bloc/lead_deal/lead_deal_bloc.dart';
import 'package:crm_task_manager/bloc/lead_deal/lead_deal_event.dart';
import 'package:crm_task_manager/bloc/lead_deal/lead_deal_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/deal/deal_model.dart';
import 'package:crm_task_manager/models/lead/lead_deal_model.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details_screen.dart';
import 'package:crm_task_manager/screens/lead/lead_cache.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/delete_lead_deal.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_deal_add_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class DealsWidget extends StatefulWidget {
  final int leadId;
  final bool autoFetch;

  const DealsWidget({Key? key, required this.leadId, this.autoFetch = true})
      : super(key: key);

  @override
  _DealsWidgetState createState() => _DealsWidgetState();
}

class _DealsWidgetState extends State<DealsWidget> {
  List<LeadDeal> deals = [];
  late ScrollController _scrollController;
  bool _canCreateDeal = false;
  // bool _canUpdateDeal = false;
  bool _canDeleteDeal = false;
  final ApiService _apiService = ApiService();

  BoxDecoration _cardDecoration(BuildContext context) => BoxDecoration(
        color: context.appColors.surfacePrimary.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.appColors.textInverse.withValues(alpha: 0.16),
        ),
      );

  Future<void> _checkPermissions() async {
    final canCreate = await _apiService.hasPermission('deal.create');
    // final canUpdate = await _apiService.hasPermission('deal.update');
    final canDelete = await _apiService.hasPermission('deal.delete');
    if (!mounted) return;
    setState(() {
      _canCreateDeal = canCreate;
      // _canUpdateDeal = canUpdate;
      _canDeleteDeal = canDelete;
    });
  }

  @override
  void initState() {
    super.initState();
    _checkPermissions(); // Проверяем права пользователя
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    if (widget.autoFetch) {
      context.read<LeadDealsBloc>().add(FetchLeadDeals(widget.leadId));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !context.read<LeadDealsBloc>().allLeadDealsFetched) {
      context.read<LeadDealsBloc>().add(
            FetchMoreLeadDeals(widget.leadId, (deals.length / 20).ceil()),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeadDealsBloc, LeadDealsState>(
      builder: (context, state) {
        if (state is LeadDealsLoading) {
          // return const Center(child: CircularProgressIndicator());
        } else if (state is LeadDealsLoaded) {
          deals = state.deals;
        } else if (state is LeadDealsError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!
                      .translate(state.message), // Локализация сообщения
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: context.appColors.textInverse,
                  ),
                ),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: context.appColors.error,
                elevation: 3,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                duration: Duration(seconds: 3),
              ),
            );
          });
        }

        return _buildDealsList(deals);
      },
    );
  }

  Widget _buildDealsList(List<LeadDeal> deals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleRow(
          AppLocalizations.of(context)!.translate('deal'),
        ),
        SizedBox(height: 8),
        if (deals.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              decoration: _cardDecoration(context),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppLocalizations.of(context)!.translate('empty'),
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color:
                          context.appColors.textInverse.withValues(alpha: 0.72),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          )
        else
          Container(
            height: 300,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: deals.length,
              itemBuilder: (context, index) {
                return _buildDealItem(deals[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDealItem(LeadDeal deal) {
    String formattedDate;

    try {
      formattedDate = (deal.lastseen != null && deal.lastseen!.isNotEmpty)
          ? DateFormat('dd.MM.yyyy').format(DateTime.parse(deal.lastseen!))
          : AppLocalizations.of(context)!.translate('');
    } catch (e) {
      formattedDate = AppLocalizations.of(context)!.translate('');
    }

    return GestureDetector(
      onTap: () {
        _navigateToDealDetails(deal);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          decoration: _cardDecoration(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Image.asset(
                  'assets/icons/MyNavBar/deal_ON.png',
                  width: 24,
                  height: 24,
                  color: context.appColors.buttonPrimaryBg,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deal.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          color: context.appColors.textInverse
                              .withValues(alpha: 0.96),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${AppLocalizations.of(context)!.translate('creation_date_details')} ${formattedDate}',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w500,
                          color: context.appColors.textInverse
                              .withValues(alpha: 0.82),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${AppLocalizations.of(context)!.translate('status_details')} ${deal.dealStatus.title ?? ''}',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w500,
                          color: context.appColors.textInverse
                              .withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_canDeleteDeal)
                  IconButton(
                    icon: Icon(Icons.delete, color: context.appColors.error),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => DeleteDealDialog(
                          dealId: deal.id,
                          leadId: widget.leadId,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToDealDetails(LeadDeal deal) {
    List<DealCustomField> defaultCustomFields = [
      DealCustomField(id: 1, key: '', value: ''),
      DealCustomField(id: 2, key: '', value: ''),
    ];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DealDetailsScreen(
          dealId: deal.id.toString(),
          dealName: deal.name ?? '',
          sum: deal.sum?.toString() ?? '',
          dealStatus: '',
          statusId: 1,
        ),
      ),
    ).then((_) {
      context.read<LeadDealsBloc>().add(FetchLeadDeals(widget.leadId));

      final dealBloc = BlocProvider.of<LeadBloc>(context, listen: false);
      dealBloc.add(FetchLeadStatuses());
    });
  }

  Row _buildTitleRow(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w700,
            color: context.appColors.textInverse.withValues(alpha: 0.96),
          ),
        ),
        if (_canCreateDeal)
          BlocBuilder<LeadByIdBloc, LeadByIdState>(
            builder: (context, state) {
              int? managerId;
              if (state is LeadByIdLoaded) {
                managerId = state.lead.manager?.id;
              }
              return TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LeadDealAddScreen(
                        leadId: widget.leadId,
                        managerId: managerId, // Передаём managerId
                      ),
                    ),
                  ).then((_) async {
                    await LeadCache.clearLeadStatuses();
                    await LeadCache.clearAllLeads();
                    BlocProvider.of<LeadBloc>(context).add(FetchLeadStatuses());
                    BlocProvider.of<DealBloc>(context).add(FetchDealStatuses());
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: context.appColors.buttonPrimaryFg,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  backgroundColor: context.appColors.buttonPrimaryBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.translate('add'),
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                    color: context.appColors.buttonPrimaryFg,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
