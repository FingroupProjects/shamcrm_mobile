import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/article_bloc/expense_article_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/article_bloc/expense_article_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/article_bloc/expense_article_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ArticleWidget extends StatefulWidget {
  final String? selectedArticle;
  final ValueChanged<String?> onChanged;

  ArticleWidget({required this.selectedArticle, required this.onChanged});

  @override
  _ArticleWidgetState createState() => _ArticleWidgetState();
}

class _ArticleWidgetState extends State<ArticleWidget> {
  ArticleGood? selectedArticleData;
  String? _autoSelectedArticleId;

  @override
  void initState() {
    super.initState();
    context.read<ExpenseArticleBloc>().add(FetchArticle());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return BlocListener<ExpenseArticleBloc, ExpenseArticleState>(
      listener: (context, state) {
        if (state is ArticleError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate(state.message),
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
              backgroundColor: colors.error,
              elevation: 3,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
      child: BlocBuilder<ExpenseArticleBloc, ExpenseArticleState>(
        builder: (context, state) {
          final isLoading = state is ArticleLoading;

          // Обновляем данные при успешной загрузке
          if (state is ArticleLoaded) {
            List<ArticleGood> articleList = state.articleList;

            if (widget.selectedArticle != null && articleList.isNotEmpty) {
              try {
                selectedArticleData = articleList.firstWhere(
                  (article) => article.id.toString() == widget.selectedArticle,
                );
              } catch (e) {
                selectedArticleData = null;
              }
            }

            if (articleList.length == 1 &&
                (widget.selectedArticle == null ||
                    selectedArticleData == null) &&
                _autoSelectedArticleId != articleList.first.id.toString()) {
              final singleArticle = articleList.first;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                widget.onChanged(singleArticle.id.toString());
                setState(() {
                  selectedArticleData = singleArticle;
                  _autoSelectedArticleId = singleArticle.id.toString();
                });
              });
            }
          }

          // Всегда отображаем поле
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.translate('article'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                child: CustomDropdown<ArticleGood>.search(
                  closeDropDownOnClearFilterSearch: true,
                  items: state is ArticleLoaded ? state.articleList : [],
                  searchHintText:
                      AppLocalizations.of(context)!.translate('search'),
                  overlayHeight: 400,
                  enabled: !isLoading, // ← Блокируем при загрузке
                  decoration: CustomDropdownDecoration(
                    closedFillColor: colors.surfaceElevated,
                    expandedFillColor: colors.surfaceElevated,
                    closedBorder: Border.all(
                      color: colors.borderSubtle,
                      width: 1,
                    ),
                    closedBorderRadius: BorderRadius.circular(12),
                    expandedBorder: Border.all(
                      color: colors.borderSubtle,
                      width: 1,
                    ),
                    expandedBorderRadius: BorderRadius.circular(12),
                    listItemDecoration: ListItemDecoration(
                      splashColor:
                          colors.buttonPrimaryBg.withValues(alpha: 0.10),
                      highlightColor:
                          colors.buttonPrimaryBg.withValues(alpha: 0.12),
                      selectedColor: colors.surfaceElevated,
                    ),
                    searchFieldDecoration: SearchFieldDecoration(
                      fillColor: colors.surfaceElevated,
                      hintStyle: TextStyle(
                        color: colors.textSecondary,
                        fontFamily: 'Gilroy',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      textStyle: TextStyle(
                        color: colors.textPrimary,
                        fontFamily: 'Gilroy',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 20,
                        color: colors.textSecondary,
                      ),
                      suffixIcon: (onClear) => IconButton(
                        onPressed: onClear,
                        icon: Icon(Icons.close,
                            size: 18, color: colors.textSecondary),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colors.borderSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colors.buttonPrimaryBg),
                      ),
                    ),
                  ),
                  listItemBuilder: (context, item, isSelected, onItemSelect) {
                    return Text(
                      item.name ?? '',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                  headerBuilder: (context, selectedItem, enabled) {
                    // ← Показываем загрузку в центре
                    if (isLoading) {
                      return const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xff1E2E52)),
                          ),
                        ),
                      );
                    }

                    return Text(
                      selectedItem?.name ??
                          AppLocalizations.of(context)!
                              .translate('select_article'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: colors.textPrimary,
                      ),
                    );
                  },
                  hintBuilder: (context, hint, enabled) {
                    // ← Загрузка когда ничего не выбрано
                    if (isLoading) {
                      return const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xff1E2E52)),
                          ),
                        ),
                      );
                    }

                    return Text(
                      AppLocalizations.of(context)!.translate('select_article'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: colors.textPrimary,
                      ),
                    );
                  },
                  // ← Загрузка в открытом списке
                  noResultFoundBuilder: (context, text) {
                    if (isLoading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xff1E2E52)),
                          ),
                        ),
                      );
                    }
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          AppLocalizations.of(context)!.translate('no_results'),
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Gilroy',
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                  excludeSelected: false,
                  initialItem: (state is ArticleLoaded &&
                          state.articleList.contains(selectedArticleData))
                      ? selectedArticleData
                      : null,
                  validator: (value) {
                    if (value == null) {
                      return AppLocalizations.of(context)!
                          .translate('field_required_project');
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (value != null) {
                      widget.onChanged(value.id.toString());
                      setState(() {
                        selectedArticleData = value;
                      });
                      FocusScope.of(context).unfocus();
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
