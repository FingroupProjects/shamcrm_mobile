import 'package:flutter/material.dart';

class CreateGoodsOpeningDialog extends StatefulWidget {
  const CreateGoodsOpeningDialog({super.key});

  @override
  State<CreateGoodsOpeningDialog> createState() => _CreateGoodsOpeningDialogState();
}

class _CreateGoodsOpeningDialogState extends State<CreateGoodsOpeningDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Создать остаток по товару',
              style: const TextStyle(
                fontSize: 18,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52),
              ),
            ),
            const SizedBox(height: 24),
            // TODO: Add form fields here
            Container(
              height: 200,
              color: Colors.grey[100],
              child: const Center(
                child: Text('Form fields will be added here'),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Отмена',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      color: Color(0xff99A4BA),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Handle save
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff1E2E52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Сохранить',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

