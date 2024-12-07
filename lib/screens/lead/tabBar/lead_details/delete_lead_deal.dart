import 'package:crm_task_manager/bloc/deal/deal_bloc.dart'; // Путь к bloc для сделок
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/lead_deal/lead_deal_bloc.dart';
import 'package:crm_task_manager/bloc/lead_deal/lead_deal_event.dart';
import 'package:crm_task_manager/bloc/lead_deal/lead_deal_state.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeleteDealDialog extends StatelessWidget {
  final int dealId;
  final int leadId;

  DeleteDealDialog({required this.dealId, required this.leadId});

  @override
  Widget build(BuildContext context) {
    return BlocListener<LeadDealsBloc, LeadDealsState>(
        listener: (context, state) {
          if (state is LeadDealsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${state.message}',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.red,
                elevation: 3,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            );
          }
        },
        child: AlertDialog(
          backgroundColor: Colors.white,
          title: Center(
            child: Text(
              'Удалить сделку',
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52),
              ),
            ),
          ),
          content: Text(
            'Вы уверены, что хотите удалить эту сделку?',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w500,
              color: Color(0xff1E2E52),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: CustomButton(
                    buttonText: 'Отмена',
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    buttonColor: Colors.red,
                    textColor: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    buttonText: 'Удалить',
                    onPressed: () {
                      context.read<DealBloc>().add(DeleteDeal(dealId));
                      Navigator.of(context).pop();

                      context.read<LeadDealsBloc>().add(FetchLeadDeals(leadId));
                    },
                    buttonColor: Color(0xff1E2E52),
                    textColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ));
  }
}
