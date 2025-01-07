import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/user/client/get_all_client_bloc.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:radio_group_v2/widgets/view_models/radio_group_controller.dart';

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
    // context.read<GetAllClientBloc>().add(GetAllClientEv());
    context.read<GetAllClientBloc>().add(GetUsersWithoutCorporateChatEv());
    super.initState();
  }

  int selectItemIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocBuilder<GetAllClientBloc, GetAllClientState>(
          builder: (context, state) {
            if (state is GetAllClientLoading) {
              return Center(child: CircularProgressIndicator(color: Color(0xff1E2E52)),);
            }

            if (state is GetAllClientError) {
              return Text(state.toString());
            }

            if (state is GetAllClientSuccess) {
              usersList =  state.dataUser.result ?? [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 12),
                  const Text(
                    'Пользователь', 
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
                        border: Border.all(width: 1, color: Color(0xFFF4F7FD))
                      ),
                      child: CustomDropdown<UserData>.search(closeDropDownOnClearFilterSearch: true,
                        items: usersList,
                        searchHintText: 'Поиск',
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

                          return Text(item.name!);
                        },
                        headerBuilder:(context, selectedItem, enabled) {
                        widget.onSelectUser(selectedItem);
                          return Text(selectedItem.name!);
                        } ,
                        hintBuilder: (context, hint, enabled) => Text('Выберите пользователя'),
                        excludeSelected: false,
                        onChanged: (value) {

                        },
                      )),
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
