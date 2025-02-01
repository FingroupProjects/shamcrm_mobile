import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/user/client/get_all_client_bloc.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:radio_group_v2/widgets/view_models/radio_group_controller.dart';

class UserListGroup extends StatefulWidget {
  final Function(UserData) onSelectUser;
  final String chatId;

  UserListGroup({
    super.key,
    required this.onSelectUser,
    required this.chatId,
  });

  @override
  State<UserListGroup> createState() => _UserListGroup();
}

class _UserListGroup extends State<UserListGroup> {
  RadioGroupController myController = RadioGroupController();

  List<String> items = [];
  List<UserData> usersList = [];

  @override
  void initState() {
    super.initState();
    context.read<GetAllClientBloc>().add(GetUsersNotInChatEv(widget.chatId));
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

  Widget _buildAvatar(String avatar) {
    if (avatar.contains('<svg')) {
      final imageUrl = extractImageUrlFromSvg(avatar);
      if (imageUrl != null) {
        return Container(
          width: 31,
          height: 31,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        );
      } else {
        final text = extractTextFromSvg(avatar);
        final backgroundColor = extractBackgroundColorFromSvg(avatar);

        if (text != null && backgroundColor != null) {
          return Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor,
              border: Border.all(
                color: Colors.white,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        } else {
          return SvgPicture.string(
            avatar,
            width: 31,
            height: 31,
            placeholderBuilder: (context) => CircularProgressIndicator(),
          );
        }
      }
    }

    return CircleAvatar(
      backgroundImage: AssetImage(avatar),
      radius: 24,
      backgroundColor: Colors.white,
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
              return Text(state.message);
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
                      color: Color(0xff1E2E52),
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
                        return Container(
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          child: Row(
                            children: [
                              if (item.image != null) _buildAvatar(item.image!),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.name ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xff1E2E52),
                                    fontWeight: FontWeight.w400,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      headerBuilder: (context, selectedItem, enabled) {
                        return Row(
                          children: [
                            if (selectedItem.image != null) _buildAvatar(selectedItem.image!),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                selectedItem.name ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xff1E2E52),
                                  fontWeight: FontWeight.w400,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      },
                      hintBuilder: (context, hint, enabled) => Text(AppLocalizations.of(context)!.translate('select_user')),
                      excludeSelected: false,
                      onChanged: (value) {
                        widget.onSelectUser(value!);
                      },
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