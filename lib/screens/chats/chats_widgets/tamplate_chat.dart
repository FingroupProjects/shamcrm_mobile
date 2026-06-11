import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/bloc/chats/template_bloc/template_bloc.dart';
import 'package:crm_task_manager/bloc/chats/template_bloc/template_state.dart' show TemplateState, TemplateLoading, TemplateLoaded, TemplateError;
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TemplateSuggestions extends StatelessWidget {
  final String query;
  final Function(String) onTemplateSelected;

  const TemplateSuggestions({
    Key? key,
    required this.query,
    required this.onTemplateSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TemplateBloc, TemplateState>(
      builder: (context, state) {
        if (state is TemplateLoading) {
          return Center(child: CircularProgressIndicator(color: context.appColors.buttonPrimaryBg));
        } else if (state is TemplateLoaded) {
          final templates = state.filteredTemplates.isNotEmpty
              ? state.filteredTemplates
              : state.templates;

          return Container(
            constraints: BoxConstraints(maxHeight: 200),
            width: double.infinity,
            decoration: BoxDecoration(
              color: context.appColors.surfacePrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: templates.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      AppLocalizations.of(context)!.translate('no_templates_found'),
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: templates.length,
                    itemBuilder: (context, index) {
                      final template = templates[index];
                      return Column(
                        children: [
                          ListTile(
                            title: Text(
                              template.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w500,
                                color: context.appColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              template.body,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w400,
                                color: context.appColors.textSecondary,
                              ),
                            ),
                            onTap: () {
                              onTemplateSelected(template.body);
                            },
                          ),
                          if (index < templates.length - 1)
                            Divider(thickness: 0.5, height: 0.5, color: context.appColors.borderSubtle),
                        ],
                      );
                    },
                  ),
          );
        } else if (state is TemplateError) {
          return Padding(
            padding: EdgeInsets.all(16),
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
        return SizedBox.shrink();
      },
    );
  }
}
