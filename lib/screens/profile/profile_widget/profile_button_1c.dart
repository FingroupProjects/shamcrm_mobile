import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:crm_task_manager/bloc/data_1c/data_1c_bloc.dart';
import 'package:crm_task_manager/bloc/data_1c/data_1c_event.dart';
import 'package:crm_task_manager/bloc/data_1c/data_1c_state.dart';

class UpdateWidget1C extends StatefulWidget {
  const UpdateWidget1C({super.key});

  @override
  _UpdateWidget1CState createState() => _UpdateWidget1CState();
}

class _UpdateWidget1CState extends State<UpdateWidget1C> with SingleTickerProviderStateMixin {
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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            lastUpdated = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now());
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
                'Ошибка: ${state.message}',
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: GestureDetector(
        onTap: () {
          context.read<Data1CBloc>().add(FetchData1C());
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileOption(
              iconPath: 'assets/icons/1c/update.png',
              text: 'Обновить данные 1С',
            ),
            if (lastUpdated != null)
              Center(
                child: Text(
                  'Последнее обновление: $lastUpdated',
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
          isLoading
              ? RotationTransition(
                  turns: Tween<double>(begin: 0, end: -1).animate(_controller),
                  child: Image.asset(
                    iconPath,
                    width: 60,
                    height: 60,
                  ),
                )
              : Image.asset(
                  iconPath,
                  width: 40,
                  height: 40,
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