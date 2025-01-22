import 'package:crm_task_manager/models/chats_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/widgets/full_image_screen_viewer.dart';

class ImageMessageBubble extends StatelessWidget {
  final String time;
  final bool isSender;
  final String filePath;
  final String fileName;
  final String senderName;

  const ImageMessageBubble({
    Key? key,
    required this.time,
    required this.isSender,
    required this.senderName,
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
      child: Column(
        crossAxisAlignment:
            isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          if(!isSender) Text(
            senderName,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          GestureDetector(
            onTap: ()  {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullImageScreenViewer(imagePath: fullUrl, time: time, fileName: fileName, senderName: (!isSender) ? senderName : '',),
                ),
              );
            },
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                      border: Border.all(width: 1, color: Colors.black26),
                      borderRadius: BorderRadius.all(Radius.circular(12))
                  ),
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
                          child: Center(child: Text(AppLocalizations.of(context)!.translate('error_loading'))),
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
          )

        ],
      ),
    );
  }
}
