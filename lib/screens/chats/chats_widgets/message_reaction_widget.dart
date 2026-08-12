import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/models/chat/message_reaction_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

/// Виджет для отображения реакций под сообщением
class MessageReactionWidget extends StatelessWidget {
  final List<MessageReaction> reactions;
  final Function(String emoji) onReactionTap;
  final bool isSender;

  const MessageReactionWidget({
    Key? key,
    required this.reactions,
    required this.onReactionTap,
    this.isSender = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 2),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        alignment: isSender ? WrapAlignment.end : WrapAlignment.start,
        children: reactions
            .map((reaction) => _buildReactionChip(reaction, context))
            .toList(),
      ),
    );
  }

  Widget _buildReactionChip(MessageReaction reaction, BuildContext context) {
    return GestureDetector(
      onTap: () => onReactionTap(reaction.emoji),
      onLongPress: () => _showReactionUsers(context, reaction),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: reaction.isMyReaction
              ? context.appColors.buttonPrimaryBg.withValues(alpha: 0.15)
              : context.appColors.backgroundSecondary,
          border: Border.all(
            color: reaction.isMyReaction
                ? context.appColors.buttonPrimaryBg.withValues(alpha: 0.4)
                : context.appColors.borderSubtle,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              reaction.emoji,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            if (reaction.count > 1) ...[
              const SizedBox(width: 4),
              Text(
                '${reaction.count}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: reaction.isMyReaction
                      ? context.appColors.buttonPrimaryBg
                      : context.appColors.textSecondary,
                  fontFamily: 'Gilroy',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Показывает список пользователей, поставивших реакцию
  void _showReactionUsers(BuildContext context, MessageReaction reaction) {
    if (reaction.users.isEmpty) return;
    final localizations = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: context.appColors.surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с эмодзи
              Row(
                children: [
                  Text(
                    reaction.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    localizations.translate('reaction_title').replaceFirst(
                          '{count}',
                          reaction.count.toString(),
                        ),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              // Список пользователей
              ...reaction.users
                  .map((user) => _buildUserListItem(user, context))
                  .toList(),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserListItem(ReactionUser user, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Аватар
          CircleAvatar(
            radius: 20,
            backgroundImage: user.image != null && user.image!.isNotEmpty
                ? NetworkImage(user.image!)
                : null,
            backgroundColor: context.appColors.buttonPrimaryBg.withValues(alpha: 0.12),
            child: user.image == null || user.image!.isEmpty
                ? Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: context.appColors.buttonPrimaryBg,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Имя
          Expanded(
            child: Text(
              user.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
