import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/models/chat/message_reaction_model.dart';

/// Компактный чип реакции как в Telegram
/// Размещается ВНУТРИ сообщения
class CompactReactionChip extends StatelessWidget {
  final MessageReaction reaction;
  final VoidCallback? onTap;
  final bool isSender;

  const CompactReactionChip({
    Key? key,
    required this.reaction,
    this.isSender = false,
    this.onTap,
  }) : super(key: key);

  // Слегка увеличил размеры для читаемости
  static const double chipHeight = 22.0;
  static const double emojiSize = 14.0;
  static const double fontSize = 12.0;
  static const double borderRadius = 11.0;
  static const double horizontalPadding = 6.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: chipHeight,
        padding: const EdgeInsets.symmetric(
          horizontal: horizontalPadding,
        ),
        decoration: BoxDecoration(
          // Единый стиль "как у серверной реакции" (без выделения контура)
          color: context.appColors.buttonPrimaryBg.withValues(alpha: 0.14),
          border: Border.all(
            color: context.appColors.buttonPrimaryBg.withValues(alpha: 0.35),
            width: 0.8,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              reaction.emoji,
              style: const TextStyle(
                fontSize: emojiSize,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              reaction.count.toString(),
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: context.appColors.textInverse,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Общая "капсула" реакций для image/file/voice сообщений.
/// Используется, чтобы реакции выглядели как единый блок, а не разрозненные чипы.
class ReactionCapsule extends StatelessWidget {
  final List<MessageReaction> reactions;
  final bool isSender;
  final Function(String emoji)? onReactionTap;

  const ReactionCapsule({
    Key? key,
    required this.reactions,
    required this.isSender,
    this.onReactionTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: reactions.map((reaction) {
          return CompactReactionChip(
            reaction: reaction,
            isSender: isSender,
            onTap: () => onReactionTap?.call(reaction.emoji),
          );
        }).toList(),
      ),
    );
  }
}
