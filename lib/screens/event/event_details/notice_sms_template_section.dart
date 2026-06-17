import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/notice_sms_sample_model.dart';
import 'package:flutter/material.dart';

class NoticeSmsTemplateSection extends StatelessWidget {
  final bool isVisible;
  final bool sendSms;
  final List<NoticeSmsSample> templates;
  final NoticeSmsSample? selectedTemplate;
  final ValueChanged<bool> onToggle;
  final ValueChanged<NoticeSmsSample> onTemplateSelected;

  const NoticeSmsTemplateSection({
    super.key,
    required this.isVisible,
    required this.sendSms,
    required this.templates,
    required this.selectedTemplate,
    required this.onToggle,
    required this.onTemplateSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final colors = context.appColors;
    final selectedName = selectedTemplate?.name ??
        (templates.isNotEmpty ? templates.first.name : 'Пустой шаблон');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Авто рассылка',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: sendSms,
              onChanged: onToggle,
              activeThumbColor: colors.buttonPrimaryFg,
              inactiveTrackColor: colors.borderSubtle.withValues(alpha: 0.5),
              activeTrackColor: colors.buttonPrimaryBg,
              inactiveThumbColor: colors.buttonPrimaryFg,
            ),
          ],
        ),
        if (sendSms) ...[
          const SizedBox(height: 8),
          Text(
            'Шаблон сообщений',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showTemplatePicker(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: colors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: colors.iconPrimary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _showTemplatePicker(BuildContext context) async {
    final colors = context.appColors;
    final selected = await showModalBottomSheet<NoticeSmsSample>(
      context: context,
      backgroundColor: colors.surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final sheetColors = context.appColors;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Шаблон сообщений',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Gilroy',
                      color: sheetColors.textPrimary,
                    ),
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: templates.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: sheetColors.borderSubtle),
                    itemBuilder: (context, index) {
                      final template = templates[index];
                      final isSelected =
                          template.name == selectedTemplate?.name &&
                              template.text == selectedTemplate?.text;

                      return ListTile(
                        title: Text(
                          template.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                            color: sheetColors.textPrimary,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check,
                                color: sheetColors.buttonPrimaryBg)
                            : null,
                        onTap: () => Navigator.pop(context, template),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      onTemplateSelected(selected);
    }
  }
}
