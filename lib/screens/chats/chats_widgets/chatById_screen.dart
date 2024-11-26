import 'package:crm_task_manager/models/ChatById_model.dart';
import 'package:flutter/material.dart';

class ChatProfileScreen extends StatelessWidget {
  final ChatProfile chatProfile;

  ChatProfileScreen({required this.chatProfile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(chatProfile.name),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildDetailItem("ID", chatProfile.id.toString()),
            _buildDetailItem("Name", chatProfile.name),
            _buildDetailItem(
                "Facebook Login", chatProfile.facebookLogin ?? "Not Provided"),
            _buildDetailItem(
                "Instagram Login", chatProfile.instaLogin ?? "Not Provided"),
            _buildDetailItem("Telegram Nick", chatProfile.tgNick ?? "Not Provided"),
            _buildDetailItem("Telegram ID", chatProfile.tgId ?? "Not Provided"),
            _buildDetailItem("Position", chatProfile.position ?? "Not Provided"),
            _buildDetailItem("WhatsApp Name", chatProfile.waName ?? "Not Provided"),
            _buildDetailItem("WhatsApp Phone", chatProfile.waPhone ?? "Not Provided"),
            _buildDetailItem("Address", chatProfile.address ?? "Not Provided"),
            _buildDetailItem("Phone", chatProfile.phone ?? "Not Provided"),
            _buildDetailItem("Message Amount", chatProfile.messageAmount.toString()),
            _buildDetailItem("Birthday", chatProfile.birthday ?? "Not Provided"),
            _buildDetailItem("Description", chatProfile.description ?? "Not Provided"),
            _buildDetailItem("Created At", chatProfile.createdAt),
            _buildDetailItem(
                "Unread Messages Count",
                chatProfile.unreadMessagesCount?.toString() ?? "Not Provided"),
            _buildDetailItem(
                "Deals Count", chatProfile.dealsCount?.toString() ?? "Not Provided"),
            _buildChannelsSection(chatProfile.channels),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label:",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelsSection(List<Channel> channels) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Channels:",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 8),
        ...channels.map((channel) => Text("- ${channel.name}")).toList(),
      ],
    );
  }
}
