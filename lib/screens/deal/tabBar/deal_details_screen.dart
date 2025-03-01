import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/deal_by_id/dealById_bloc.dart';
import 'package:crm_task_manager/bloc/deal_by_id/dealById_event.dart';
import 'package:crm_task_manager/bloc/deal_by_id/dealById_state.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/main.dart';
import 'package:crm_task_manager/models/dealById_model.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_delete.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details/dropdown_history.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details/deal_task_screen.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details/history_dialog.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_edit_screen.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;

import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class DealDetailsScreen extends StatefulWidget {
  final String dealId;
  final String dealName;
  final String? startDate;
  final String? endDate;
  final String sum;
  final String dealStatus;
  final int statusId;
  final String? manager;
  final String? currency;
  final String? lead;
  final int? leadId;
  final String? description;
  final List<DealCustomField> dealCustomFields;

  DealDetailsScreen({
    required this.dealId,
    required this.dealName,
    this.startDate,
    this.endDate,
    required this.sum,
    required this.dealStatus,
    required this.statusId,
    this.manager,
    this.currency,
    this.lead,
    this.leadId,
    this.description,
    required this.dealCustomFields,
  });

  @override
  _DealDetailsScreenState createState() => _DealDetailsScreenState();
}

class _DealDetailsScreenState extends State<DealDetailsScreen> {
  List<Map<String, String>> details = [];
  DealById? currentDeal;
  bool _canEditDeal = false;
  bool _canDeleteDeal = false;
  final ApiService _apiService = ApiService();
  final GlobalKey keyDealEdit = GlobalKey();
  final GlobalKey keyDealTasks = GlobalKey();
  final GlobalKey keyDealHistory = GlobalKey();
  List<TargetFocus> targets = [];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    context
        .read<DealByIdBloc>()
        .add(FetchDealByIdEvent(dealId: int.parse(widget.dealId)));

    // Отложим инициализацию подсказок до построения виджета
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initTargets();
      showTutorial();
    });
  }
// Перемещаем инициализацию целей после построения виджета
void _initTargets() {
  targets = [
    createTarget(
      identify: 'keyDealEdit',
      keyTarget: keyDealEdit,
      title: AppLocalizations.of(context)!.translate('tutorial_deal_edit_title'),
      description: AppLocalizations.of(context)!.translate('tutorial_deal_edit_description'),
      align: ContentAlign.bottom,
      context: context,
    ),
    createTarget(
      identify: 'keyDealTasks',
      keyTarget: keyDealTasks,
      title: AppLocalizations.of(context)!.translate('tutorial_deal_tasks_title'),
      description: AppLocalizations.of(context)!.translate('tutorial_deal_tasks_description'),
      align: ContentAlign.top,
      context: context,
    ),
    createTarget(
      identify: 'keyDealHistory',
      keyTarget: keyDealHistory,
      title: AppLocalizations.of(context)!.translate('tutorial_deal_history_title'),
      description: AppLocalizations.of(context)!.translate('tutorial_deal_history_description'),
      align: ContentAlign.top,
      context: context,
    ),
  ];
}

void showTutorial() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isTutorialShown = prefs.getBool('isTutorialShownDealDetails') ?? false;

  await Future.delayed(const Duration(seconds: 1));

  if (!isTutorialShown)
  {
    TutorialCoachMark(
      targets: targets,
      textSkip: AppLocalizations.of(context)!.translate('tutorial_skip'),
      textStyleSkip: TextStyle(
        color: Colors.white,
        fontFamily: 'Gilroy',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        shadows: [
          Shadow(offset: Offset(-1.5, -1.5), color: Colors.black),
          Shadow(offset: Offset(1.5, -1.5), color: Colors.black),
          Shadow(offset: Offset(1.5, 1.5), color: Colors.black),
          Shadow(offset: Offset(-1.5, 1.5), color: Colors.black),
        ],
      ),
      colorShadow: Color(0xff1E2E52),
      hideSkip: false,
      alignSkip: Alignment.bottomRight,
      focusAnimationDuration: Duration(milliseconds: 300),
      pulseAnimationDuration: Duration(milliseconds: 500),
      onClickTarget: (target) {
        print("Target clicked: \${target.identify}");
      },
      onClickOverlay: (target) {
        print("Overlay clicked: \${target.identify}");
      },
      onSkip: () {
        print(AppLocalizations.of(context)!.translate('tutorial_skip'));
        return true;
      },
      onFinish: () {
        print("Tutorial finished");
        prefs.setBool('isTutorialShownDealDetails', true);
      },
    ).show(context: context);
  }
}

TargetFocus createTarget({
  required String identify,
  required GlobalKey keyTarget,
  required String title,
  required String description,
  required ContentAlign align,
  EdgeInsets? extraPadding,
  SizedBox? extraSpacing,
  required BuildContext context,
}) {
  return TargetFocus(
    identify: identify,
    keyTarget: keyTarget,
    alignSkip: Alignment.bottomRight,
    enableOverlayTab: true,
    shape: ShapeLightFocus.Circle,
    radius: 100,
    paddingFocus: 8,
    contents: [
      TargetContent(
        align: align,
        builder: (context, controller) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Gilroy',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  shadows: [
                    Shadow(offset: Offset(-1.5, -1.5), color: Colors.black),
                    Shadow(offset: Offset(1.5, -1.5), color: Colors.black),
                    Shadow(offset: Offset(1.5, 1.5), color: Colors.black),
                    Shadow(offset: Offset(-1.5, 1.5), color: Colors.black),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  shadows: [
                    Shadow(offset: Offset(-1, -1), color: Colors.black),
                    Shadow(offset: Offset(1, -1), color: Colors.black),
                    Shadow(offset: Offset(1, 1), color: Colors.black),
                    Shadow(offset: Offset(-1, 1), color: Colors.black),
                  ],
                ),
              ),
              extraSpacing ?? SizedBox(height: 20),
            ],
          );
        },
      ),
    ],
  );
}


  void _showFullTextDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  title,
                  style: TextStyle(
                    color: Color(0xff1E2E52),
                    fontSize: 18,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                constraints: BoxConstraints(maxHeight: 400),
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  child: Text(
                    content,
                    textAlign: TextAlign.justify, // Выровнять текст по ширине

                    style: TextStyle(
                      color: Color(0xff1E2E52),
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: CustomButton(
                  buttonText: AppLocalizations.of(context)!.translate('close'),
                  onPressed: () => Navigator.pop(context),
                  buttonColor: Color(0xff1E2E52),
                  textColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _checkPermissions() async {
    final canEdit = await _apiService.hasPermission('deal.update');
    final canDelete = await _apiService.hasPermission('deal.delete');

    setState(() {
      _canEditDeal = canEdit;
      _canDeleteDeal = canDelete;
    });
  }

  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final parsedDate = DateTime.parse(dateString);
      return DateFormat('dd.MM.yyyy').format(parsedDate);
    } catch (e) {
      return AppLocalizations.of(context)!.translate('invalid_format');
    }
  }

  void _updateDetails(DealById deal) {
    currentDeal = deal;
    details = [
      {
        'label': AppLocalizations.of(context)!.translate('name_deal_details'),
        'value': deal.name
      },
      {
        'label': AppLocalizations.of(context)!.translate('lead_deal_card'),
        'value': deal.lead?.name ?? ''
      },
      {
        'label': AppLocalizations.of(context)!.translate('manager_details'),
        'value': deal.manager?.name ?? 'Система'
      },
      {
        'label': AppLocalizations.of(context)!.translate('start_date_details'),
        'value': formatDate(deal.startDate)
      },
      {
        'label': AppLocalizations.of(context)!.translate('end_date_details'),
        'value': formatDate(deal.endDate)
      },
      {
        'label': AppLocalizations.of(context)!.translate('summa_details'),
        'value': deal.sum.toString()
      },
      {
        'label': AppLocalizations.of(context)!.translate('description_details'),
        'value': deal.description ?? ''
      },
      {
        'label': AppLocalizations.of(context)!.translate('author_details'),
        'value': deal.author?.name ?? ''
      },
      {
        'label':
            AppLocalizations.of(context)!.translate('creation_date_details'),
        'value': formatDate(deal.createdAt)
      },
      {
        'label': AppLocalizations.of(context)!.translate('status_history'),
        'value': deal.dealStatus?.title ?? ''
      },
    ];

    for (var field in deal.dealCustomFields) {
      details.add({'label': '${field.key}:', 'value': field.value});
    }
  }

  bool _isTextOverflow(String text, TextStyle style, double maxWidth) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    return textPainter.didExceedMaxLines;
  }

  Widget _buildExpandableText(String label, String value, double maxWidth) {
    final TextStyle style = TextStyle(
      fontSize: 16,
      fontFamily: 'Gilroy',
      fontWeight: FontWeight.w500,
      color: Color(0xff1E2E52),
      backgroundColor: Colors.white,
    );

    return GestureDetector(
      onTap: () => _showFullTextDialog(label.replaceAll(':', ''), value),
      child: Text(
        value,
        style: style.copyWith(
          decoration: TextDecoration.underline,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(
          context, AppLocalizations.of(context)!.translate('view_deal')),
      backgroundColor: Colors.white,
      body: BlocListener<DealByIdBloc, DealByIdState>(
        listener: (context, state) {
          if (state is DealByIdLoaded) {
          } else if (state is DealByIdError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
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
                  backgroundColor: Colors.red,
                  elevation: 3,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  duration: Duration(seconds: 3),
                ),
              );
            });
          }
        },
        child: BlocBuilder<DealByIdBloc, DealByIdState>(
          builder: (context, state) {
            if (state is DealByIdLoading) {
              return Center(
                  child: CircularProgressIndicator(color: Color(0xff1E2E52)));
            } else if (state is DealByIdLoaded) {
              DealById deal = state.deal;
              _updateDetails(deal);
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ListView(
                  children: [
                    _buildDetailsList(),
                    const SizedBox(height: 8),
                    ActionHistoryWidget(dealId: int.parse(widget.dealId)),
                    const SizedBox(height: 16),
                    Container(
                      key: keyDealTasks,
                      child: TasksWidget(dealId: int.parse(widget.dealId)),
                    ),
                  ],
                ),
              );
            } else if (state is DealByIdError) {
              return Center(
                  child: Text(
                      AppLocalizations.of(context)!.translate('error_text')));
            }
            return Center(child: Text(''));
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, String title) {
    return AppBar(
      backgroundColor: Colors.white,
      forceMaterialTransparency: true,
      elevation: 0,
      centerTitle: false,
      leadingWidth: 40,
      leading: Padding(
        padding: const EdgeInsets.only(left: 0),
        child: Transform.translate(
          offset: const Offset(0, -2),
          child: IconButton(
            icon: Image.asset(
              'assets/icons/arrow-left.png',
              width: 24,
              height: 24,
            ),
            onPressed: () {
              Navigator.pop(context, widget.statusId);
            },
          ),
        ),
      ),
      title: Transform.translate(
        offset: const Offset(-10, 0),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
        //в котор
      ),
      actions: [
        if (_canEditDeal || _canDeleteDeal)
          Row(
            key: keyDealEdit, // Add the key for the tutorial target

            mainAxisSize: MainAxisSize.min,
            children: [
              if (_canEditDeal)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  icon: Image.asset(
                    'assets/icons/edit.png',
                    width: 24,
                    height: 24,
                  ),
                  onPressed: () async {
                    if (currentDeal != null) {
                      final startDateString = currentDeal!.startDate != null &&
                              currentDeal!.startDate!.isNotEmpty
                          ? DateFormat('dd/MM/yyyy')
                              .format(DateTime.parse(currentDeal!.startDate!))
                          : null;
                      final endDateString = currentDeal!.endDate != null &&
                              currentDeal!.endDate!.isNotEmpty
                          ? DateFormat('dd/MM/yyyy')
                              .format(DateTime.parse(currentDeal!.endDate!))
                          : null;
                      final createdAtDateString = currentDeal!.createdAt !=
                                  null &&
                              currentDeal!.createdAt!.isNotEmpty
                          ? DateFormat('dd/MM/yyyy')
                              .format(DateTime.parse(currentDeal!.createdAt!))
                          : null;

                      final shouldUpdate = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DealEditScreen(
                            dealId: currentDeal!.id,
                            dealName: currentDeal!.name,
                            statusId: currentDeal!.statusId,
                            manager: currentDeal!.manager != null
                                ? currentDeal!.manager!.id.toString()
                                : '',
                            lead: currentDeal!.lead != null
                                ? currentDeal!.lead!.id.toString()
                                : '',
                            startDate: startDateString,
                            endDate: endDateString,
                            createdAt: createdAtDateString,
                            sum: currentDeal!.sum.toString(),
                            description: currentDeal!.description ?? '',
                            dealCustomFields: currentDeal!.dealCustomFields,
                          ),
                        ),
                      );

                      if (shouldUpdate == true) {
                        context
                            .read<DealByIdBloc>()
                            .add(FetchDealByIdEvent(dealId: currentDeal!.id));
                        context.read<DealBloc>().add(FetchDealStatuses());
                      }
                    }
                  },
                ),
              if (_canDeleteDeal)
                IconButton(
                  padding: EdgeInsets.only(right: 8),
                  constraints: BoxConstraints(),
                  icon: Image.asset(
                    'assets/icons/delete.png',
                    width: 24,
                    height: 24,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => DeleteDealDialog(
                        dealId: currentDeal!.id,
                        leadId: currentDeal!.lead!.id,
                      ),
                    );
                  },
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildDetailsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: details.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: _buildDetailItem(
            details[index]['label']!,
            details[index]['value']!,
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(label),
            SizedBox(width: 8),
            Expanded(
              child: (label.contains(AppLocalizations.of(context)!
                          .translate('name_list')) ||
                      label.contains(AppLocalizations.of(context)!
                          .translate('description_list')))
                  ? _buildExpandableText(label, value, constraints.maxWidth)
                  : (label ==
                              AppLocalizations.of(context)!
                                  .translate('lead_deal_card') &&
                          value.isNotEmpty)
                      ? GestureDetector(
                          onTap: () {
                            if (currentDeal?.lead?.id != null) {
                              navigatorKey.currentState?.push(
                                MaterialPageRoute(
                                  builder: (context) => LeadDetailsScreen(
                                    leadId: currentDeal!.lead!.id.toString(),
                                    leadName: value,
                                    leadStatus: "",
                                    statusId: 0,
                                  ),
                                ),
                              );
                            }
                          },
                          child: Text(
                            value,
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w500,
                              color: Color(0xff1E2E52),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        )
                      : _buildValue(value),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w400,
        color: Color(0xff99A4BA),
      ),
    );
  }

  Widget _buildValue(String value) {
    return Text(
      value,
      style: TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w500,
        color: Color(0xff1E2E52),
      ),
    );
  }
}
