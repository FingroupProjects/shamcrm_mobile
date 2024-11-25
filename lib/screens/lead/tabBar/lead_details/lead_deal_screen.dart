import 'package:crm_task_manager/bloc/lead_deal/lead_deal_bloc.dart';
import 'package:crm_task_manager/bloc/lead_deal/lead_deal_event.dart';
import 'package:crm_task_manager/bloc/lead_deal/lead_deal_state.dart';
import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/models/lead_deal_model.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details_screen.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/delete_lead_deal.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_deal_add_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class DealsWidget extends StatefulWidget {
  final int leadId;

  DealsWidget({required this.leadId});

  @override
  _DealsWidgetState createState() => _DealsWidgetState();
}

class _DealsWidgetState extends State<DealsWidget> {
  List<LeadDeal> deals = [];
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    context.read<LeadDealsBloc>().add(FetchLeadDeals(widget.leadId));
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
      context
          .read<LeadDealsBloc>()
          .add(FetchMoreLeadDeals(widget.leadId, (deals.length / 20).ceil()));
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
          return Center(child: Text(state.message));
        }

        return _buildDealsList(deals);
      },
    );
  }

  Widget _buildDealsList(List<LeadDeal> deals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleRow('Сделки'),
        SizedBox(height: 8),
        if (deals.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              decoration: TaskCardStyles.taskCardDecoration,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Пока здесь нет сделок',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: Color(0xff1E2E52),
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
    final formattedDate = deal.startDate != null
        ? DateFormat('dd-MM-yyyy HH:mm').format(DateTime.parse(deal.startDate!))
        : 'Не указано';

    return GestureDetector(
      onTap: () {
        _navigateToDealDetails(deal);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          decoration: TaskCardStyles.taskCardDecoration,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Image.asset(
                  'assets/icons/MyNavBar/deal_ON.png',
                  width: 24,
                  height: 24,
                  color: Color(0xff1E2E52),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deal.name,
                        style: TaskCardStyles.titleStyle,
                      ),
                      SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: TaskCardStyles.priorityStyle.copyWith(
                          color: Color(0xff1E2E52),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Color(0xff1E2E52)),
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
          dealCustomFields: defaultCustomFields,
        ),
      ),
    );
  }

  Row _buildTitleRow(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TaskCardStyles.titleStyle.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LeadDealAddScreen(leadId: widget.leadId),
                    ),
                  );
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            backgroundColor: Color(0xff1E2E52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Добавить',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  //   void _showAddNoteDialog() {
  //   showModalBottomSheet(
  //     context: context,
  //     backgroundColor: Colors.white,
  //     builder: (BuildContext context) {
  //       return CreateNotesDialog(leadId: widget.leadId);
  //     },
  //   );
  // }

  // void _showDeleteDealDialog(Deal deal) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => DeleteDealDialog(dealId: deal.id),
  //   );
  // }
}
