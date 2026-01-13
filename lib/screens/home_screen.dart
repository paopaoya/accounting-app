import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import 'add_transaction_screen.dart';
import 'statistics_screen.dart';

class HomeScreen extends StatefulWidget {
  final int userId;
  final String username;

  const HomeScreen({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final transactions = await DatabaseService.instance.getTransactions(
        widget.userId,
      );
      setState(() => _transactions = transactions);
    } catch (e) {
      print('Error loading transactions: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: _buildContent(),
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
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_currentIndex == 0) {
      return _buildTransactionsList();
    } else {
      return StatisticsScreen(userId: widget.userId);
    }
  }

  Widget _buildTransactionsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              '暂无记录',
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
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        final isIncome = transaction['type'] == 'income';
        final date = DateTime.fromMillisecondsSinceEpoch(
          transaction['date'] * 1000,
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
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
            subtitle: Text(
              DateFormat('yyyy-MM-dd').format(date),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
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
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteTransaction(transaction['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}