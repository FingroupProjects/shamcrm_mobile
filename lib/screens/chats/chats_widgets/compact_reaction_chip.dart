import 'package:flutter/material.dart';
import 'package:crm_task_manager/models/message_reaction_model.dart';

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
          // Если мы отправитель (фиолетовый фон), делаем светлую подложку
          color: isSender
              ? (reaction.isMyReaction
                  ? Colors.white.withOpacity(0.4)
                  : Colors.white.withOpacity(0.25))
              : (reaction.isMyReaction
                  ? const Color(0x1A2481CC)
                  : const Color(0x14000000)),
          borderRadius: BorderRadius.circular(borderRadius),
          border: reaction.isMyReaction
              ? Border.all(
                  color: isSender
                      ? Colors.white.withOpacity(0.8)
                      : const Color(0xFF2481CC),
                  width: 1.2,
                )
              : null,
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
                color: isSender
                    ? Colors.white
                    : (reaction.isMyReaction
                        ? const Color(0xFF2481CC)
                        : const Color(0xFF8E8E93)),
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
