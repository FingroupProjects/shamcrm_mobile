import 'package:crm_task_manager/bloc/call_bloc/operator_bloc/operator_bloc.dart';
import 'package:crm_task_manager/bloc/call_bloc/operator_bloc/operator_event.dart';
import 'package:crm_task_manager/bloc/call_bloc/operator_bloc/operator_state.dart';
import 'package:crm_task_manager/models/page_2/operator_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/page_2/call_center/operator_details.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class CallReportList extends StatefulWidget {
  final String searchQuery;
  final VoidCallback onResetSearch; // Добавляем callback для сброса поиска

  const CallReportList({
    Key? key,
    required this.searchQuery,
    required this.onResetSearch,
  }) : super(key: key);

  @override
  _CallReportListState createState() => _CallReportListState();
}

class _CallReportListState extends State<CallReportList> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OperatorBloc(ApiService())..add(FetchOperators()),
      child: BlocBuilder<OperatorBloc, OperatorState>(
        builder: (context, state) {
          if (state is OperatorLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is OperatorError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.message,
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<OperatorBloc>().add(FetchOperators());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Повторить',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else if (state is OperatorLoaded) {
            final filteredOperators = _getFilteredOperators(state.operators);
            if (filteredOperators.isEmpty && widget.searchQuery.isNotEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Операторы не найдены',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: widget.onResetSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Сбросить поиск',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: filteredOperators.length,
                itemBuilder: (context, index) {
                  final operator = filteredOperators[index];
                  final int rating = operator.operatorAvgRating != null
                      ? operator.operatorAvgRating!.round()
                      : 0; // Обработка null, рейтинг по умолчанию 0
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OperatorDetailsScreen(
                            operatorName: operator.fullName,
                            rating: rating,
                            operatorId: operator.id,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.15),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade100, width: 1),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16.0),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF6C5CE7),
                          child: operator.image.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    operator.image,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Text(
                                      operator.fullName.isNotEmpty
                                          ? operator.fullName.substring(0, 2)
                                          : 'О',
                                      style: const TextStyle(
                                        fontFamily: 'Gilroy',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                              : Text(
                                  operator.fullName.isNotEmpty
                                      ? operator.fullName.substring(0, 2)
                                      : 'О',
                                  style: const TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                        title: Text(
                          operator.fullName,
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              children: List.generate(5, (starIndex) {
                                return Padding(
                                  padding: const EdgeInsets.only(left: 2.0),
                                  child: Image.asset(
                                    starIndex < rating
                                        ? 'assets/icons/AppBar/star_on.png'
                                        : 'assets/icons/AppBar/star_off.png',
                                    width: 16,
                                    height: 16,
                                  ),
                                );
                              }),
                            ),
                            if (rating == 0) // Добавляем текст, если рейтинг отсутствует
                              const Padding(
                                padding: EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Рейтинг отсутствует',
                                  style: TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  List<Operator> _getFilteredOperators(List<Operator> operators) {
    if (widget.searchQuery.isEmpty) {
      return operators;
    }
    return operators.where((operator) {
      final fullName = operator.fullName.toLowerCase();
      final query = widget.searchQuery.toLowerCase();
      return fullName.contains(query);
    }).toList();
  }
}