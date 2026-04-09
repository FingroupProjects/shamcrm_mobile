import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

/// Переиспользуемые кнопки для документов
/// Два режима:
/// 1. CREATE - "Сохранить и провести" + "Сохранить" (две кнопки в одном ряду)
/// 2. EDIT - "Обновить" (одна кнопка)
class DocumentActionButtons extends StatefulWidget {
  final DocumentActionMode mode;
  final bool isLoading;
  final VoidCallback? onSave;
  final VoidCallback? onSaveAndApprove;

  const DocumentActionButtons({
    required this.mode,
    required this.isLoading,
    this.onSave,
    this.onSaveAndApprove,
    Key? key,
  }) : super(key: key);

  @override
  State<DocumentActionButtons> createState() => _DocumentActionButtonsState();
}

class _DocumentActionButtonsState extends State<DocumentActionButtons> {
  bool _tapLocked = false;

  @override
  void didUpdateWidget(covariant DocumentActionButtons oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isLoading && _tapLocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || widget.isLoading || !_tapLocked) return;
        setState(() => _tapLocked = false);
      });
    }
  }

  void _handleTap(VoidCallback? callback) {
    if (_tapLocked || widget.isLoading || callback == null) return;

    setState(() => _tapLocked = true);
    callback();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.isLoading || !_tapLocked) return;
      setState(() => _tapLocked = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: widget.mode == DocumentActionMode.create
          ? _buildCreateButtons(context)
          : _buildEditButton(context),
    );
  }

  // TODO: Эти изменения в расположении кнопок (Row вместо Column, компактный дизайн) должны быть проверены в других файлах, где используется DocumentActionButtons
  // Кнопки для создания документа
  Widget _buildCreateButtons(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return Row(
      children: [
        // Первая кнопка "Сохранить и провести" - белый фон с зелёной границей
        Expanded(
          child: Container(
            height: 48, // Уменьшено с 48 до 40 для компактности
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xff4CAF50), width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: widget.isLoading || _tapLocked
                    ? null
                    : () => _handleTap(widget.onSaveAndApprove),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8), // Уменьшено с 16 до 8
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 18, // Уменьшено с 20 до 18
                        color: widget.isLoading
                            ? const Color(0xff99A4BA)
                            : const Color(0xff4CAF50),
                      ),
                      const SizedBox(width: 6), // Уменьшено с 8 до 6
                      Text(
                        localizations.translate('save_and_approve') ??
                            'Сохранить и провести',
                        style: TextStyle(
                          fontSize: 14, // Уменьшено с 16 до 14
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: widget.isLoading
                              ? const Color(0xff99A4BA)
                              : const Color(0xff4CAF50),
                        ),
                        overflow: TextOverflow.ellipsis, // Добавлено для предотвращения переполнения
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12), // Пространство между кнопками
        // Вторая кнопка "Сохранить" - синяя
        Expanded(
          child: SizedBox(
            height: 48, // Уменьшено с 48 до 40 для компактности
            child: ElevatedButton(
              onPressed: widget.isLoading || _tapLocked
                  ? null
                  : () => _handleTap(widget.onSave),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff4759FF),
                disabledBackgroundColor: const Color(0xffE5E7EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      width: 18, // Уменьшено с 20 до 18
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save_outlined,
                            color: Colors.white, size: 18), // Уменьшено с 20 до 18
                        const SizedBox(width: 6), // Уменьшено с 8 до 6
                        Text(
                          localizations.translate('save') ?? 'Сохранить',
                          style: const TextStyle(
                            fontSize: 14, // Уменьшено с 16 до 14
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis, // Добавлено для предотвращения переполнения
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // Кнопка для редактирования документа
  Widget _buildEditButton(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: widget.isLoading || _tapLocked
            ? null
            : () => _handleTap(widget.onSave),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff4759FF),
          disabledBackgroundColor: const Color(0xffE5E7EB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: widget.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save_outlined, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    localizations.translate('save') ?? 'Обновить',
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

enum DocumentActionMode {
  create, // Режим создания (две кнопки)
  edit,   // Режим редактирования (одна кнопка)
}
