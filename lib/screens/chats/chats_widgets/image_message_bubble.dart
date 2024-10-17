import 'package:crm_task_manager/models/chats_model.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/widgets/full_image_screen_viewer.dart';

class ImageMessageBubble extends StatelessWidget {
  final String time;
  final bool isSender;
  final String filePath;
  final String fileName;

  const ImageMessageBubble({
    Key? key,
    required this.time,
    required this.isSender,
    required this.filePath,
    required this.fileName, required Message message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String baseUrl = 'https://shamcrm.com/storage/';
    // final String baseUrl = 'http://192.168.1.61:8008/storage/';
    final String fullUrl = '$baseUrl$filePath';

    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FullImageScreenViewer(imagePath: fullUrl),
            ),
          );
        },
        child: Column(
          crossAxisAlignment:
              isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 5),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  fullUrl,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 200,
                      height: 200,
                      color: Colors.grey,
                      child: const Center(child: Text('Ошибка загрузки')),
                    );
                  },
                ),
              ),
            ),
            Text(
              time,
              style: const TextStyle(
                fontSize: 12,
                color: ChatSmsStyles.appBarTitleColor,
                fontWeight: FontWeight.w400,
                fontFamily: 'Gilroy',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
