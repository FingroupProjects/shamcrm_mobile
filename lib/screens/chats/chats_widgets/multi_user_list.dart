import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/user/client/get_all_client_bloc.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UserMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedUsers;
  final Function(List<UserData>) onSelectUsers;
  final bool hasError;
  final String? errorText;

  UserMultiSelectWidget({
    super.key,
    required this.onSelectUsers,
    this.selectedUsers,
    this.hasError = false,
    this.errorText,
  });

  @override
  State<UserMultiSelectWidget> createState() => _UserMultiSelectWidgetState();
}

class _UserMultiSelectWidgetState extends State<UserMultiSelectWidget> {
  List<UserData> usersList = [];
  List<UserData> selectedUsersData = [];
  bool selectAll = false;

  final UserData selectAllItem = UserData(id: -1, name: 'select_all', lastname: '');

  @override
  void initState() {
    super.initState();
    context.read<GetAllClientBloc>().add(GetAnotherClientEv());
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
      radius: 20,
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
              final dropdownItems = [selectAllItem, ...usersList];
              if (widget.selectedUsers != null && usersList.isNotEmpty) {
                selectedUsersData = usersList
                    .where((user) =>
                        widget.selectedUsers!.contains(user.id.toString()))
                    .toList();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate('users_list'),
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
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(width: 1, color: Color(0xFFF4F7FD)),
                    ),
                    child: CustomDropdown<UserData>.multiSelectSearch(
                      items: dropdownItems, 
                      initialItems: selectedUsersData,
                      searchHintText: AppLocalizations.of(context)!.translate('search'),
                      overlayHeight: 400,
                      decoration: CustomDropdownDecoration(
                        closedFillColor: Color(0xffF4F7FD),
                        expandedFillColor: Colors.white,
                        closedBorder: Border.all(
                          color: widget.hasError ? Colors.red : Color(0xffF4F7FD),
                          width: widget.hasError ? 1.5 : 1,
                        ),
                        closedBorderRadius: BorderRadius.circular(12),
                        expandedBorder: Border.all(
                          color: widget.hasError ? Colors.red : Color(0xffF4F7FD),
                          width: widget.hasError ? 1.5 : 1,
                        ),
                        expandedBorderRadius: BorderRadius.circular(12),
                      ),
                      listItemBuilder: (context, item, isSelected, onItemSelect) {
                        if (item.id == -1) {
                          return ListTile(
                            minTileHeight: 0,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8), 
                            minVerticalPadding: 0,
                            dense: true,
                            title: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Color(0xff1E2E52), width: 1),
                                    color: selectAll ? Color(0xff1E2E52) : Colors.transparent,
                                  ),
                                  child: selectAll
                                      ? Icon(Icons.check, color: Colors.white, size: 16)
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  AppLocalizations.of(context)!.translate('select_all'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Gilroy',
                                    color: Color(0xff1E2E52),
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              setState(() {
                                selectAll = !selectAll;
                                if (selectAll) {
                                  selectedUsersData = List.from(usersList);
                                } else {
                                  selectedUsersData = [];
                                }
                                widget.onSelectUsers(selectedUsersData);
                              });
                            },
                          );
                        }

                        return ListTile(
                          minTileHeight: 0, 
                          contentPadding: EdgeInsets.symmetric(horizontal: 8), 
                          minVerticalPadding: 0,
                          dense: true,
                          title: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Color(0xff1E2E52), width: 1),
                                  color: isSelected ? Color(0xff1E2E52) : Colors.transparent,
                                ),
                                child: isSelected
                                    ? Icon(Icons.check, color: Colors.white, size: 16)
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              if (item.image != null) ...[
                                _buildAvatar(item.image!),
                                const SizedBox(width: 10),
                              ],
                              Flexible(
                                child: Text(
                                  item.name!,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Gilroy',
                                    color: Color(0xff1E2E52),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          onTap: () => onItemSelect(),
                        );
                      },
                      headerListBuilder: (context, hint, enabled) {
                        int selectedUsersCount = selectedUsersData.length;

                        return Text(
                          selectedUsersCount == 0
                              ? AppLocalizations.of(context)!
                                  .translate('select_users')
                              : '${AppLocalizations.of(context)!.translate('selected_users')}$selectedUsersCount',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                            color: Color(0xff1E2E52),
                          ),
                        );
                      },
                      hintBuilder: (context, hint, enabled) => Text(
                          AppLocalizations.of(context)!.translate('select_users'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                            color: Color(0xff99A4BA),
                          )),
                      onListChanged: (values) {
                        final filteredValues =
                            values.where((item) => item.id != -1).toList();
                        widget.onSelectUsers(filteredValues);
                        setState(() {
                          selectedUsersData = filteredValues;
                          selectAll = filteredValues.length == usersList.length;
                        });
                      },
                    ),
                  ),
                  if (widget.hasError && widget.errorText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        widget.errorText!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
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
