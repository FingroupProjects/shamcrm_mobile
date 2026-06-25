import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/helpers/theme_context_extension.dart';
import '../../../bloc/page_2_BLOC/openings/supplier/supplier_openings_bloc.dart';
import '../../../bloc/page_2_BLOC/openings/supplier/supplier_openings_event.dart';
import '../../../bloc/page_2_BLOC/openings/client/client_openings_bloc.dart';
import '../../../bloc/page_2_BLOC/openings/client/client_openings_event.dart';
import '../../../bloc/page_2_BLOC/openings/goods/goods_openings_bloc.dart';
import '../../../bloc/page_2_BLOC/openings/goods/goods_openings_event.dart';
import '../../../bloc/page_2_BLOC/openings/cash_register/cash_register_openings_bloc.dart';
import '../../../bloc/page_2_BLOC/openings/cash_register/cash_register_openings_event.dart';
import '../../../custom_widget/custom_app_bar_simple.dart';
import '../../../screens/profile/languages/app_localizations.dart';
import '../../../screens/profile/profile_screen.dart';
import 'supplier/supplier_content.dart';
import 'client/client_content.dart';
import 'goods/goods_content.dart';
import 'cash_register/cash_register_content.dart';
import 'supplier/create_supplier_opening_dialog.dart';
import 'client/create_client_opening_dialog.dart';
import 'goods/create_goods_opening_dialog.dart';
import 'cash_register/create_cash_register_opening_dialog.dart';

class TaskStyles {
  static const TextStyle tabTextStyle = TextStyle(
    fontSize: 16,
    fontFamily: 'Gilroy',
    fontWeight: FontWeight.w500,
  );

  static const List<Color> tabAccentColors = [
    Color(0xff38BDF8), // Поставщик
    Color(0xff38BDF8), // Клиент
    Color(0xff38BDF8), // Товар
    Color(0xff38BDF8), // Касса
  ];

  static BoxDecoration tabButtonDecoration({
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
    required Color backgroundColor,
  }) {
    return BoxDecoration(
      color: isActive ? activeColor : backgroundColor,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(
        color: isActive ? activeColor : inactiveColor.withValues(alpha: 0.55),
        width: 1,
      ),
      boxShadow: isActive
          ? [
              BoxShadow(
                color: activeColor.withValues(alpha: 0.16),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ]
          : null,
    );
  }
}

class OpeningsScreen extends StatefulWidget {
  final int currentTabIndex;

  const OpeningsScreen({super.key, this.currentTabIndex = 0});

  @override
  State<OpeningsScreen> createState() => _OpeningsScreenState();
}

class _OpeningsScreenState extends State<OpeningsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  final List<Map<String, dynamic>> _tabTitles = [
    {'id': 0, 'titleKey': 'tab_supplier', 'title': 'Поставщик'},
    {'id': 1, 'titleKey': 'tab_client', 'title': 'Клиент'},
    {'id': 2, 'titleKey': 'tab_goods', 'title': 'Товар'},
    {'id': 3, 'titleKey': 'tab_cash_register', 'title': 'Касса'},
  ];
  late List<GlobalKey> _tabKeys;
  late int _currentTabIndex;
  bool isClickAvatarIcon = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String? _currentSearch;

  // Store bloc instances
  late SupplierOpeningsBloc _supplierBloc;
  late ClientOpeningsBloc _clientBloc;
  late GoodsOpeningsBloc _goodsBloc;
  late CashRegisterOpeningsBloc _cashRegisterBloc;

  @override
  void initState() {
    super.initState();

    // Initialize blocs
    _supplierBloc = SupplierOpeningsBloc()..add(LoadSupplierOpenings());
    _clientBloc = ClientOpeningsBloc()..add(LoadClientOpenings());
    _goodsBloc = GoodsOpeningsBloc()..add(LoadGoodsOpenings());
    _cashRegisterBloc = CashRegisterOpeningsBloc()
      ..add(LoadCashRegisterOpenings());

    _currentTabIndex = widget.currentTabIndex;
    _scrollController = ScrollController();
    _tabKeys = List.generate(_tabTitles.length, (_) => GlobalKey());
    _tabController = TabController(
      length: _tabTitles.length,
      vsync: this,
      initialIndex: widget.currentTabIndex,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _currentTabIndex = _tabController.index;
        // Если переключились на вкладку Касса (id == 3), очищаем поиск
        if (_tabTitles[_tabController.index]['id'] == 3) {
          _currentSearch = null;
          _searchController.clear();
        }
      });
      _scrollToActiveTab();
      // Reload data when tab changes
      _loadDataForCurrentTab();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveTab();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();

    // Dispose blocs
    _supplierBloc.close();
    _clientBloc.close();
    _goodsBloc.close();
    _cashRegisterBloc.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colors = context.appColors;

    return MultiBlocProvider(
      providers: [
        BlocProvider<SupplierOpeningsBloc>.value(value: _supplierBloc),
        BlocProvider<ClientOpeningsBloc>.value(value: _clientBloc),
        BlocProvider<GoodsOpeningsBloc>.value(value: _goodsBloc),
        BlocProvider<CashRegisterOpeningsBloc>.value(value: _cashRegisterBloc),
      ],
      child: Scaffold(
        backgroundColor: colors.backgroundPrimary,
        floatingActionButton: isClickAvatarIcon
            ? null
            : FloatingActionButton(
                onPressed: _showCreateDialog,
                backgroundColor: colors.buttonPrimaryBg,
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                ),
              ),
        appBar: AppBar(
          forceMaterialTransparency: true,
          elevation: 0,
          backgroundColor: colors.backgroundPrimary,
          automaticallyImplyLeading: !isClickAvatarIcon,
          title: CustomAppBarSimple(
            title: isClickAvatarIcon
                ? localizations!.translate('appbar_settings')
                : localizations!.translate('appbar_openings'),
            onClickProfileAvatar: () {
              setState(() {
                isClickAvatarIcon = !isClickAvatarIcon;
              });
            },
            showSearchIcon: !isClickAvatarIcon &&
                _currentTabIndex !=
                    3, // Показываем поиск на всех вкладках кроме Кассы (id=3)
            onChangedSearchInput: _onSearch,
            textEditingController: _searchController,
            focusNode: _searchFocusNode,
            clearButtonClick: (isSearching) {
              if (!isSearching) {
                setState(() {
                  _currentSearch = null;
                  _searchController.clear();
                });
                // Не применяем поиск на вкладке Касса (id == 3)
                if (_tabTitles[_currentTabIndex]['id'] != 3) {
                  _loadDataForCurrentTab();
                }
              }
            },
          ),
        ),
        body: isClickAvatarIcon
            ? ProfileScreen()
            : Column(
                children: [
                  const SizedBox(height: 15),
                  _buildCustomTabBar(),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _buildTabBarView(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _scrollController,
      child: Row(
        children: List.generate(_tabTitles.length, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _buildTabButton(index),
          );
        }),
      ),
    );
  }

  Widget _buildTabButton(int index) {
    bool isActive = _tabController.index == index;
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final accentColor = TaskStyles.tabAccentColors[index];

    // Use translation for title
    String title = localizations.translate(_tabTitles[index]['titleKey']);

    return GestureDetector(
      key: _tabKeys[index],
      onTap: () {
        _tabController.animateTo(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        constraints: const BoxConstraints(minWidth: 84),
        decoration: TaskStyles.tabButtonDecoration(
          isActive: isActive,
          activeColor: accentColor,
          inactiveColor: colors.borderPrimary,
          backgroundColor: colors.surfaceElevated,
        ),
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 20),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TaskStyles.tabTextStyle.copyWith(
            color: isActive ? Colors.white : colors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: List.generate(_tabTitles.length, (index) {
        return _buildTabContent(_tabTitles[index]['id']);
      }),
    );
  }

  Widget _buildTabContent(int id) {
    if (id == 0) {
      return const SupplierContent();
    } else if (id == 1) {
      return const ClientContent();
    } else if (id == 2) {
      return const GoodsContent();
    } else if (id == 3) {
      return const CashRegisterContent();
    } else {
      return Container();
    }
  }

  void _scrollToActiveTab() {
    final keyContext = _tabKeys[_currentTabIndex].currentContext;
    if (keyContext != null) {
      final box = keyContext.findRenderObject() as RenderBox;
      final position =
          box.localToGlobal(Offset.zero, ancestor: context.findRenderObject());
      final tabWidth = box.size.width;
      final screenWidth = MediaQuery.of(context).size.width;

      if (position.dx < 0 || (position.dx + tabWidth) > screenWidth) {
        double targetOffset = _scrollController.offset +
            position.dx -
            (screenWidth / 2) +
            (tabWidth / 2);
        targetOffset =
            targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent);

        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _onSearch(String query) {
    // Не применяем поиск на вкладке Касса (id == 3)
    if (_tabTitles[_currentTabIndex]['id'] == 3) {
      return;
    }

    setState(() {
      _currentSearch = query.trim().isNotEmpty ? query : null;
    });

    // Ищем в текущей вкладке
    _loadDataForCurrentTab();
  }

  void _loadDataForCurrentTab() {
    final id = _tabTitles[_currentTabIndex]['id'];

    if (id == 0) {
      // Supplier tab - передаем текущий search
      _supplierBloc.add(LoadSupplierOpenings(search: _currentSearch));
    } else if (id == 1) {
      // Client tab - передаем текущий search
      _clientBloc.add(LoadClientOpenings(search: _currentSearch));
    } else if (id == 2) {
      // Goods tab - передаем текущий search
      _goodsBloc.add(LoadGoodsOpenings(search: _currentSearch));
    } else if (id == 3) {
      // Cash register tab - поиск не используется, всегда null
      _cashRegisterBloc.add(LoadCashRegisterOpenings(search: null));
    }
  }

  void _showCreateDialog() {
    final id = _tabTitles[_currentTabIndex]['id'];

    if (id == 0) {
      showDialog(
        context: context,
        builder: (dialogContext) => BlocProvider.value(
          value: _supplierBloc,
          child: const CreateSupplierOpeningDialog(),
        ),
      );
    } else if (id == 1) {
      showDialog(
        context: context,
        builder: (dialogContext) => BlocProvider.value(
          value: _clientBloc,
          child: const CreateClientOpeningDialog(),
        ),
      );
    } else if (id == 2) {
      showDialog(
        context: context,
        builder: (dialogContext) => BlocProvider.value(
          value: _goodsBloc,
          child: const CreateGoodsOpeningDialog(),
        ),
      );
    } else if (id == 3) {
      showDialog(
        context: context,
        builder: (dialogContext) => BlocProvider.value(
          value: _cashRegisterBloc,
          child: const CreateCashRegisterOpeningDialog(),
        ),
      );
    } else {
      return;
    }
  }
}
