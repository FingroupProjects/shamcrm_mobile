import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/region/region_bloc.dart';
import 'package:crm_task_manager/bloc/region/region_state.dart';
import 'package:crm_task_manager/models/region_model.dart';

class RegionWidget extends StatefulWidget {
  final String? selectedRegion;
  final ValueChanged<String?> onChanged;

  RegionWidget({required this.selectedRegion, required this.onChanged});

  @override
  _RegionWidgetState createState() => _RegionWidgetState();
}

class _RegionWidgetState extends State<RegionWidget> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegionBloc, RegionState>(
      builder: (context, state) {
        List<DropdownMenuItem<String>> dropdownItems = [];

        if (state is RegionLoading) {
          dropdownItems = [
            DropdownMenuItem(
              value: null,
              child: Text(
                'Загрузка...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
            ),
          ];
        } else if (state is RegionLoaded) {
          dropdownItems =
              state.regions.map<DropdownMenuItem<String>>((Region region) {
            return DropdownMenuItem<String>(
              value: region.id.toString(),
              child: Text(region.name),
            );
          }).toList();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Регион',
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
              ),
              child: DropdownButtonFormField<String>(
                value: dropdownItems
                        .any((item) => item.value == widget.selectedRegion)
                    ? widget.selectedRegion
                    : null,
                hint: const Text(
                  'Выберите регион',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                ),
                items: dropdownItems,
                onChanged: widget.onChanged,
                validator: (value) {
                  if (value == null) {
                    return 'Поле обязательно для заполнения';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF4F7FD)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF4F7FD)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF4F7FD)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                dropdownColor: Colors.white,
                icon: Image.asset(
                  'assets/icons/tabBar/dropdown.png',
                  width: 16,
                  height: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
