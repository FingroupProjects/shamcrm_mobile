import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';

abstract class ExpenseArticleState {}

class ArticleInitial extends ExpenseArticleState {}

class ArticleLoading extends ExpenseArticleState {}

class ArticleLoaded extends ExpenseArticleState {
  final List<ArticleGood> articleList;

  ArticleLoaded(this.articleList);
}

class ArticleError extends ExpenseArticleState {
  final String message;

  ArticleError(this.message);
}

class ArticleSuccess extends ExpenseArticleState {
  final String message;

  ArticleSuccess(this.message);
}

