import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  static const Color activeColor = Color(0xff1E2E52);
  static const Color inactiveColor = Color(0xff99A4BA);

  static const TextStyle tabTextStyle = TextStyle(
    fontSize: 14,
    fontFamily: 'Gilroy',
    fontWeight: FontWeight.w500,
  );

  static BoxDecoration tabButtonDecoration(bool isActive) {
    return BoxDecoration(
      color: isActive ? const Color(0xff1E2E52) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isActive ? const Color(0xff1E2E52) : const Color(0xff99A4BA),
        width: 1,
      ),
      boxShadow: isActive
          ? [
              BoxShadow(
                color: const Color(0xff1E2E52).withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
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
  _OpeningsScreenState createState() => _OpeningsScreenState();
}

class _OpeningsScreenState extends State<OpeningsScreen> with TickerProviderStateMixin {
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
    _cashRegisterBloc = CashRegisterOpeningsBloc()..add(LoadCashRegisterOpenings());

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
      });
      _scrollToActiveTab();
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

    return MultiBlocProvider(
      providers: [
        BlocProvider<SupplierOpeningsBloc>.value(value: _supplierBloc),
        BlocProvider<ClientOpeningsBloc>.value(value: _clientBloc),
        BlocProvider<GoodsOpeningsBloc>.value(value: _goodsBloc),
        BlocProvider<CashRegisterOpeningsBloc>.value(value: _cashRegisterBloc),
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        floatingActionButton: isClickAvatarIcon
            ? null
            : FloatingActionButton(
                onPressed: _showCreateDialog,
                backgroundColor: const Color(0xff1E2E52),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                ),
              ),
        appBar: AppBar(
          forceMaterialTransparency: true,
          elevation: 0,
          backgroundColor: Colors.white,
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
            showSearchIcon: false,
            onChangedSearchInput: (value) {},
            textEditingController: _searchController,
            focusNode: _searchFocusNode,
            clearButtonClick: (isSearching) {},
          ),
        ),
        body: isClickAvatarIcon
            ? ProfileScreen()
            : Column(
                children: [
                  const SizedBox(height: 15),
                  _buildCustomTabBar(),
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
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildTabButton(index),
          );
        }),
      ),
    );
  }

  Widget _buildTabButton(int index) {
    bool isActive = _tabController.index == index;
    final localizations = AppLocalizations.of(context)!;

    // Use translation for title
    String title = localizations.translate(_tabTitles[index]['titleKey']);

    return GestureDetector(
      key: _tabKeys[index],
      onTap: () {
        _tabController.animateTo(index);
      },
      child: Container(
        decoration: TaskStyles.tabButtonDecoration(isActive),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Text(
          title,
          style: TaskStyles.tabTextStyle.copyWith(
            color: isActive ? Colors.white : TaskStyles.inactiveColor,
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
      final position = box.localToGlobal(Offset.zero, ancestor: context.findRenderObject());
      final tabWidth = box.size.width;
      final screenWidth = MediaQuery.of(context).size.width;

      if (position.dx < 0 || (position.dx + tabWidth) > screenWidth) {
        double targetOffset = _scrollController.offset + position.dx - (screenWidth / 2) + (tabWidth / 2);
        targetOffset = targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent);

        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
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
