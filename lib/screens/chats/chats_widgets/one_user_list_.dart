import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/user/client/get_all_client_bloc.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:radio_group_v2/widgets/view_models/radio_group_controller.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ClientRadioGroupWidget extends StatefulWidget {
  Function(UserData) onSelectUser;
  ClientRadioGroupWidget({super.key, required this.onSelectUser});

  @override
  State<ClientRadioGroupWidget> createState() => _ClientRadioGroupWidgetState();
}

class _ClientRadioGroupWidgetState extends State<ClientRadioGroupWidget> {
  RadioGroupController myController = RadioGroupController();
  List<String> items = [];
  List<UserData> usersList = [];

 @override
  void initState() {
    context.read<GetAllClientBloc>().add(GetUsersWithoutCorporateChatEv());
    super.initState();
  }
  
  String? extractImageUrlFromSvg(String svg) {
    if (svg.contains('href="')) {
      final start = svg.indexOf('href="') + 6;
      final end = svg.indexOf('"', start);
      return svg.substring(start, end);
    }
    return null;
  }

  String? extractTextFromSvg(String svg) {
    final textMatch = RegExp(r'<text[^>]*>(.*?)</text>').firstMatch(svg);
    return textMatch?.group(1);
  }

  Color? extractBackgroundColorFromSvg(String svg) {
    final fillMatch = RegExp(r'fill="(#[A-Fa-f0-9]+)"').firstMatch(svg);
    if (fillMatch != null) {
      final colorHex = fillMatch.group(1);
      if (colorHex != null) {
        final hex = colorHex.replaceAll('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      }
    }
    return null;
  }

  Widget buildUserAvatar(UserData userData) {
    if (userData.image == null) return SizedBox(width: 31, height: 31);

    final imageUrl = extractImageUrlFromSvg(userData.image!);

    return Container(
      margin: EdgeInsets.only(right: 4),
      child: imageUrl != null
          ? Stack(
              children: [
                SvgPicture.string(
                  userData.image!,
                  width: 31,
                  height: 31,
                ),
                ClipOval(
                  child: Image.network(
                    imageUrl,
                    width: 31,
                    height: 31,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            )
          : Container(
              width: 31,
              height: 31,
              child: Center(
                child: SvgPicture.string(
                  userData.image!,
                  width: 31,
                  height: 31,
                ),
              ),
            ),
    );
  }

 

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocBuilder<GetAllClientBloc, GetAllClientState>(
          builder: (context, state) {
            if (state is GetAllClientLoading) {
              return Center(
                child: CircularProgressIndicator(color: Color(0xff1E2E52)),
              );
            }

            if (state is GetAllClientError) {
              return Text(state.toString());
            }

            if (state is GetAllClientSuccess) {
              usersList = state.dataUser.result ?? [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)!.translate('user'), 
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Color(0xfff1E2E52),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFF4F7FD),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(width: 1, color: Color(0xFFF4F7FD)),
                    ),
                    child: CustomDropdown<UserData>.search(
                      closeDropDownOnClearFilterSearch: true,
                      items: usersList,
                      searchHintText: AppLocalizations.of(context)!.translate('search'), 
                      overlayHeight: 400,
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
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          child: Row(
                            children: [
                              buildUserAvatar(item),
                              Text(item.name!),
                            ],
                          ),
                        );
                      },
                      headerBuilder: (context, selectedItem, enabled) {
                        widget.onSelectUser(selectedItem);
                        return Row(
                          children: [
                            buildUserAvatar(selectedItem),
                            Text(selectedItem.name!),
                          ],
                        );
                      },
                      hintBuilder: (context, hint, enabled) =>
                          Text(AppLocalizations.of(context)!.translate('select_user')),
                      excludeSelected: false,
                      onChanged: (value) {},
                    ),
                  ),
                ],
              );
            }

            return SizedBox();
          },
        ),
      ],
    );
  }
}