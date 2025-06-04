import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_state.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/custom_widget/custom_tasks_tabBar.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/models/page_2/order_status_model.dart';
import 'package:crm_task_manager/page_2/order/order_details/delete_status_order.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_add.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_column.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_status_add.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_status_edit.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OrderScreen extends StatefulWidget {
  final int? organizationId;

  const OrderScreen({this.organizationId});

  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<GlobalKey> _tabKeys = [];
  bool _isSearching = false;
  int _currentTabIndex = 0;
  bool isClickAvatarIcon = false;
  List<OrderStatus> _statuses = [];
  bool _isInitialLoad = true;
  bool _navigateToNewStatus = false;
  int? _newStatusId;

  late OrderBloc _orderBloc;

  @override
  void initState() {
    super.initState();
    print('OrderScreen: Инициализация состояния');
    _orderBloc = OrderBloc(ApiService())..add(FetchOrderStatuses());
    print(
        'OrderScreen: Создан OrderBloc и добавлено событие FetchOrderStatuses');
    _tabController = TabController(length: 0, vsync: this);
    print('OrderScreen: Создан TabController с length=0');
  }

  @override
  void dispose() {
    print('OrderScreen: Вызов dispose');
    _scrollController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    _orderBloc.close();
    print('OrderScreen: Все контроллеры и OrderBloc освобождены');
    super.dispose();
  }

  void _scrollToActiveTab() {
    print(
        'OrderScreen: Начало _scrollToActiveTab, _currentTabIndex=$_currentTabIndex');
    if (_tabKeys.isEmpty || _currentTabIndex >= _tabKeys.length) {
      print(
          'OrderScreen: _tabKeys пуст или _currentTabIndex вне диапазона, пропускаем');
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keyContext = _tabKeys[_currentTabIndex].currentContext;
      if (keyContext != null) {
        final box = keyContext.findRenderObject() as RenderBox;
        final position = box.localToGlobal(Offset.zero,
            ancestor: context.findRenderObject());
        final tabWidth = box.size.width;
        double targetOffset = _scrollController.offset +
            position.dx -
            (MediaQuery.of(context).size.width / 2) +
            (tabWidth / 2);
        print('OrderScreen: Прокрутка к targetOffset=$targetOffset');
        _scrollController.animateTo(
          targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.ease,
        );
      } else {
        print(
            'OrderScreen: keyContext для _currentTabIndex=$_currentTabIndex равен null');
        Future.delayed(Duration(milliseconds: 100), () {
          print(
              'OrderScreen: Повторная попытка _scrollToActiveTab после задержки');
          _scrollToActiveTab();
        });
      }
    });
  }

  void _onSearch(String query) {
    print('OrderScreen: Вызов _onSearch с query=$query');
    setState(() {
      _isSearching = query.isNotEmpty;
      print('OrderScreen: _isSearching установлен в $_isSearching');
    });
  }

  void _onStatusUpdated(int newStatusId) {
    print('OrderScreen: Вызов _onStatusUpdated с newStatusId=$newStatusId');
    final newTabIndex =
        _statuses.indexWhere((status) => status.id == newStatusId);
    print('OrderScreen: Найден newTabIndex=$newTabIndex');
    if (newTabIndex != -1 && newTabIndex != _currentTabIndex) {
      setState(() {
        _currentTabIndex = newTabIndex;
        print('OrderScreen: _currentTabIndex обновлен на $newTabIndex');
      });
      _tabController.animateTo(newTabIndex);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('OrderScreen: Вызов _scrollToActiveTab после _onStatusUpdated');
        _scrollToActiveTab();
      });
      _orderBloc.add(FetchOrders(statusId: newStatusId));
      print(
          'OrderScreen: Добавлено событие FetchOrders для statusId=$newStatusId');
    } else {
      print(
          'OrderScreen: newTabIndex=$newTabIndex, _currentTabIndex=$_currentTabIndex, переход не требуется');
    }
  }

  void _resetScreenState() {
    print('OrderScreen: Сброс состояния экрана');
    setState(() {
      _statuses = [];
      _tabKeys = [];
      _currentTabIndex = 0;
      _isInitialLoad = true;
      _navigateToNewStatus = false;
      _isSearching = false;
      _searchController.clear();
      print(
          'OrderScreen: Сброшены _statuses, _tabKeys, _currentTabIndex, _isInitialLoad, _navigateToNewStatus, _isSearching');
    });
    _tabController.dispose();
    _tabController = TabController(length: 0, vsync: this);
    print('OrderScreen: TabController пересоздан с length=0');
  }

  void _showStatusOptions(BuildContext context, int index) {
    final RenderBox renderBox =
        _tabKeys[index].currentContext!.findRenderObject() as RenderBox;
    final Offset position = renderBox.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + renderBox.size.height,
        position.dx + renderBox.size.width,
        position.dy + renderBox.size.height * 2,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 4,
      color: Colors.white,
      items: [
        PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit, color: Color(0xff99A4BA)),
            title: Text(
              'Изменить',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
                color: Color(0xff1E2E52),
              ),
            ),
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, color: Color(0xff99A4BA)),
            title: Text(
              'Удалить',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
                color: Color(0xff1E2E52),
              ),
            ),
          ),
        ),
      ],
    ).then((value) {
      if (value == 'edit') {
        showDialog(
          context: context,
          barrierColor: Colors.black.withOpacity(0.5),
          builder: (context) => EditStatusOrder(
            status: _statuses[index],
            orderBloc: _orderBloc,
          ),
        ).then((result) {
          if (result == true) {
            _orderBloc.add(FetchOrderStatuses());
            print(
                'OrderScreen: Добавлено событие FetchOrderStatuses после редактирования');
          }
        });
      } else if (value == 'delete') {
        showDialog(
          context: context,
          barrierColor: Colors.black.withOpacity(0.5),
          builder: (context) => DeleteStatusOrder(
            statusId: _statuses[index].id,
            statusName: _statuses[index].name,
            orderBloc: _orderBloc,
          ),
        ).then((result) {
          if (result == true) {
            _orderBloc.add(FetchOrderStatuses());
            print(
                'OrderScreen: Добавлено событие FetchOrderStatuses после удаления');
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print('OrderScreen: Начало build');
    final localizations = AppLocalizations.of(context);
    return BlocProvider.value(
      value: _orderBloc,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          forceMaterialTransparency: true,
          title: CustomAppBarPage2(
            onChangedSearchInput: (value) => _onSearch(value),
            showFilterIcon: false,
            showSearchIcon: true,
            title: isClickAvatarIcon
                ? localizations!.translate('appbar_settings')
                : localizations!.translate('appbar_orders'),
            onClickProfileAvatar: () {
              setState(() {
                isClickAvatarIcon = !isClickAvatarIcon;
                print(
                    'OrderScreen: isClickAvatarIcon изменен на $isClickAvatarIcon');
              });
            },
            textEditingController: _searchController,
            focusNode: _focusNode,
            clearButtonClick: (value) {
              if (!value) {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  print(
                      'OrderScreen: Очищен поиск, _isSearching=$_isSearching');
                });
              }
            },
            clearButtonClickFiltr: (value) {},
            currentFilters: {}, // Provide empty map since no filters are used
          ),
        ),
        body: isClickAvatarIcon
            ? const ProfileScreen()
            : BlocListener<OrderBloc, OrderState>(
                listener: (context, state) {
                  print(
                      'OrderScreen: BlocListener, текущее состояние: ${state.runtimeType}');
                  if (state is OrderLoaded) {
                    print('OrderScreen: Получено состояние OrderLoaded');
                    print(
                        'OrderScreen: Новые статусы: ${state.statuses.map((s) => s.toJson()).toList()}');
                    print(
                        'OrderScreen: Текущие _statuses: ${_statuses.map((s) => s.toJson()).toList()}');
                    if (_statuses.length != state.statuses.length ||
                        !_statuses.every(
                            (s) => state.statuses.any((st) => st.id == s.id))) {
                      print(
                          'OrderScreen: Список статусов изменился, обновляем UI');
                      setState(() {
                        _statuses = state.statuses;
                        print(
                            'OrderScreen: _statuses обновлен: ${_statuses.map((s) => s.toJson()).toList()}');
                        _tabKeys =
                            List.generate(_statuses.length, (_) => GlobalKey());
                        print(
                            'OrderScreen: _tabKeys обновлен, длина: ${_tabKeys.length}');
                        _tabController.dispose();
                        _tabController = TabController(
                            length: _statuses.length, vsync: this);
                        print(
                            'OrderScreen: TabController пересоздан с length=${_statuses.length}');
                        _tabController.addListener(() {
                          if (_currentTabIndex != _tabController.index) {
                            setState(() {
                              _currentTabIndex = _tabController.index;
                              print(
                                  'OrderScreen: _currentTabIndex обновлен на $_currentTabIndex');
                            });
                            _scrollToActiveTab();
                            if (_statuses.isNotEmpty) {
                              _orderBloc.add(FetchOrders(
                                statusId: _statuses[_currentTabIndex].id,
                                page: 1,
                                perPage: 20,
                              ));
                              print(
                                  'OrderScreen: Добавлено событие FetchOrders для statusId=${_statuses[_currentTabIndex].id}');
                            }
                          }
                        });

                        if (_navigateToNewStatus &&
                            _statuses.isNotEmpty &&
                            _newStatusId != null) {
                          print(
                              'OrderScreen: Выполняется переход на новый статус, _newStatusId=$_newStatusId');
                          final newTabIndex = _statuses.indexWhere(
                              (status) => status.id == _newStatusId);
                          print(
                              'OrderScreen: Найден newTabIndex=$newTabIndex для _newStatusId=$_newStatusId');
                          if (newTabIndex != -1) {
                            setState(() {
                              _currentTabIndex = newTabIndex;
                              _navigateToNewStatus = false;
                              print(
                                  'OrderScreen: _currentTabIndex установлен в $newTabIndex, _navigateToNewStatus сброшен');
                            });
                            _tabController.animateTo(newTabIndex);
                            print(
                                'OrderScreen: TabController переключен на индекс $newTabIndex');
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              print(
                                  'OrderScreen: Вызов _scrollToActiveTab после перестроения');
                              _scrollToActiveTab();
                            });
                            _orderBloc.add(FetchOrders(
                              statusId: _statuses[newTabIndex].id,
                              page: 1,
                              perPage: 20,
                              forceRefresh: true,
                            ));
                            print(
                                'OrderScreen: Добавлено событие FetchOrders для нового статуса statusId=${_statuses[newTabIndex].id}');
                          } else {
                            print(
                                'OrderScreen: Новый статус с id=$_newStatusId не найден в списке статусов');
                          }
                        }
                      });
                      if (_isInitialLoad && _statuses.isNotEmpty) {
                        print(
                            'OrderScreen: Первая загрузка, запрашиваем заказы для первого статуса');
                        _orderBloc.add(FetchOrders(
                          statusId: _statuses[0].id,
                          page: 1,
                          perPage: 20,
                        ));
                        _isInitialLoad = false;
                        print('OrderScreen: _isInitialLoad установлен в false');
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          print(
                              'OrderScreen: Вызов _scrollToActiveTab после начальной загрузки');
                          _scrollToActiveTab();
                        });
                      }
                    } else {
                      print(
                          'OrderScreen: Список статусов не изменился, пропускаем обновление UI');
                    }
                  } else if (state is OrderStatusCreated) {
                    print(
                        'OrderScreen: Получено состояние OrderStatusCreated, message=${state.message}, newStatusId=${state.newStatusId}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          state.message,
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.green,
                        elevation: 3,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    print('OrderScreen: Показан зеленый SnackBar');

                    _resetScreenState();

                    setState(() {
                      _navigateToNewStatus = true;
                      _newStatusId = state.newStatusId;
                      print(
                          'OrderScreen: Установлены _navigateToNewStatus=$_navigateToNewStatus, _newStatusId=$_newStatusId');
                    });

                    _orderBloc.add(FetchOrderStatuses());
                    print('OrderScreen: Добавлено событие FetchOrderStatuses');
                  } else if (state is OrderStatusDeleted) {
                    print(
                        'OrderScreen: Получено состояние OrderStatusDeleted, message=${state.message}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          state.message,
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.green,
                        elevation: 3,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    print('OrderScreen: Показан зеленый SnackBar');

                    _resetScreenState();
                    _orderBloc.add(FetchOrderStatuses());
                    print(
                        'OrderScreen: Добавлено событие FetchOrderStatuses после удаления');
                  } else if (state is OrderStatusUpdated) {
                    print(
                        'OrderScreen: Получено состояние OrderStatusUpdated, message=${state.message}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          state.message,
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.green,
                        elevation: 3,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    print('OrderScreen: Показан зеленый SnackBar');

                    _resetScreenState();
                    _orderBloc.add(FetchOrderStatuses());
                    print(
                        'OrderScreen: Добавлено событие FetchOrderStatuses после редактирования');
                  } else if (state is OrderError) {
                    print(
                        'OrderScreen: Получено состояние OrderError, message=${state.message}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          state.message,
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.red,
                        elevation: 3,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    print('OrderScreen: Показан красный SnackBar с ошибкой');
                  }
                },
                child: BlocBuilder<OrderBloc, OrderState>(
                  builder: (context, state) {
                    print(
                        'OrderScreen: BlocBuilder, текущее состояние: ${state.runtimeType}');
                    if (_statuses.isEmpty || state is OrderLoading) {
                      print(
                          'OrderScreen: _statuses пуст или состояние OrderLoading, показываем загрузку');
                      return const Center(
                        child: PlayStoreImageLoading(
                          size: 80.0,
                          duration: Duration(milliseconds: 1000),
                        ),
                      );
                    }

                    print(
                        'OrderScreen: _statuses не пуст, отображаем контент, _statuses=${_statuses.map((s) => s.toJson()).toList()}');
                    return RefreshIndicator(
                      color: const Color(0xff1E2E52),
                      backgroundColor: Colors.white,
                      onRefresh: () async {
                        print(
                            'OrderScreen: Выполняется обновление через RefreshIndicator');
                        _orderBloc.add(FetchOrderStatuses());
                        if (_statuses.isNotEmpty) {
                          _orderBloc.add(FetchOrders(
                            statusId: _statuses[_currentTabIndex].id,
                            page: 1,
                            perPage: 20,
                          ));
                          print(
                              'OrderScreen: Добавлено событие FetchOrders для statusId=${_statuses[_currentTabIndex].id}');
                        }
                        return Future.delayed(const Duration(milliseconds: 1));
                      },
                      child: Column(
                        children: [
                          const SizedBox(height: 15),
                          _buildCustomTabBar(context),
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: _statuses.map((status) {
                                final List<Order> statusOrders = state
                                        is OrderLoaded
                                    ? state.orders
                                        .where((order) =>
                                            order.orderStatus.id == status.id)
                                        .toList()
                                    : <Order>[];
                                print(
                                    'OrderScreen: Отображаем вкладку для статуса ${status.toJson()}, заказы: ${statusOrders.map((o) => o.toJson()).toList()}');
                                return OrderColumn(
                                  statusId: status.id,
                                  name: status.name,
                                  searchQuery: _isSearching
                                      ? _searchController.text
                                      : null,
                                  organizationId: widget.organizationId,
                                  onStatusUpdated: () =>
                                      _onStatusUpdated(status.id),
                                  onStatusId: (newStatusId) =>
                                      _onStatusUpdated(newStatusId),
                                  onTabChange: (newTabIndex) {
                                    setState(() {
                                      _currentTabIndex = newTabIndex;
                                      print(
                                          'OrderScreen: _currentTabIndex обновлен на $newTabIndex через onTabChange');
                                    });
                                    _tabController.animateTo(newTabIndex);
                                    _scrollToActiveTab();
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            print(
                'OrderScreen: Нажата кнопка FloatingActionButton для создания заказа');
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderAddScreen(
                    // organizationId: widget.organizationId,
                    ),
              ),
            );

            if (result != null &&
                result is Map<String, dynamic> &&
                result['success'] == true) {
              final newStatusId = result['statusId'];
              print(
                  'OrderScreen: Получен результат создания заказа, newStatusId=$newStatusId');
              final orderBloc = context.read<OrderBloc>();

              final newTabIndex =
                  _statuses.indexWhere((status) => status.id == newStatusId);
              print(
                  'OrderScreen: Найден newTabIndex=$newTabIndex для newStatusId=$newStatusId');
              if (newTabIndex != -1) {
                setState(() {
                  _currentTabIndex = newTabIndex;
                  print(
                      'OrderScreen: _currentTabIndex установлен в $newTabIndex');
                });
                _tabController.animateTo(newTabIndex);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  print(
                      'OrderScreen: Вызов _scrollToActiveTab после создания заказа');
                  _scrollToActiveTab();
                });
              }

              orderBloc.add(FetchOrders(
                statusId: newStatusId,
                page: 1,
                perPage: 20,
                forceRefresh: true,
              ));
              print(
                  'OrderScreen: Добавлено событие FetchOrders для statusId=$newStatusId');

              if (newTabIndex != _currentTabIndex) {
                orderBloc.add(FetchOrders(
                  statusId: _statuses[_currentTabIndex].id,
                  page: 1,
                  perPage: 20,
                  forceRefresh: true,
                ));
                print(
                    'OrderScreen: Добавлено событие FetchOrders для текущего статуса statusId=${_statuses[_currentTabIndex].id}');
              }
            } else {
              print(
                  'OrderScreen: Результат создания заказа неуспешен или отсутствует');
            }
          },
          backgroundColor: const Color(0xff1E2E52),
          child: const Icon(
            Icons.add,
            color: Color.fromARGB(255, 255, 255, 255),
            size: 25,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTabBar(BuildContext context) {
    print(
        'OrderScreen: Начало _buildCustomTabBar, _statuses=${_statuses.map((s) => s.toJson()).toList()}');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _scrollController,
      child: Row(
        children: [
          ...List.generate(_statuses.length, (index) {
            bool isActive = _tabController.index == index;
            print(
                'OrderScreen: Создаем вкладку для индекса $index, isActive=$isActive');
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: GestureDetector(
                key: _tabKeys[index],
                onTap: () {
                  print('OrderScreen: Нажата вкладка с индексом $index');
                  _tabController.animateTo(index);
                },
                onLongPress: () {
                  print(
                      'OrderScreen: Долгое нажатие на вкладку с индексом $index');
                  _showStatusOptions(context, index);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive ? Colors.black : const Color(0xff99A4BA),
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  child: Text(
                    _statuses[index].name,
                    style: TaskStyles.tabTextStyle.copyWith(
                      color: isActive
                          ? TaskStyles.activeColor
                          : TaskStyles.inactiveColor,
                    ),
                  ),
                ),
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: GestureDetector(
              onTap: () async {
                print('OrderScreen: Нажата кнопка добавления нового статуса');
                await showDialog(
                  context: context,
                  builder: (context) =>
                      CreateOrderStatusDialog(orderBloc: _orderBloc),
                );
                print('OrderScreen: Диалог создания статуса закрыт');
              },
              child: const Text(
                '+',
                style: TextStyle(
                  fontSize: 24,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                  color: Color(0xff1E2E52),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
