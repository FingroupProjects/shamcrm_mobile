import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/models/page_2/openings/client_openings_model.dart';
import '../../../../bloc/page_2_BLOC/openings/client/client_openings_bloc.dart';
import '../../../../bloc/page_2_BLOC/openings/client/client_dialog_bloc.dart';
import '../../../../bloc/page_2_BLOC/openings/client/client_dialog_event.dart';
import '../../../../bloc/page_2_BLOC/openings/client/client_dialog_state.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import 'add_client_opening_screen.dart';

class CreateClientOpeningDialog extends StatelessWidget {
  const CreateClientOpeningDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // Получаем оригинальный блок для передачи в AddClientOpeningScreen
    final clientOpeningsBloc = context.read<ClientOpeningsBloc>();
    
    return BlocProvider(
      create: (context) => ClientDialogBloc()..add(LoadLeadsForDialog()),
      child: ClientLeadsDialog(
        clientOpeningsBloc: clientOpeningsBloc,
      ),
    );
  }
}

class ClientLeadsDialog extends StatelessWidget {
  final ClientOpeningsBloc clientOpeningsBloc;
  
  const ClientLeadsDialog({
    super.key,
    required this.clientOpeningsBloc,
  });

  String _translate(BuildContext context, String key, String fallback) {
    return AppLocalizations.of(context)?.translate(key) ?? fallback;
  }

  Widget _buildLeadsList(BuildContext context, List<ClientOpening> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Отображаем список клиентов/лидов
        if (items.isEmpty)
          Container(
            width: double.infinity,
            height: 350,
            child: Center(child:
                Text(
                  _translate(context, 'no_data_to_display', 'Нет данных для отображения'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff475569),
                  ),
                ),
            ),
          )
        else
          ...items.map((item) => _buildLeadCard(context, item)).toList(),
      ],
    );
  }

  Widget _buildLeadCard(BuildContext context, ClientOpening item) {
    return GestureDetector(
      onTap: () {
        // Закрываем диалог
        Navigator.pop(context);
        
        // Открываем экран добавления с существующим блоком
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (newContext) => BlocProvider.value(
              value: clientOpeningsBloc,
              child: AddClientOpeningScreen(
                clientName: item.counterparty?.name ?? 'Неизвестный клиент',
                leadId: item.id ?? 0,
              ),
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xffE2E8F0),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.counterparty?.name ?? 'Неизвестный клиент',
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52),
              ),
            ),
            if ( item.counterparty?.phone != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  item.counterparty?.phone?? '',
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xff64748B),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        constraints: BoxConstraints(
          minHeight: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 420,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff1E2E52).withOpacity(0.15),
              spreadRadius: 0,
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff1E2E52), Color(0xff2C3E68)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.people_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _translate(context, 'select_client', 'Выберите клиента'),
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Flexible(
              child: BlocBuilder<ClientDialogBloc, ClientDialogState>(
                builder: (context, state) {
                  if (state is ClientDialogLoading) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: Color(0xff1E2E52),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _translate(context, 'loading_data_dialog', 'Загрузка данных...'),
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

                  if (state is ClientDialogError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Color(0xffEF4444),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _translate(context, 'error_loading_dialog', 'Ошибка загрузки'),
                              style: const TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xff1E2E52),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 14,
                                color: Color(0xff64748B),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                context.read<ClientDialogBloc>().add(LoadLeadsForDialog());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff1E2E52),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                _translate(context, 'retry_dialog', 'Повторить'),
                                style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state is ClientDialogLoaded) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: _buildLeadsList(context, state.leads),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

