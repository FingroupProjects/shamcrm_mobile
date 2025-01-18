import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/dashboard_charts_models_manager/user_task_model.dart';
import 'package:crm_task_manager/models/user_byId_model..dart';
import 'package:crm_task_manager/screens/dashboard_for_manager/CACHE/users_chart_manager_cache.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

class GoalCompletionChart extends StatefulWidget {
  const GoalCompletionChart({Key? key}) : super(key: key);

  @override
  State<GoalCompletionChart> createState() => _GoalCompletionChartState();
}

class _GoalCompletionChartState extends State<GoalCompletionChart> {
  final List<String> months = const [
    'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
  ];
  String? userName;
  int currentMonth = DateTime.now().month - 1; // 0-based index (январь - 0, февраль - 1, ...)
  double currentMonthProgress = 0; // Начальный примерный прогресс
  List<double> monthlyData = []; // Список для данных с сервера
  bool isLoading = true; // Переменная для отслеживания загрузки данных

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadUserStatsFromCache();  // Загружаем данные из кэша сразу
  }

Future<void> _loadUserName() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Загружаем ID пользователя из кеша
    String userId = prefs.getString('userID') ?? '';

    // Загружаем имя пользователя из кеша, если оно есть
    String? savedUserName = prefs.getString('userName');

    // Если ID пользователя пустое, значит пользователь не авторизован или нет данных
    if (userId.isEmpty) {
      setState(() {
        userName = savedUserName ?? ''; // Если имя в кеше отсутствует, оставляем пустую строку
      });
      return;
    }

    // Если ID пользователя есть, пробуем получить имя из кеша или API
    if (savedUserName != null && savedUserName.isNotEmpty) {
      // Если имя пользователя уже сохранено в кеше, используем его
      setState(() {
        userName = savedUserName;
      });
    } else {
      // Иначе, загружаем имя из API
      UserByIdProfile userProfile = await ApiService().getUserById(int.parse(userId));
      setState(() {
        userName = userProfile.name ?? ''; // В случае отсутствия имени в API, оставляем пустую строку
      });

      // Сохраняем имя в кеш
      if (userName!.isNotEmpty) {
        prefs.setString('userName', userName!);
      }
    }
  } catch (e) {
    print('Ошибка при загрузке имени пользователя: $e');
    setState(() {
      userName = ''; // В случае ошибки, ставим пустую строку
    });
  }
}

  // Загружаем данные о задачах из кэша
  Future<void> _loadUserStatsFromCache() async {
    try {
      List<double>? cachedData = await UserTaskCompletionCacheHandler.getUserTaskCompletionData();
      if (cachedData != null && cachedData.isNotEmpty) {
        setState(() {
          monthlyData = cachedData;
          currentMonthProgress = monthlyData.isNotEmpty && currentMonth < monthlyData.length
              ? monthlyData[currentMonth] : 0.0;
          isLoading = false; 
        });
      }
      _loadUserStatsFromApi(); 
    } catch (e) {
      print('Ошибка при загрузке данных о задачах из кэша: $e');
      _loadUserStatsFromApi(); 
    }
  }

  // Загружаем данные о задачах из API
  Future<void> _loadUserStatsFromApi() async {
    try {
      UserTaskCompletionManager data = await ApiService().getUserStatsManager();
      setState(() {
        monthlyData = data.finishedTasksPercent;
        currentMonthProgress = monthlyData.isNotEmpty && currentMonth < monthlyData.length ? monthlyData[currentMonth] : 0.0; 
        isLoading = false; 
      });
      await UserTaskCompletionCacheHandler.saveUserTaskCompletionData(monthlyData);
    } catch (e) {
      print('Ошибка при загрузке данных с API: $e');
    }
  }

  String formatPercent(double value) {
    if (value == 100 || value == 0 || value % 1 == 0) {
      return '${value.toInt()}%';
    }
    return '${value.toStringAsFixed(2)}%';
  }

  Color getBarColor(double percent) {
    if (percent == 0) {
      return const Color.fromARGB(255, 173, 172, 172); // Gray (0%)
    } else if (percent > 0 && percent <= 30) {
      return const Color(0xFFC30202); // Red (1-30%)
    } else if (percent < 100) {
      return const Color(0xFF3935E7); // Blue (31-99%)
    } else {
      return const Color(0xFF27A945); // Green (100%)
    }
  }

  Widget _buildCurrentMonthProgress() {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                userName ?? '',
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              Text(
                '${months[currentMonth]} ${formatPercent(currentMonthProgress)}',
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: currentMonthProgress / 100,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              getBarColor(currentMonthProgress),
            ),
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataChart() {
    return Column(
      children: [
        const SizedBox(height: 10),
        const Text(
          'Нет данных для отображения',
          style: TextStyle(
            fontSize: 16,
            fontFamily: "Gilroy",
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        Container(
          height: 300,
          padding: const EdgeInsets.fromLTRB(4, 16, 16, 16),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 100,
              minY: 0,
              groupsSpace: 12,
              backgroundColor: Colors.white,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipRoundedRadius: 6,
                  tooltipPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  tooltipMargin: 4,
                  fitInsideVertically: true,
                  fitInsideHorizontally: true,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${months[groupIndex]}\n',
                      const TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      children: [
                        TextSpan(
                          text: formatPercent(rod.toY),
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value < 0 || value >= months.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Transform.rotate(
                          angle: -1.55,
                          child: Text(
                            months[value.toInt()],
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      );
                    },
                    reservedSize: 40,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return SizedBox(
                        width: 60,
                        child: Text(
                          formatPercent(value),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      );
                    },
                    reservedSize: 35,
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                drawVerticalLine: true,
                horizontalInterval: 20,
                verticalInterval: 1,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  );
                },
                getDrawingVerticalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.1),
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  left: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
              ),
              barGroups: List.generate(
                months.length,
                (index) => BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: 0.0, // Показать 0 для всех месяцев
                      color: const Color.fromARGB(255, 173, 172, 172), // Gray (0%)
                      width: 20,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    bool allDataZero = monthlyData.isEmpty || monthlyData.every((element) => element == 0.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Выполнение целей',
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        // Прогресс для текущего месяца
        _buildCurrentMonthProgress(),
        // График с данными за месяц
        allDataZero ? _buildNoDataChart() : Container(
          height: 300,
          padding: const EdgeInsets.fromLTRB(4, 16, 16, 16),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 100,
              minY: 0,
              groupsSpace: 12,
              backgroundColor: Colors.white,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipRoundedRadius: 6,
                  tooltipPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  tooltipMargin: 4,
                  fitInsideVertically: true,
                  fitInsideHorizontally: true,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${months[groupIndex]}\n',
                      const TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      children: [
                        TextSpan(
                          text: formatPercent(rod.toY),
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value < 0 || value >= months.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Transform.rotate(
                          angle: -1.55,
                          child: Text(
                            months[value.toInt()],
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      );
                    },
                    reservedSize: 40,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return SizedBox(
                        width: 60,
                        child: Text(
                          formatPercent(value),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      );
                    },
                    reservedSize: 35,
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                drawVerticalLine: true,
                horizontalInterval: 20,
                verticalInterval: 1,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  );
                },
                getDrawingVerticalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.1),
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  left: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
              ),
              barGroups: List.generate(
                months.length,
                (index) => BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: monthlyData.isNotEmpty && index < monthlyData.length
                          ? monthlyData[index]
                          : 0.0009, // Защита от пустых данных
                      color: const Color(0xFF3935E7), // Установили один цвет для всех месяцев
                      width: 20,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
