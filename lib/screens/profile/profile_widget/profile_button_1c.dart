import 'package:crm_task_manager/models/organization_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:crm_task_manager/bloc/data_1c/data_1c_bloc.dart';
import 'package:crm_task_manager/bloc/data_1c/data_1c_event.dart';
import 'package:crm_task_manager/bloc/data_1c/data_1c_state.dart';

class UpdateWidget1C extends StatefulWidget {
  final Organization organization;

  const UpdateWidget1C({
    Key? key,
    required this.organization,
  }) : super(key: key);

  @override
  _UpdateWidget1CState createState() => _UpdateWidget1CState();
}

class _UpdateWidget1CState extends State<UpdateWidget1C>
    with SingleTickerProviderStateMixin {
  bool isLoading = false;
  String? lastUpdated;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    final organizationLastUpdate = widget.organization.last1cUpdate;
    if (organizationLastUpdate != null) {
      lastUpdated = DateFormat('dd.MM.yyyy HH:mm')
          .format(DateTime.parse(organizationLastUpdate));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final organization = widget.organization;

    return BlocListener<Data1CBloc, Data1CState>(
      listener: (context, state) {
        if (state is Data1CLoading) {
          setState(() {
            isLoading = true;
          });
          _controller.repeat();
        } else if (state is Data1CLoaded) {
          setState(() {
            isLoading = false;
            final updatedOrganization = state.data1C.firstWhere(
              (org) => org.id == widget.organization.id,
              orElse: () => widget.organization,
            );
            lastUpdated = updatedOrganization.last1cUpdate != null
                ? DateFormat('dd.MM.yyyy HH:mm')
                    .format(DateTime.parse(updatedOrganization.last1cUpdate!))
                : null;
          });
          _controller.stop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Данные 1С успешно обновлены',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is Data1CError) {
          setState(() {
            isLoading = false;
          });
          _controller.stop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                // '${state.message}',
                'Данные успешно обновлены!',
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
              backgroundColor: Colors.green,
              elevation: 3,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: GestureDetector(
        onTap: organization.is1cIntegration
            ? () {
                context.read<Data1CBloc>().add(FetchData1C());
              }
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (organization.is1cIntegration)
              _buildProfileOption(
                iconPath: 'assets/icons/1c/5.png',
                text: 'Обновить данные 1С',
                
              ),
            if (lastUpdated != null)
              Center(
                child: Text(
                  'Последнее обновление 1C: $lastUpdated',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Gilroy',
                    color: Color(0xFF1E1E1E),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

 Widget _buildProfileOption({required String iconPath, required String text}) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF4F7FD),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        // Новый контейнер с фоном и скругленными углами
        Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255,  223, 225, 247), // Цвет фона
            borderRadius: BorderRadius.circular(12), // Скругленные углы
          ),
          child: isLoading
              ? RotationTransition(
                  turns: Tween<double>(begin: 0, end: -1).animate(_controller),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0), // Отступы для размера иконки
                    child: Image.asset(
                      iconPath,
                      width: 50,
                      height: 50,
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(1.0), // Отступы для размера иконки
                  child: Image.asset(
                    iconPath,
                    width: 40,
                    height: 40,
                  ),
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: Color(0xFF1E1E1E),
            ),
          ),
        ),
      ],
    ),
  );
}

}
