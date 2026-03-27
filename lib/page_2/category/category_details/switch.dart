import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class PriceAffectSwitcher extends StatelessWidget {
  final bool isActive;
  final ValueChanged<bool> onChanged;

  const PriceAffectSwitcher({
    Key? key,
    required this.isActive,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text( AppLocalizations.of(context)!.translate('has_price_characteristics'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                ),
                SizedBox(height: 4),
                Text( AppLocalizations.of(context)!.translate('has_price_characteristics_description'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Gilroy',
                    color: Color(0x991E2E52), 
                  ),
                ),
              ],
            ),
          ),

          Switch(
            value: isActive,
            onChanged: onChanged,
            activeColor: const Color.fromARGB(255, 255, 255, 255),
            inactiveTrackColor: const Color.fromARGB(255, 179, 179, 179).withOpacity(0.5),
            activeTrackColor: const Color(0xFF4759FF), 
            inactiveThumbColor: const Color.fromARGB(255, 255, 255, 255),
          ),
        ],
      ),
    );
  }
}
