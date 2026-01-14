import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/export_service.dart';
import 'add_transaction_screen.dart';
import 'statistics_screen.dart';
import 'budget_screen.dart';
import 'animated_filter_chip.dart';

class HomeScreen extends StatefulWidget {
  final int userId;
  final String username;
  final VoidCallback? toggleTheme;
  final bool isDarkMode;

  const HomeScreen({
    super.key,
    required this.userId,
    required this.username,
    this.toggleTheme,
    this.isDarkMode = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String? _filterType;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  bool _showFilters = false;
  late bool isDarkMode;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode;
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final transactions = await DatabaseService.instance.getTransactions(
        widget.userId,
      );
      setState(() {
        _transactions = transactions;
        _applyFilters();
      });
    } catch (e) {
      print('Error loading transactions: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    _filteredTransactions = _transactions.where((transaction) {
      bool matches = true;

      if (_searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        matches = matches &&
            (transaction['category'].toString().toLowerCase().contains(query) ||
                (transaction['note']?.toString().toLowerCase().contains(query) ?? false));
      }

      if (_filterType != null) {
        matches = matches && transaction['type'] == _filterType;
      }

      if (_filterStartDate != null) {
        final date = DateTime.fromMillisecondsSinceEpoch(transaction['date'] * 1000);
        matches = matches && date.isAfter(_filterStartDate!) || date.isAtSameMomentAs(_filterStartDate!);
      }

      if (_filterEndDate != null) {
        final date = DateTime.fromMillisecondsSinceEpoch(transaction['date'] * 1000);
        matches = matches && date.isBefore(_filterEndDate!) || date.isAtSameMomentAs(_filterEndDate!);
      }

      return matches;
    }).toList();
  }

  Future<void> _deleteTransaction(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseService.instance.deleteTransaction(id);
      _loadTransactions();
    }
  }

  Future<void> _editTransaction(Map<String, dynamic> transaction) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(
          userId: widget.userId,
          transaction: transaction,
        ),
      ),
    );
    if (result == true) {
      _loadTransactions();
    }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('记账本'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() => _showFilters = !_showFilters);
            },
          ),
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: toggleTheme,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'export_csv') {
                _exportData('csv');
              } else if (value == 'export_json') {
                _exportData('json');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart),
                    SizedBox(width: 12),
                    Text('导出 CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export_json',
                child: Row(
                  children: [
                    Icon(Icons.code),
                    SizedBox(width: 12),
                    Text('导出 JSON'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showFilters) _buildFilters(),
          Expanded(child: _buildContent()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionScreen(userId: widget.userId),
            ),
          );
          if (result == true) {
            _loadTransactions();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('记账'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: '记账',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: '统计',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet),
            label: '预算',
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_currentIndex == 0) {
      return _buildTransactionsList();
    } else if (_currentIndex == 1) {
      return StatisticsScreen(userId: widget.userId);
    } else {
      return BudgetScreen(userId: widget.userId);
    }
  }

  Widget _buildFilters() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: _showFilters
          ? Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '搜索分类或备注...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _applyFilters();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                      ),
                      onChanged: (_) => _applyFilters(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      AnimatedFilterChip(
                        label: const Text('全部'),
                        selected: _filterType == null,
                        onSelected: (selected) {
                          setState(() {
                            _filterType = selected ? null : _filterType;
                            _applyFilters();
                          });
                        },
                      ),
                      AnimatedFilterChip(
                        label: const Text('💰 收入'),
                        selected: _filterType == 'income',
                        onSelected: (selected) {
                          setState(() {
                            _filterType = selected ? 'income' : null;
                            _applyFilters();
                          });
                        },
                      ),
                      AnimatedFilterChip(
                        label: const Text('💸 支出'),
                        selected: _filterType == 'expense',
                        onSelected: (selected) {
                          setState(() {
                            _filterType = selected ? 'expense' : null;
                            _applyFilters();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _selectDateRange,
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _filterStartDate != null && _filterEndDate != null
                          ? '${_filterStartDate!.month}/${_filterStartDate!.day} - ${_filterEndDate!.month}/${_filterEndDate!.day}'
                          : '选择日期',
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _filterStartDate = picked.start;
        _filterEndDate = picked.end;
        _applyFilters();
      });
    }
  }

  Future<void> _exportData(String format) async {
    try {
      final hasPermission = await ExportService.requestStoragePermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('需要存储权限才能导出数据')),
          );
        }
        return;
      }

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (format == 'csv') {
        await ExportService.exportToCSV(_filteredTransactions);
      } else {
        await ExportService.exportToJSON(_filteredTransactions);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出${format.toUpperCase()}成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  Widget _buildTransactionsList() {

      if (_isLoading) {

        return const Center(child: CircularProgressIndicator());

      }

  

      if (_filteredTransactions.isEmpty) {

        return Center(

          child: Column(

            mainAxisAlignment: MainAxisAlignment.center,

            children: [

              Icon(

                _transactions.isEmpty ? Icons.receipt_long : Icons.search_off,

                size: 80,

                color: Colors.grey[300],

              ),

              const SizedBox(height: 16),

              Text(

                _transactions.isEmpty ? '暂无记录' : '没有找到匹配的记录',

                style: TextStyle(

                  fontSize: 18,

                  color: Colors.grey[600],

                ),

              ),

            ],

          ),

        );

      }

  

      return ListView.builder(

  

            padding: const EdgeInsets.all(16),

  

            itemCount: _filteredTransactions.length,

  

            itemBuilder: (context, index) {

  

              final transaction = _filteredTransactions[index];

  

              final isIncome = transaction['type'] == 'income';

  

              final date = DateTime.fromMillisecondsSinceEpoch(

  

                transaction['date'] * 1000,

  

              );

  

      

  

              return TweenAnimationBuilder<double>(

  

                duration: Duration(milliseconds: 300 + (index * 50)),

  

                tween: Tween(begin: 0, end: 1),

  

                builder: (context, value, child) {

  

                  return Transform.translate(

  

                    offset: Offset(0, 20 * (1 - value)),

  

                    child: Opacity(

  

                      opacity: value,

  

                      child: child,

  

                    ),

  

                  );

  

                },

  

                child: Card(

  

                  margin: const EdgeInsets.only(bottom: 12),

  

                  child: InkWell(

  

                    onTap: () => _editTransaction(transaction),

  

                    borderRadius: BorderRadius.circular(16),

  

                    child: ListTile(

  

                      leading: CircleAvatar(

  

                        backgroundColor: isIncome

  

                            ? Colors.green.withOpacity(0.1)

  

                            : Colors.red.withOpacity(0.1),

  

                        child: Text(

  

                          _getCategoryIcon(transaction['category']),

  

                          style: const TextStyle(fontSize: 24),

  

                        ),

  

                      ),

  

                      title: Text(

  

                        transaction['category'],

  

                        style: const TextStyle(fontWeight: FontWeight.bold),

  

                      ),

  

                      subtitle: Column(

  

                        crossAxisAlignment: CrossAxisAlignment.start,

  

                        children: [

  

                          Text(

  

                            DateFormat('yyyy-MM-dd').format(date),

  

                            style: TextStyle(

  

                              color: Colors.grey[600],

  

                              fontSize: 12,

  

                            ),

  

                          ),

  

                          if (transaction['note'] != null && transaction['note'].toString().isNotEmpty)

  

                            Text(

  

                              transaction['note'],

  

                              style: TextStyle(

  

                                color: Colors.grey[500],

  

                                fontSize: 11,

  

                              ),

  

                              maxLines: 1,

  

                              overflow: TextOverflow.ellipsis,

  

                            ),

  

                        ],

  

                      ),

  

                      trailing: Row(

  

                        mainAxisSize: MainAxisSize.min,

  

                        children: [

  

                          Text(

  

                            '${isIncome ? '+' : '-'}¥${transaction['amount'].toStringAsFixed(2)}',

  

                            style: TextStyle(

  

                              fontSize: 18,

  

                              fontWeight: FontWeight.bold,

  

                              color: isIncome ? Colors.green : Colors.red,

  

                            ),

  

                          ),

  

                          IconButton(

  

                            icon: const Icon(Icons.edit_outlined),

  

                            onPressed: () => _editTransaction(transaction),

  

                          ),

  

                          IconButton(

  

                            icon: const Icon(Icons.delete_outline),

  

                            onPressed: () => _deleteTransaction(transaction['id']),

  

                          ),

  

                        ],

  

                      ),

  

                    ),

  

                  ),

  

                ),

  

              );

  

            },

  

          );

    }
}