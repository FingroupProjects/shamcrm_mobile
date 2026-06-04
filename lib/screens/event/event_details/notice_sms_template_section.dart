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
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    final selectedName = selectedTemplate?.name ??
        (templates.isNotEmpty ? templates.first.name : 'Пустой шаблон');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Авто рассылка',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: sendSms,
              onChanged: onToggle,
              activeThumbColor: Colors.white,
              inactiveTrackColor:
                  const Color.fromARGB(255, 179, 179, 179).withValues(alpha: 0.5),
              activeTrackColor: const Color(0xff4759FF),
              inactiveThumbColor: Colors.white,
            ),
          ],
        ),
        if (sendSms) ...[
          const SizedBox(height: 8),
          const Text(
            'Шаблон сообщений',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: Color(0xff1E2E52),
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
                color: const Color(0xffF4F7FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xff1E2E52),
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
    final selected = await showModalBottomSheet<NoticeSmsSample>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Шаблон сообщений',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Gilroy',
                      color: Color(0xff1E2E52),
                    ),
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: templates.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final template = templates[index];
                      final isSelected = template.name == selectedTemplate?.name &&
                          template.text == selectedTemplate?.text;

                      return ListTile(
                        title: Text(
                          template.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                            color: Color(0xff1E2E52),
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: Color(0xff4759FF))
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
