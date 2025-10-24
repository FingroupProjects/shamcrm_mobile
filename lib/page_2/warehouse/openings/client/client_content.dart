import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../custom_widget/animation.dart';
import '../../../../models/page_2/openings/client_openings_model.dart';
import '../../../../bloc/page_2_BLOC/openings/client/client_openings_bloc.dart';
import '../../../../bloc/page_2_BLOC/openings/client/client_openings_event.dart';
import '../../../../bloc/page_2_BLOC/openings/client/client_openings_state.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import 'client_card.dart';
import 'client_details.dart';
import '../opening_delete_dialog.dart';

class ClientContent extends StatefulWidget {
  const ClientContent({super.key});

  @override
  State<ClientContent> createState() => _ClientContentState();
}

class _ClientContentState extends State<ClientContent> {
  Future<void> _onRefresh() async {
    context.read<ClientOpeningsBloc>().add(LoadClientOpenings());
    await context.read<ClientOpeningsBloc>().stream.firstWhere(
          (state) => state is! ClientOpeningsLoading || state is ClientOpeningsLoaded || state is ClientOpeningsError,
    );
  }

  Widget _buildClientList(List<ClientOpening> clients) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xff1E2E52),
      child: ListView.separated(
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: clients.length,
        itemBuilder: (context, index) {
          return ClientCard(
            client: clients[index],
            onClick: (client) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClientOpeningDetailsScreen(
                    opening: client,
                  ),
                ),
              );
            },
            onLongPress: (client) {
              // Handle client long press
            },
            onDelete: (client) {
              final bloc = context.read<ClientOpeningsBloc>();
              showDialog(
                context: context,
                builder: (dialogContext) => OpeningDeleteDialog(
                  openingId: client.id ?? 0,
                  openingType: OpeningType.client,
                  onConfirmDelete: () {
                    bloc.add(
                      DeleteClientOpening(id: client.id ?? 0),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final localizations = AppLocalizations.of(context)!;
    
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 64,
                    color: Color(0xff99A4BA),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizations.translate('no_clients') ?? 'Нет клиентов',
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.translate('no_clients_description') ?? 'Список клиентов пуст',
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 14,
                      color: Color(0xff99A4BA),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: PlayStoreImageLoading(
        size: 80,
      ),
    );
  }

  Widget _buildErrorState(String message) {
    final localizations = AppLocalizations.of(context)!;
    
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xffFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xffFECACA),
                      width: 1,
                    ),
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
                        localizations.translate('error_loading_dialog') ?? 'Ошибка загрузки',
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
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
                        onPressed: () {
                          context.read<ClientOpeningsBloc>().add(LoadClientOpenings());
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
                          localizations.translate('retry') ?? 'Повторить',
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ClientOpeningsBloc, ClientOpeningsState>(
      listener: (context, state) {
        // Обработка операционных ошибок через snackbar
        if (state is ClientOpeningsOperationError) {
          showCustomSnackBar(
            context: context,
            message: state.message,
            isSuccess: false,
          );
        }
      },
      builder: (context, state) {
        // Если это операционная ошибка, показываем предыдущее состояние
        if (state is ClientOpeningsOperationError) {
          state = state.previousState;
        }

        debugPrint("ClientOpeningsState: $state");

        if (state is ClientOpeningsLoading) {
          return _buildLoadingState();
        } else if (state is ClientOpeningsError) {
          return _buildErrorState(state.message);
        } else if (state is ClientOpeningsLoaded) {
          if (state.clients.isEmpty) {
            return _buildEmptyState();
          }
          return _buildClientList(state.clients);
        }

        return _buildEmptyState();
      },
    );
  }
}

// Helper function for snackbar
void showCustomSnackBar({
  required BuildContext context,
  required String message,
  required bool isSuccess,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: isSuccess ? Colors.green : const Color(0xffEF4444),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}