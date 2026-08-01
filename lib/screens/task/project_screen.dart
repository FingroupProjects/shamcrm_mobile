import 'dart:async';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/models/project_model.dart';
import 'package:crm_task_manager/screens/task/task_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ProjectScreen extends StatefulWidget {
  const ProjectScreen({super.key});

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  final List<Project> _projects = [];

  Timer? _searchDebounce;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasReachedMax = false;
  bool _isSearching = false;
  bool _canCreate = false;
  bool _canUpdate = false;
  bool _canDelete = false;
  bool _canRead = false;
  int _currentPage = 1;
  static const int _perPage = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPermissions();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadPermissions() async {
    final results = await Future.wait([
      _apiService.hasPermission('project.read'),
      _apiService.hasPermission('project.create'),
      _apiService.hasPermission('project.update'),
      _apiService.hasPermission('project.delete'),
    ]);
    if (!mounted) return;
    setState(() {
      _canRead = results[0];
      _canCreate = results[1];
      _canUpdate = results[2];
      _canDelete = results[3];
    });
    if (_canRead) {
      _loadProjects(refresh: true);
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _hasReachedMax || _isLoadingMore) {
      return;
    }
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 180) {
      _loadProjects();
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      if (mounted) {
        _loadProjects(refresh: true);
      }
    });
  }

  Future<void> _loadProjects({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _hasReachedMax = false;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final response = await _apiService.getAllProject(
        page: refresh ? 1 : _currentPage + 1,
        perPage: _perPage,
        search: _searchController.text,
      );
      final items = response.result ?? [];
      final page =
          response.pagination?.currentPage ?? (refresh ? 1 : _currentPage + 1);
      final totalPages = response.pagination?.totalPages ?? page;

      if (!mounted) return;
      setState(() {
        if (refresh) {
          _projects
            ..clear()
            ..addAll(items);
        } else {
          _projects.addAll(items);
        }
        _currentPage = page;
        _hasReachedMax = page >= totalPages || items.isEmpty;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось загрузить проекты')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) return '-';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat('dd-MM-yyyy').format(parsed);
  }

  String _statusLabel(int? statusId) {
    switch (statusId) {
      case 2:
        return 'Завершено';
      case 3:
        return 'Приостановлен';
      case 1:
      default:
        return 'Активный';
    }
  }

  Color _statusBg(int? statusId) {
    switch (statusId) {
      case 2:
        return const Color(0xFF059669);
      case 3:
        return const Color(0xFF7C3AED);
      case 1:
      default:
        return const Color(0xFF2563EB);
    }
  }

  Color _statusFg(int? statusId) {
    return Colors.white;
  }

  void _openProject(Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider<TaskBloc>(
          create: (_) => TaskBloc(_apiService),
          child: TaskScreen(
            projectId: project.id,
            projectName: project.name,
          ),
        ),
      ),
    );
  }

  Future<void> _openProjectDialog({Project? project}) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierColor: context.appColors.overlay.withValues(alpha: 0.55),
      builder: (_) => _ProjectEditDialog(
        project: project,
        canDelete: _canDelete,
      ),
    );
    if (saved == true) {
      _loadProjects(refresh: true);
    }
  }

  Widget _buildProjectCard(Project project) {
    final colors = context.appColors;
    return Material(
      color: colors.surfaceElevated,
      elevation: 0,
      shadowColor: colors.shadow.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.borderPrimary),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openProject(project),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colors.surfaceAccent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.folder_outlined,
                        color: colors.iconPrimary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      project.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 17,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    constraints: const BoxConstraints(minHeight: 26),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusBg(project.statusId),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.circle, size: 7, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          _statusLabel(project.statusId),
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 11,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                            color: _statusFg(project.statusId),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_canUpdate) const SizedBox(width: 8),
                  if (_canUpdate)
                    Tooltip(
                      message: 'Редактировать',
                      child: Material(
                        color: colors.surfaceAccent,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _openProjectDialog(project: project),
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: Icon(
                              Icons.edit_outlined,
                              color: colors.iconPrimary,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: colors.borderSubtle),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _ProjectDate(
                      label: 'Дата начала',
                      value: _formatDate(project.startDate),
                      icon: Icons.play_circle_outline_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ProjectDate(
                      label: 'Дата завершения',
                      value: _formatDate(project.endDate),
                      icon: Icons.event_available_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      forceMaterialTransparency: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      leading: IconButton(
        tooltip: 'Назад',
        icon: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: context.appColors.surfaceElevated,
            shape: BoxShape.circle,
            border: Border.all(color: context.appColors.borderPrimary),
          ),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: context.appColors.iconPrimary),
        ),
        onPressed: () {
          if (_isSearching) {
            setState(() {
              _isSearching = false;
              _searchController.clear();
            });
            _loadProjects(refresh: true);
          } else {
            Navigator.pop(context);
          }
        },
      ),
      title: _isSearching
          ? TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Поиск проектов',
                hintStyle: TextStyle(
                  color: context.appColors.fieldHint,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Icon(Icons.search_rounded,
                    color: context.appColors.iconSecondary),
                filled: true,
                fillColor: context.appColors.fieldBg,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.appColors.fieldBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.appColors.fieldBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: context.appColors.buttonPrimaryBg, width: 1.5),
                ),
              ),
              style: TextStyle(
                color: context.appColors.textPrimary,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
              ),
            )
          : Text(
              'Проекты',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: context.appColors.textPrimary,
              ),
            ),
      actions: [
        IconButton(
          tooltip: _isSearching ? 'Очистить' : 'Поиск',
          onPressed: () {
            if (_isSearching) {
              _searchController.clear();
              _loadProjects(refresh: true);
            } else {
              setState(() => _isSearching = true);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _searchFocusNode.requestFocus();
              });
            }
          },
          icon: Icon(
            _isSearching ? Icons.close : Icons.search,
            color: context.appColors.iconPrimary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.backgroundPrimary,
      appBar: _buildAppBar(),
      floatingActionButton: _canCreate
          ? FloatingActionButton(
              heroTag: 'project_screen_create_fab',
              onPressed: () => _openProjectDialog(),
              backgroundColor: context.appColors.buttonPrimaryBg,
              child: Image.asset(
                'assets/icons/tabBar/add.png',
                width: 24,
                height: 24,
              ),
            )
          : null,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AppBackgroundOverlay(preset: AppBackgroundPreset.aurora),
          Positioned.fill(
            child: _isLoading
                ? const Center(child: PlayStoreImageLoading(size: 80))
                : !_canRead
                    ? const Center(child: Text('Нет доступа к проектам'))
                    : RefreshIndicator(
                        onRefresh: () => _loadProjects(refresh: true),
                        child: _projects.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  const SizedBox(height: 160),
                                  Center(
                                    child: Text(
                                      'Проекты не найдены',
                                      style: TextStyle(
                                        fontFamily: 'Gilroy',
                                        color: context.appColors.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                controller: _scrollController,
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 96),
                                itemCount:
                                    _projects.length + (_isLoadingMore ? 1 : 0),
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  if (index >= _projects.length) {
                                    return const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 16),
                                      child: Center(
                                        child: PlayStoreImageLoading(size: 56),
                                      ),
                                    );
                                  }
                                  return _buildProjectCard(_projects[index]);
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ProjectDate extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ProjectDate({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: colors.iconSecondary, size: 17),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.textMuted,
                  )),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProjectEditDialog extends StatefulWidget {
  final Project? project;
  final bool canDelete;

  const _ProjectEditDialog({
    this.project,
    required this.canDelete,
  });

  @override
  State<_ProjectEditDialog> createState() => _ProjectEditDialogState();
}

class _ProjectEditDialogState extends State<_ProjectEditDialog> {
  final ApiService _apiService = ApiService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  int _statusId = 1;
  bool _isSaving = false;
  bool _isDeleting = false;

  static const Map<int, String> _statuses = {
    1: 'Активный',
    2: 'Готов',
    3: 'Заморожен',
  };

  @override
  void initState() {
    super.initState();
    final project = widget.project;
    if (project != null) {
      _nameController.text = project.name;
      _startController.text = _displayDate(project.startDate);
      _endController.text = _displayDate(project.endDate);
      _statusId = project.statusId ?? 1;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  static String _displayDate(String? value) {
    if (value == null || value.isEmpty) return '';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat('dd/MM/yyyy').format(parsed);
  }

  String? _apiDate(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    final parsed = DateFormat('dd/MM/yyyy').tryParseStrict(text) ??
        DateFormat('dd.MM.yyyy').tryParseStrict(text) ??
        DateTime.tryParse(text);
    if (parsed == null) return text;
    return DateFormat('yyyy-MM-dd').format(parsed);
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    final project = widget.project;
    final result = project == null
        ? await _apiService.createProject(
            name: _nameController.text.trim(),
            startDate: _apiDate(_startController.text),
            endDate: _apiDate(_endController.text),
            statusId: 1,
          )
        : await _apiService.updateProject(
            projectId: project.id,
            name: _nameController.text.trim(),
            startDate: _apiDate(_startController.text),
            endDate: _apiDate(_endController.text),
            statusId: _statusId,
          );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (result['success'] == true) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Не удалось сохранить')),
      );
    }
  }

  Future<void> _delete() async {
    final project = widget.project;
    if (project == null) return;

    setState(() => _isDeleting = true);
    final result = await _apiService.deleteProject(project.id);
    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (result['success'] == true) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Не удалось удалить')),
      );
    }
  }

  Widget _statusField() {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Статус',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: colors.textPrimary),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: _statusId,
          decoration: _decoration(),
          dropdownColor: colors.surfacePrimary,
          icon: Icon(Icons.keyboard_arrow_down, color: colors.iconPrimary),
          items: _statuses.entries
              .map(
                (entry) => DropdownMenuItem<int>(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _statusId = value);
            }
          },
        ),
      ],
    );
  }

  InputDecoration _decoration() {
    final colors = context.appColors;
    return InputDecoration(
      filled: true,
      fillColor: colors.fieldBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.fieldBorder),
      ),
    );
  }

  Widget _headerButton({
    required Widget child,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: color ?? context.appColors.surfaceAccent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onPressed,
          child: Center(child: child),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isEdit = widget.project != null;
    final maxDialogHeight = MediaQuery.sizeOf(context).height * 0.88;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      backgroundColor: colors.surfacePrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560, maxHeight: maxDialogHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      isEdit ? 'Редактирование' : 'Новый проект',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  if (isEdit && widget.canDelete)
                    _headerButton(
                      color: colors.buttonDangerBg,
                      onPressed: _isDeleting ? null : _delete,
                      child: _isDeleting
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.buttonDangerFg,
                              ),
                            )
                          : Icon(Icons.delete_outline,
                              color: colors.buttonDangerFg, size: 20),
                    ),
                  if (isEdit && widget.canDelete) const SizedBox(width: 8),
                  _headerButton(
                    onPressed: () => Navigator.pop(context, false),
                    child:
                        Icon(Icons.close, color: colors.iconPrimary, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Divider(height: 1, color: colors.borderSubtle),
              const SizedBox(height: 18),
              Flexible(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        controller: _nameController,
                        hintText: 'Введите название',
                        label: 'Название',
                      ),
                      if (isEdit) ...[
                        const SizedBox(height: 18),
                        _statusField(),
                      ],
                      const SizedBox(height: 18),
                      CustomTextFieldDate(
                        controller: _startController,
                        label: 'Дата начала',
                      ),
                      const SizedBox(height: 18),
                      CustomTextFieldDate(
                        controller: _endController,
                        label: 'Дата завершения',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: colors.buttonDangerBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Отмена',
                        style: TextStyle(
                          color: colors.buttonDangerFg,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Gilroy',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: colors.buttonPrimaryBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSaving
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.buttonPrimaryFg,
                              ),
                            )
                          : Text(
                              'Сохранить',
                              style: TextStyle(
                                color: colors.buttonPrimaryFg,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                fontFamily: 'Gilroy',
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
