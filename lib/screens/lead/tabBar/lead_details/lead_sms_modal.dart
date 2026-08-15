import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/lead/lead_sms_model.dart';
import 'package:crm_task_manager/models/event/notice_sms_sample_model.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LeadSmsModal extends StatefulWidget {
  final int leadId;
  final String leadName;
  final String phone;
  final int? salesFunnelId;

  const LeadSmsModal({
    super.key,
    required this.leadId,
    required this.leadName,
    required this.phone,
    this.salesFunnelId,
  });

  static Future<void> show(
    BuildContext context, {
    required int leadId,
    required String leadName,
    required String phone,
    int? salesFunnelId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LeadSmsModal(
        leadId: leadId,
        leadName: leadName,
        phone: phone,
        salesFunnelId: salesFunnelId,
      ),
    );
  }

  @override
  State<LeadSmsModal> createState() => _LeadSmsModalState();
}

class _LeadSmsModalState extends State<LeadSmsModal> {
  final ApiService _apiService = ApiService();
  final TextEditingController _messageController = TextEditingController();

  bool _isLoading = true;
  bool _isLoadingMessages = false;
  bool _isSending = false;
  int _tabIndex = 0;
  String? _organizationId;
  String? _salesFunnelId;

  List<NoticeSmsSample> _templates = const [];
  NoticeSmsSample? _selectedTemplate;

  List<SmsSenderIntegration> _senders = const [];
  SmsSenderIntegration? _selectedSender;

  List<LeadSmsMessage> _messages = const [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final organizationId = await _apiService.getSelectedOrganization();
      final salesFunnelId = widget.salesFunnelId?.toString() ??
          await _apiService.getSelectedSalesFunnel();

      final templates = <NoticeSmsSample>[NoticeSmsSample.empty()];
      templates.addAll(await _apiService.getNoticeSmsSamples());

      final senders = await _apiService.getSmsIntegrations(
        organizationId: organizationId,
        salesFunnelId: salesFunnelId,
      );

      if (!mounted) return;

      final activeSenders = senders.where((item) => item.isActive).toList();
      setState(() {
        _organizationId = organizationId;
        _salesFunnelId = salesFunnelId;
        _templates = templates;
        _selectedTemplate = templates.isNotEmpty ? templates.first : null;
        _senders = activeSenders;
        _selectedSender = activeSenders.isNotEmpty ? activeSenders.first : null;
        _messageController.text =
            _resolvedTemplateText(_selectedTemplate?.text ?? '');
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      showCustomSnackBar(
        context: context,
        message: 'Не удалось загрузить SMS данные',
        isSuccess: false,
      );
    }
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoadingMessages = true;
    });

    try {
      final messages = await _apiService.getLeadSmsMessages(
        leadId: widget.leadId,
        organizationId: _organizationId,
        salesFunnelId: _salesFunnelId,
      );

      if (!mounted) return;
      setState(() {
        _messages = messages;
        _isLoadingMessages = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingMessages = false;
      });
      showCustomSnackBar(
        context: context,
        message: 'Не удалось загрузить отправленные сообщения',
        isSuccess: false,
      );
    }
  }

  String _resolvedTemplateText(String text) {
    return text
        .replaceAll('%name%', widget.leadName)
        .replaceAll('%phone%', widget.phone);
  }

  Future<void> _selectTemplate() async {
    if (_templates.isEmpty) return;

    final selected = await showModalBottomSheet<NoticeSmsSample>(
      context: context,
      backgroundColor: context.appColors.surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: _templates.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: context.appColors.borderSubtle,
            ),
            itemBuilder: (context, index) {
              final template = _templates[index];
              final isSelected = template.id == _selectedTemplate?.id &&
                  template.text == _selectedTemplate?.text;

              return ListTile(
                title: Text(
                  template.name,
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                    color: context.appColors.textPrimary,
                  ),
                ),
                trailing: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        color: context.appColors.buttonPrimaryBg,
                      )
                    : null,
                onTap: () => Navigator.pop(context, template),
              );
            },
          ),
        );
      },
    );

    if (selected == null || !mounted) return;
    setState(() {
      _selectedTemplate = selected;
      _messageController.text = _resolvedTemplateText(selected.text);
    });
  }

  Future<void> _selectSender() async {
    if (_senders.isEmpty) return;

    final selected = await showModalBottomSheet<SmsSenderIntegration>(
      context: context,
      backgroundColor: context.appColors.surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final colors = context.appColors;
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: _senders.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: colors.borderSubtle,
            ),
            itemBuilder: (context, index) {
              final sender = _senders[index];
              final isSelected = sender.id == _selectedSender?.id;

              return ListTile(
                tileColor: colors.surfacePrimary,
                title: Text(
                  sender.displayName,
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  ),
                ),
                subtitle:
                    sender.name.isNotEmpty && sender.name != sender.displayName
                        ? Text(
                            sender.name,
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              color: colors.textSecondary,
                            ),
                          )
                        : null,
                trailing: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        color: colors.buttonPrimaryBg,
                      )
                    : null,
                onTap: () => Navigator.pop(context, sender),
              );
            },
          ),
        );
      },
    );

    if (selected == null || !mounted) return;
    setState(() {
      _selectedSender = selected;
    });
  }

  Future<void> _sendMessage() async {
    final sender = _selectedSender;
    final text = _messageController.text.trim();

    if (sender == null) {
      showCustomSnackBar(
        context: context,
        message: 'Выберите отправителя',
        isSuccess: false,
      );
      return;
    }

    if (text.isEmpty) {
      showCustomSnackBar(
        context: context,
        message: 'Введите сообщение',
        isSuccess: false,
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await _apiService.sendLeadSmsMessage(
        leadId: widget.leadId,
        integrationId: sender.id,
        text: text,
        organizationId: _organizationId,
        salesFunnelId: _salesFunnelId,
      );

      if (!mounted) return;

      showCustomSnackBar(
        context: context,
        message: 'Сообщение отправлено',
        isSuccess: true,
      );

      setState(() {
        _isSending = false;
        _tabIndex = 1;
      });

      await _loadMessages();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
      });
      showCustomSnackBar(
        context: context,
        message: 'Не удалось отправить сообщение',
        isSuccess: false,
      );
    }
  }

  void _switchTab(int index) {
    if (_tabIndex == index) return;
    setState(() {
      _tabIndex = index;
    });
    if (index == 1) {
      _loadMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final colors = context.appColors;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.only(bottom: viewInsets),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: colors.surfacePrimary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: colors.borderSubtle,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          Text(
                            'Сообщение',
                            style: TextStyle(
                              fontSize: 22,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: colors.surfaceElevated,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.borderSubtle),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded,
                            color: colors.iconPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      _buildTabButton(0, 'Отправить'),
                      _buildTabButton(1, 'Отправленные'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _tabIndex == 0
                        ? _buildComposer()
                        : _buildSentMessages(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String title) {
    final isActive = _tabIndex == index;
    final colors = context.appColors;

    return Expanded(
      child: GestureDetector(
        onTap: () => _switchTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? colors.surfacePrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: isActive ? colors.buttonPrimaryBg : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComposer() {
    final colors = context.appColors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      children: [
        _buildFieldLabel('Отправитель'),
        _buildPickerField(
          value: _selectedSender?.displayName,
          placeholder: _senders.isEmpty
              ? 'Нет доступных отправителей'
              : 'Выберите отправителя',
          onTap: _senders.isEmpty ? null : _selectSender,
        ),
        const SizedBox(height: 14),
        _buildFieldLabel('Шаблон'),
        _buildPickerField(
          value: _selectedTemplate?.name,
          placeholder: 'Выберите шаблон',
          onTap: _selectTemplate,
        ),
        const SizedBox(height: 14),
        _buildFieldLabel('Сообщение'),
        Container(
          decoration: BoxDecoration(
            color: colors.fieldBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.fieldBorder),
          ),
          child: TextField(
            controller: _messageController,
            maxLines: 7,
            minLines: 7,
            style: TextStyle(
              fontSize: 15,
              fontFamily: 'Gilroy',
              color: colors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Введите сообщение',
              hintStyle: TextStyle(
                fontSize: 15,
                fontFamily: 'Gilroy',
                color: colors.fieldHint,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isSending ? null : _sendMessage,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.buttonPrimaryBg,
              foregroundColor: colors.textInverse,
              disabledBackgroundColor: colors.borderSubtle,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isSending
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Отправить',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSentMessages() {
    final colors = context.appColors;
    if (_isLoadingMessages) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Отправленных сообщений пока нет',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMessages,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        itemCount: _messages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _messages[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Дата отправки: ${_formatDate(item.sentAt)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.text.isEmpty ? 'Без текста' : item.text,
                  style: TextStyle(
                    fontSize: 15,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                    height: 1.35,
                  ),
                ),
                if (item.author.isNotEmpty || item.status.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (item.author.isNotEmpty)
                        Expanded(
                          child: Text(
                            'Автор: ${item.author}',
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w500,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      if (item.status.isNotEmpty) ...[
                        if (item.author.isNotEmpty) const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfacePrimary,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: colors.borderSubtle),
                          ),
                          child: Text(
                            _formatStatus(item.status),
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w600,
                              color: colors.buttonPrimaryBg,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFieldLabel(String title) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildPickerField({
    required String? value,
    required String placeholder,
    required VoidCallback? onTap,
  }) {
    final isEmpty = value == null || value.isEmpty;
    final colors = context.appColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: colors.fieldBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.fieldBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                isEmpty ? placeholder : value,
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: isEmpty ? colors.fieldHint : colors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: onTap == null ? colors.fieldHint : colors.iconPrimary,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'Дата неизвестна';
    return DateFormat('dd/MM/yyyy HH:mm').format(value.toLocal());
  }

  String _formatStatus(String status) {
    final normalized = status.trim().toLowerCase();
    switch (normalized) {
      case '':
        return 'Отправлено';
      case 'accepted':
        return 'Отправлено';
      case 'sent':
        return 'Отправлено';
      case 'delivered':
        return 'Доставлено';
      case 'failed':
        return 'Ошибка';
      case 'rejected':
        return 'Отклонено';
      case 'pending':
        return 'В очереди';
      default:
        return status;
    }
  }
}
