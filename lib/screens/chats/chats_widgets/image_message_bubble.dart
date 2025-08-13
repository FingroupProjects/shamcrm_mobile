import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/widgets/full_image_screen_viewer.dart';

class ImageMessageBubble extends StatefulWidget {
  final String time;
  final bool isSender;
  final String filePath;
  final String fileName;
  final String senderName;
  final String? replyMessage;
  final bool isHighlighted;
  final bool isRead;

  const ImageMessageBubble({
    Key? key,
    required this.time,
    required this.isSender,
    required this.senderName,
    required this.filePath,
    required this.fileName,
    this.replyMessage,
    this.isHighlighted = false,
    required this.isRead,
    required Message message,
  }) : super(key: key);

  @override
  State<ImageMessageBubble> createState() => _ImageMessageBubbleState();
}

class _ImageMessageBubbleState extends State<ImageMessageBubble> {
  final ApiService _apiService = ApiService();
  String? baseUrl;

  @override
  void initState() {
    super.initState();
    _initializeBaseUrl();
  }

  Future<void> _initializeBaseUrl() async {
    try {
      final enteredDomainMap = await _apiService.getEnteredDomain();
      setState(() {
        baseUrl = 'https://${enteredDomainMap['enteredMainDomain']}/storage/';
      });
    } catch (error) {
      setState(() {
        baseUrl = 'https://shamcrm.com/storage/';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? fullUrl = baseUrl != null ? '$baseUrl${widget.filePath}' : null;

    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: widget.isHighlighted
            ? [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 5,
                  spreadRadius: 2,
                  offset: Offset(0, -4),
                ),
              ]
            : [],
      ),
      child: Align(
        alignment: widget.isSender ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: widget.isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            if (!widget.isSender)
              Text(
                widget.senderName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            GestureDetector(
              onTap: fullUrl != null
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullImageScreenViewer(
                            imagePath: fullUrl,
                            time: widget.time,
                            fileName: widget.fileName,
                            senderName: (!widget.isSender) ? widget.senderName : '',
                          ),
                        ),
                      );
                    }
                  : null,
              child: Column(
                crossAxisAlignment: widget.isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      border: Border.all(width: 1, color: Colors.black26),
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          offset: Offset(0, 4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: fullUrl != null
                          ? Image.network(
                              fullUrl,
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 200,
                                  height: 200,
                                  color: Colors.grey,
                                  child: Center(
                                    child: Text(AppLocalizations.of(context)!.translate('error_loading')),
                                  ),
                                );
                              },
                            )
                          : Container(
                              width: 200,
                              height: 200,
                              color: Colors.grey,
                              child: Center(
                                child: Text(AppLocalizations.of(context)!.translate('loading')),
                              ),
                            ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          right: widget.isSender ? 0 : 10,
                          left: widget.isSender ? 10 : 0,
                        ),
                        child: Text(
                          widget.time,
                          style: const TextStyle(
                            fontSize: 12,
                            color: ChatSmsStyles.appBarTitleColor,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                      ),
                      const SizedBox(width: 3),
                      if (widget.isSender)
                        Icon(
                          widget.isRead ? Icons.done_all : Icons.done_all,
                          size: 18,
                          color: widget.isRead ? const Color.fromARGB(255, 45, 28, 235) : Colors.grey.shade400,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}