import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/database_service.dart';

class StatisticsScreen extends StatefulWidget {
  final int userId;

  const StatisticsScreen({super.key, required this.userId});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _selectedPeriod = 'month';
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  List<Map<String, dynamic>> _statistics = [];
  List<Map<String, dynamic>> _total = [];
  bool _isLoading = true;

  final List<String> _periods = [
    '今日',
    '本周',
    '本月',
    '本年',
    '自定义',
  ];

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  DateTimeRange _getDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case '今日':
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case '本周':
        final start = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(
          start: DateTime(start.year, start.month, start.day),
          end: now,
        );
      case '本月':
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
      case '本年':
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: now,
        );
      default:
        return DateTimeRange(
          start: _customStartDate ?? now,
          end: _customEndDate ?? now,
        );
    }
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    try {
      final range = _getDateRange();
      final statistics = await DatabaseService.instance.getStatistics(
        widget.userId,
        startDate: range.start,
        endDate: range.end,
      );
      final total = await DatabaseService.instance.getTotal(
        widget.userId,
        startDate: range.start,
        endDate: range.end,
      );

      setState(() {
        _statistics = statistics;
        _total = total;
      });
    } catch (e) {
      print('Error loading statistics: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _selectedPeriod = '自定义';
      });
      _loadStatistics();
    }
  }

  double _getTotalByType(String type) {
    final item = _total.firstWhere(
      (t) => t['type'] == type,
      orElse: () => {'total': 0},
    );
    return (item['total'] as num?)?.toDouble() ?? 0.0;
  }

  String _getCategoryIcon(String category) {
    const icons = {
      '工资': '💰',
      '奖金': '🎁',
      '兼职': '💼',
      '餐饮': '🍜',
      '交通': '🚗',
      '购物': '🛒',
      '教育': '📚',
      '医疗': '💊',
    };
    return icons[category] ?? '📝';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalIncome = _getTotalByType('income');
    final totalExpense = _getTotalByType('expense');
    final balance = totalIncome - totalExpense;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间筛选
          Wrap(
            spacing: 8,
            children: _periods.map((period) {
              final isSelected = _selectedPeriod == period;
              return FilterChip(
                label: Text(period),
                selected: isSelected,
                onSelected: (selected) {
                  if (period == '自定义') {
                    _selectCustomDateRange();
                  } else {
                    setState(() => _selectedPeriod = period);
                    _loadStatistics();
                  }
                },
                selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                checkmarkColor: Theme.of(context).colorScheme.primary,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // 总览卡片
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard('总收入', totalIncome, Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard('总支出', totalExpense, Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryCard('结余', balance, Colors.blue),
          const SizedBox(height: 24),

          // 收入统计
          _buildStatisticsSection('收入统计', 'income', Colors.green),
          const SizedBox(height: 24),

          // 支出统计
          _buildStatisticsSection('支出统计', 'expense', Colors.red),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '¥${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(String title, String type, Color color) {
    final statistics = _statistics.where((s) {
      final category = s['category'];
      final incomeCategories = ['工资', '奖金', '兼职'];
      final expenseCategories = ['餐饮', '交通', '购物', '教育', '医疗'];
      
      if (type == 'income') {
        return incomeCategories.contains(category);
      } else {
        return expenseCategories.contains(category);
      }
    }).toList();

    if (statistics.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              '暂无${title.replaceFirst('统计', '')}数据',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: statistics.isEmpty
                      ? 10
                      : (statistics.map((s) => s['total'] as num).reduce((a, b) => a > b ? a : b) as double) * 1.2,
                  barGroups: statistics.map((stat) {
                    return BarChartGroupData(
                      x: statistics.indexOf(stat),
                      barRods: [
                        BarChartRodData(
                          toY: (stat['total'] as num).toDouble(),
                          color: color,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < statistics.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _getCategoryIcon(statistics[value.toInt()]['category']),
                                style: const TextStyle(fontSize: 20),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...statistics.map((stat) => ListTile(
                  dense: true,
                  leading: Text(
                    _getCategoryIcon(stat['category']),
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(stat['category']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '¥${(stat['total'] as num).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${stat['count']}笔',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}