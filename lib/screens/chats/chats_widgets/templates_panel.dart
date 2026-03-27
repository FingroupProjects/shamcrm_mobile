import 'package:crm_task_manager/bloc/chats/template_bloc/template_bloc.dart';
import 'package:crm_task_manager/bloc/chats/template_bloc/template_event.dart';
import 'package:crm_task_manager/bloc/chats/template_bloc/template_state.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('TemplatesPanel: Building panel');
    return SlideTransition(
      position: _animation,
      child: Container(
        color: Colors.black.withOpacity(0.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              constraints: BoxConstraints(maxHeight: 500),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate('templates'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Gilroy',
                      color: Color(0xff1E2E52),
                    ),
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: BlocBuilder<TemplateBloc, TemplateState>(
                      builder: (context, state) {
                        if (state is TemplateLoading) {
                          return Center(child: CircularProgressIndicator());
                        } else if (state is TemplateLoaded) {
                          if (state.templates.isEmpty) {
                            return Center(
                              child: Text(
                                AppLocalizations.of(context)!.translate('no_templates'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xff99A4BA),
                                ),
                              ),
                            );
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: state.templates.length,
                            itemBuilder: (context, index) {
                              final template = state.templates[index];
                              return Column(
                                children: [
                                  ListTile(
                                    title: Text(
                                      template.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'Gilroy',
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xff1E2E52),
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
                                        color: Color(0xff99A4BA),
                                      ),
                                    ),
                                    onTap: () {
  debugPrint('TemplatesPanel: Template selected: ${template.body}');
  // НЕ вызываем Navigator.pop() здесь!
  // Только передаем данные через callback
  widget.onTemplateSelected(template.body);
},
                                  ),
                                  if (index < state.templates.length - 1)
                                    Divider(thickness: 0.5, height: 0.5, color: Colors.grey),
                                ],
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
                                color: Colors.red,
                              ),
                            ),
                          );
                        }
                        return SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}