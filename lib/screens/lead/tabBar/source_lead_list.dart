import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/source_lead/source_lead_bloc.dart';
import 'package:crm_task_manager/bloc/source_lead/source_lead_event.dart';
import 'package:crm_task_manager/bloc/source_lead/source_lead_state.dart';
import 'package:crm_task_manager/models/source_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SourceLeadWidget extends StatefulWidget {
  final String? selectedSourceLead;
  final ValueChanged<String?> onChanged;

  SourceLeadWidget({required this.selectedSourceLead, required this.onChanged});

  @override
  _SourceLeadWidgetState createState() => _SourceLeadWidgetState();
}
class _SourceLeadWidgetState extends State<SourceLeadWidget> {
  SourceLead? selectedSourceData;

  @override
  void initState() {
    super.initState();
    context.read<SourceLeadBloc>().add(FetchSourceLead());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SourceLeadBloc, SourceLeadState>(
      listener: (context, state) {
        if (state is SourceLeadError) {
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
        }
      },
      child: BlocBuilder<SourceLeadBloc, SourceLeadState>(
        builder: (context, state) {
          // Обновляем данные при успешной загрузке
          if (state is SourceLeadLoaded) {
            List<SourceLead> sourcesList = state.sourceLead;
            
            if (widget.selectedSourceLead != null && sourcesList.isNotEmpty) {
              try {
                selectedSourceData = sourcesList.firstWhere(
                  (source) => source.id.toString() == widget.selectedSourceLead,
                );
              } catch (e) {
                selectedSourceData = null;
              }
            }
          }

          // Всегда отображаем поле
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.translate('source'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                child: CustomDropdown<SourceLead>.search(
                  closeDropDownOnClearFilterSearch: true,
                  items: state is SourceLeadLoaded ? state.sourceLead : [],
                  searchHintText: AppLocalizations.of(context)!.translate('search'),
                  overlayHeight: 400,
                  enabled: true, // Всегда enabled
                  decoration: CustomDropdownDecoration(
                    closedFillColor: Color(0xffF4F7FD),
                    expandedFillColor: Colors.white,
                    closedBorder: Border.all(
                      color: Color(0xffF4F7FD),
                      width: 1,
                    ),
                    closedBorderRadius: BorderRadius.circular(12),
                    expandedBorder: Border.all(
                      color: Color(0xffF4F7FD),
                      width: 1,
                    ),
                    expandedBorderRadius: BorderRadius.circular(12),
                  ),
                  listItemBuilder: (context, item, isSelected, onItemSelect) {
                    return Text(
                      item.name,
                      style: TextStyle(
                        color: Color(0xff1E2E52),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                      ),
                    );
                  },
                  headerBuilder: (context, selectedItem, enabled) {
                    if (state is SourceLeadLoading) {
                      return Row(
                        children: [
                          // SizedBox(
                          //   width: 16,
                          //   height: 16,
                          //   child: CircularProgressIndicator(
                          //     strokeWidth: 2,
                          //     valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1E2E52)),
                          //   ),
                          // ),
                          Text(
                            AppLocalizations.of(context)!.translate('select_source'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Gilroy',
                              color: Color(0xff1E2E52),
                            ),
                          ),
                        ],
                      );
                    }
                    return Text(
                      selectedItem.name ?? AppLocalizations.of(context)!.translate('select_source'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                    );
                  },
                  hintBuilder: (context, hint, enabled) => Text(
                    AppLocalizations.of(context)!.translate('select_source'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Color(0xff1E2E52),
                    ),
                  ),
                  excludeSelected: false,
initialItem: (state is SourceLeadLoaded && state.sourceLead.contains(selectedSourceData))
    ? selectedSourceData
    : null,
                  // validator: (value) {
                  //   if (value == null) {
                  //     return AppLocalizations.of(context)!.translate('field_required_source');
                  //   }
                  //   return null;
                  // },
                  onChanged: (value) {
                    if (value != null) {
                      widget.onChanged(value.id.toString());
                      setState(() {
                        selectedSourceData = value;
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