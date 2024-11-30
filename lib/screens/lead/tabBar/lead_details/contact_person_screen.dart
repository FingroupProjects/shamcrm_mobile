import 'package:crm_task_manager/bloc/contact_person/contact_person_bloc.dart';
import 'package:crm_task_manager/bloc/contact_person/contact_person_event.dart';
import 'package:crm_task_manager/bloc/contact_person/contact_person_state.dart';
import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/models/contact_person_model.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/contact_person_add_screen.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/contact_person_delete.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/contact_person_update_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ContactPersonWidget extends StatefulWidget {
  final int leadId;

  ContactPersonWidget({required this.leadId});

  @override
  _ContactPersonWidgetState createState() => _ContactPersonWidgetState();
}

class _ContactPersonWidgetState extends State<ContactPersonWidget> {
  List<ContactPerson> contactPerson = [];
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    context.read<ContactPersonBloc>().add(FetchContactPerson(widget.leadId));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ContactPersonBloc, ContactPersonState>(
      builder: (context, state) {
        if (state is ContactPersonLoading) {
          // return const Center(child: CircularProgressIndicator());
        } else if (state is ContactPersonLoaded) {
          contactPerson = state.contactPerson;
        } else if (state is ContactPersonError) {
          return Center(child: Text(state.message));
        }

        return _buildContactPersonList(contactPerson);
      },
    );
  }

  Widget _buildContactPersonList(List<ContactPerson> contactPerson) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleRow('Контактное Лицо'),
        SizedBox(height: 8),
        if (contactPerson.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              decoration: TaskCardStyles.taskCardDecoration,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Пока здесь нет Контактное Лицо',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: Color(0xff1E2E52),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          )
        else
          Container(
            height: 300,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: contactPerson.length,
              itemBuilder: (context, index) {
                return _buildContactPersonItem(contactPerson[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildContactPersonItem(ContactPerson contactPerson) {
    return GestureDetector(
      onTap: () {
        _navigateToContactPersonDetails(contactPerson);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          decoration: TaskCardStyles.taskCardDecoration,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Image.asset(
                  'assets/icons/contactPerson.png',
                  width: 24,
                  height: 24,
                  color: Color(0xff1E2E52),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contactPerson.name,
                        style: TaskCardStyles.titleStyle,
                      ),
                      Text(
                        contactPerson.phone,
                      ),
                      Text(
                        contactPerson.position.toString(),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Color(0xff1E2E52)),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => DeleteContactPersonDialog(
                        contactPerson: contactPerson,
                        leadId: widget.leadId,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToContactPersonDetails(ContactPerson contactPerson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactPersonUpdateScreen(
          leadId: widget.leadId,
          contactPerson: contactPerson,
        ),
      ),
    ).then((_) {
      context.read<ContactPersonBloc>().add(FetchContactPerson(widget.leadId));
    });
  }

  Row _buildTitleRow(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TaskCardStyles.titleStyle.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ContactPersonAddScreen(leadId: widget.leadId),
              ),
            ).then((_) {
              context
                  .read<ContactPersonBloc>()
                  .add(FetchContactPerson(widget.leadId));
            });
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            backgroundColor: Color(0xff1E2E52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Добавить',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
