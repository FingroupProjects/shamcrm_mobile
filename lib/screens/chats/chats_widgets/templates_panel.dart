import 'package:crm_task_manager/bloc/chats/template_bloc/template_bloc.dart';
import 'package:crm_task_manager/bloc/chats/template_bloc/template_event.dart';
import 'package:crm_task_manager/bloc/chats/template_bloc/template_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/global_fun.dart' show stripHtmlTags;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class TemplatesPanel extends StatefulWidget {
  final Function(String) onTemplateSelected;

  const TemplatesPanel({super.key, required this.onTemplateSelected});

  @override
  _TemplatesPanelState createState() => _TemplatesPanelState();
}

class _TemplatesPanelState extends State<TemplatesPanel> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _animation = Tween<Offset>(
      begin: Offset(0.0, 1.0),
      end: Offset(0.0, 0.0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
    context.read<TemplateBloc>().add(FetchTemplates());
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('TemplatesPanel: Building panel');
    final localizations = AppLocalizations.of(context)!;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SlideTransition(
      position: _animation,
      child: Container(
        color: context.appColors.overlay.withValues(alpha: 0.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                left: 12,
                right: 12,
                bottom: 12 + bottomInset,
              ),
              child: Material(
                color: context.appColors.overlay.withValues(alpha: 0.0),
                elevation: 10,
                shadowColor: context.appColors.shadow.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 520),
                    decoration: BoxDecoration(
                      color: context.appColors.surfacePrimary,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BlocBuilder<TemplateBloc, TemplateState>(
                          builder: (context, state) {
                            final totalCount = state is TemplateLoaded
                                ? state.templates.length
                                : 0;

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: context.appColors.buttonPrimaryBg,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: context.appColors.textInverse.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.grid_view_rounded,
                                      color: context.appColors.textInverse,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      localizations.translate('templates'),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontFamily: 'Gilroy',
                                        fontWeight: FontWeight.w600,
                                        color: context.appColors.textInverse,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: context.appColors.textInverse.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '$totalCount',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'Gilroy',
                                        fontWeight: FontWeight.w600,
                                        color: context.appColors.textInverse,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: () {
                                      setState(() {
                                        _isSearching = !_isSearching;
                                      });
                                      if (!_isSearching) {
                                        _searchController.clear();
                                        context
                                            .read<TemplateBloc>()
                                            .add(FilterTemplates(''));
                                      } else {
                                        _searchFocusNode.requestFocus();
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: Icon(
                                        _isSearching
                                            ? Icons.close_rounded
                                            : Icons.search_rounded,
                                        color: context.appColors.textInverse,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        AnimatedCrossFade(
                          firstChild: const SizedBox.shrink(),
                          secondChild: Container(
                            color: context.appColors.backgroundSecondary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              onChanged: (value) {
                                context
                                    .read<TemplateBloc>()
                                    .add(FilterTemplates(value));
                              },
                              decoration: InputDecoration(
                                hintText: localizations.translate('search'),
                                hintStyle: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 14,
                                  color: context.appColors.textSecondary,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: context.appColors.textSecondary,
                                ),
                                filled: true,
                                fillColor: context.appColors.surfacePrimary,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 14,
                                  color: context.appColors.textPrimary,
                              ),
                            ),
                          ),
                          crossFadeState: _isSearching
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 200),
                        ),
                        Expanded(
                          child: BlocBuilder<TemplateBloc, TemplateState>(
                            builder: (context, state) {
                              if (state is TemplateLoading) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              } else if (state is TemplateLoaded) {
                                final isFiltering =
                                    _searchController.text.trim().isNotEmpty;
                                final templates = isFiltering
                                    ? state.filteredTemplates
                                    : state.templates;

                                if (templates.isEmpty) {
                                  return Center(
                                    child: Text(
                                      isFiltering
                                          ? localizations
                                              .translate('no_templates_found')
                                          : localizations
                                              .translate('no_templates'),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'Gilroy',
                                        fontWeight: FontWeight.w500,
                                        color: context.appColors.textSecondary,
                                      ),
                                    ),
                                  );
                                }

                                return ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 8),
                                  itemCount: templates.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 4),
                                  itemBuilder: (context, index) {
                                    final template = templates[index];
                                    final previewText =
                                        stripHtmlTags(template.body).trim();
                                    return InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () {
                                        debugPrint(
                                            'TemplatesPanel: Template selected: ${template.body}');
                                        widget.onTemplateSelected(template.body);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: context.appColors.backgroundSecondary,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              margin: const EdgeInsets.only(
                                                  top: 6),
                                              decoration: BoxDecoration(
                                                color: context.appColors.buttonPrimaryBg,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    template.title,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontFamily: 'Gilroy',
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: context.appColors.textPrimary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    previewText,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontFamily: 'Gilroy',
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: context.appColors.textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              } else if (state is TemplateError) {
                                return Center(
                                  child: Text(
                                    state.message,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Gilroy',
                                      fontWeight: FontWeight.w500,
                                      color: context.appColors.error,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
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
      ),
    );
  }
}
