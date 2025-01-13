import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManagerFilterPopup extends StatelessWidget {
  final Function(dynamic)? onManagerSelected;

  const ManagerFilterPopup({
    Key? key,
    this.onManagerSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      constraints: BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Выберите менеджера',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E2E52),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, size: 20),
                ),
              ],
            ),
          ),
          Container(
            constraints: BoxConstraints(maxHeight: 300),
            child: BlocBuilder<GetAllManagerBloc, GetAllManagerState>(
              builder: (context, state) {
                if (state is GetAllManagerLoading) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(color: Color(0xff1E2E52))
                    ),
                  );
                } else if (state is GetAllManagerError) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        state.message,
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          color: Colors.red,
                        ),
                      ),
                    ),
                  );
                } else if (state is GetAllManagerSuccess) {
                  final managers = state.dataManager.result;
                  if (managers == null) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Нет доступных менеджеров',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                          ),
                        ),
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: managers.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // Опция "Все" теперь полностью сбрасывает состояние
                        return InkWell(
                          onTap: () {
                            if (onManagerSelected != null) {
                              // Сбрасываем все фильтры и возвращаемся к исходному состоянию
                              onManagerSelected!(null);
                              
                              // Перезагружаем данные через BLoC
                              final leadBloc = BlocProvider.of<LeadBloc>(context);
                              leadBloc.add(FetchLeadStatuses());
                            }
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Color(0xFFEEEEEE),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Text(
                              'Все',
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1E2E52),
                              ),
                            ),
                          ),
                        );
                      }
                      
                      final manager = managers[index - 1];
                      final name = manager.name ?? 'Без имени';
                      return InkWell(
                        onTap: () {
                          if (onManagerSelected != null) {
                            onManagerSelected!(manager);
                          }
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Text(
                            name,
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 14,
                              color: Color(0xFF1E2E52),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
                return Container();
              },
            ),
          ),
        ],
      ),
    );
  }
}