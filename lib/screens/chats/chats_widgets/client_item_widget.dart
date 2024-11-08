import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/user/client/get_all_client_bloc.dart';
import 'package:crm_task_manager/models/user.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:radio_group_v2/utils/radio_group_decoration.dart';
import 'package:radio_group_v2/widgets/view_models/radio_group_controller.dart';
import 'package:radio_group_v2/widgets/views/radio_group.dart';

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
    context.read<GetAllClientBloc>().add(GetAllClientEv());
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
              return Center(child: CircularProgressIndicator());
            }

            if (state is GetAllClientError) {
              return Text(state.toString());
            }

            if (state is GetAllClientSuccess) {
              usersList =  state.dataUser.result ?? [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                // Для выравнивания по левому краю
                children: [
                  SizedBox(height: 12),
                  const Text(
                    'Пользователь', // Ваше название или лейбл
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Color(0xfff1E2E52),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Отступ между лейблом и выпадающим списком
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
/*
  return Column(
      children: [
        BlocBuilder<GetAllClientBloc, GetAllClientState>(
          builder: (context, state) {

            if(state is GetAllClientLoading) {
              return Center(child: CircularProgressIndicator());
            }

            if(state is GetAllClientError) {
                return Text(state.toString());
            }

            if(state is GetAllClientSuccess) {
              usersList = state.dataUser.result ?? [];

              return ListView.builder(
                  itemBuilder: (context, index) {
                    var data = usersList[index];
                    return InkWell(
                      onTap: () {
                        print('click');
                        setState(() {
                          selectItemIndex = index;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          color: (selectItemIndex == index) ? AppColors.primaryBlue.withOpacity(.1) : AppColors.backgroundPrimaryWhite100
                        ),
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [

                            Text(data.name!, style: TextStyle(
                                fontSize: 18,
                              color: AppColors.primaryBlue,
                              fontWeight:  (selectItemIndex == index) ? FontWeight.w600 : FontWeight.w400
                            ),),
                            if(selectItemIndex == index) Icon(
                              Icons.check,
                              color: AppColors.primaryBlue,
                              size: 32,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                itemCount: usersList.length,
              );

              return Column(
                children: [
                  SizedBox(height: 12),
                  RadioGroup(
                    controller: myController,
                    values: usersList,

                    onChanged: (value) {
                      print(value);
                    },
                    labelBuilder: (item) {
                      var data = item as UserData;
                      return Container(
                        color: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Text(data.name!, style: TextStyle(
                                fontSize: 18
                            ),)
                          ],
                        ),
                      );
                    },
                    indexOfDefault: 0,
                    decoration: RadioGroupDecoration(
                      labelStyle: TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 20
                      ),
                      toggleable: true,
                      splashRadius: 44,
                      activeColor: AppColors.primaryBlue,
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
 */
