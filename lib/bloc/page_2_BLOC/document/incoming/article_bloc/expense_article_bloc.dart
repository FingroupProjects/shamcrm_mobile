import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/article_bloc/expense_article_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/article_bloc/expense_article_state.dart';

class ExpenseArticleBloc extends Bloc<ExpenseArticleEvent, ExpenseArticleState> {
  final ApiService apiService;
  bool allArticleFetched = false;

  ExpenseArticleBloc(this.apiService) : super(ArticleInitial()) {
    on<FetchArticle>(_fetchArticle);
  }

  Future<void> _fetchArticle(
      FetchArticle event, Emitter<ExpenseArticleState> emit) async {
    emit(ArticleLoading());

    if (await _checkInternetConnection()) {
      try {
        final articleList = await apiService.getAllExpenseArticles();
        allArticleFetched = articleList.isEmpty;
        emit(ArticleLoaded(articleList));
      } catch (e) {
        //print('Ошибка при загрузке статей!'); // For debugging
        emit(ArticleError('Не удалось загрузить список статей!'));
      }
    } else {
      emit(ArticleError('Нет подключения к интернету'));
    }
  }

  // Method to check internet connection
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }
}

