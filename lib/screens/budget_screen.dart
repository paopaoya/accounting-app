import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';

class BudgetScreen extends StatefulWidget {
  final int userId;

  const BudgetScreen({super.key, required this.userId});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  DateTime _selectedMonth = DateTime.now();
  Map<String, dynamic> _budgetUsage = {};
  List<Map<String, dynamic>> _budgets = [];
  bool _isLoading = true;

  final List<String> _categories = ['餐饮', '交通', '购物', '教育', '医疗'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final month = DateFormat('yyyy-MM').format(_selectedMonth);
      final budgets = await DatabaseService.instance.getBudgets(
        widget.userId,
        month: month,
      );
      final budgetUsage = await DatabaseService.instance.getBudgetUsage(
        widget.userId,
        month,
      );

      setState(() {
        _budgets = budgets;
        _budgetUsage = budgetUsage;
      });
    } catch (e) {
      print('Error loading budget data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
      });
      _loadData();
    }
  }

  Future<void> _addBudget() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddBudgetSheet(
        userId: widget.userId,
        month: DateFormat('yyyy-MM').format(_selectedMonth),
        categories: _categories,
        onAdded: _loadData,
      ),
    );
  }

  Future<void> _editBudget(Map<String, dynamic> budget) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EditBudgetSheet(
        budget: budget,
        onUpdated: _loadData,
      ),
    );
  }

  Future<void> _deleteBudget(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个预算吗？'),
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
      await DatabaseService.instance.deleteBudget(id);
      _loadData();
    }
  }

  String _getCategoryIcon(String category) {
    const icons = {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('预算管理'),
      ),
      body: Column(
        children: [
          // 月份选择
          Container(
            padding: const EdgeInsets.all(16),
            child: InkWell(
              onTap: _selectMonth,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('yyyy年MM月').format(_selectedMonth),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
          ),

          // 预算列表
          Expanded(
            child: _budgets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '暂无预算',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '点击下方按钮添加预算',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _budgets.length,
                    itemBuilder: (context, index) {
                      final budget = _budgets[index];
                      final category = budget['category'];
                      final usage = _budgetUsage[category] ?? {};
                      final percentage = (usage['percentage'] ?? 0).toDouble();
                      final isOverBudget = percentage > 100;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        _getCategoryIcon(category),
                                        style: const TextStyle(fontSize: 28),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        category,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: () => _editBudget(budget),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () => _deleteBudget(budget['id']),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: percentage / 100,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isOverBudget
                                        ? Colors.red
                                        : percentage > 80
                                            ? Colors.orange
                                            : Colors.green,
                                  ),
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '已用: ¥${(usage['spent'] ?? 0).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: isOverBudget ? Colors.red : Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    '预算: ¥${budget['amount'].toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    '${percentage.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isOverBudget
                                          ? Colors.red
                                          : percentage > 80
                                              ? Colors.orange
                                              : Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              if (usage['remaining'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    '剩余: ¥${(usage['remaining'] as num).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: (usage['remaining'] as num) < 0
                                          ? Colors.red
                                          : Colors.green[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addBudget,
        icon: const Icon(Icons.add),
        label: const Text('添加预算'),
      ),
    );
  }
}

class _AddBudgetSheet extends StatefulWidget {
  final int userId;
  final String month;
  final List<String> categories;
  final VoidCallback onAdded;

  const _AddBudgetSheet({
    required this.userId,
    required this.month,
    required this.categories,
    required this.onAdded,
  });

  @override
  State<_AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends State<_AddBudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) return;

    setState(() => _isLoading = true);

    try {
      await DatabaseService.instance.addBudget({
        'user_id': widget.userId,
        'category': _selectedCategory,
        'amount': double.parse(_amountController.text),
        'month': widget.month,
      });

      if (mounted) {
        Navigator.pop(context);
        widget.onAdded();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('添加失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '添加预算',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '预算金额',
                  hintText: '请输入预算金额',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入预算金额';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return '请输入有效的金额';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                '选择分类',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: widget.categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return FilterChip(
                    label: Text('${_getCategoryIcon(category)} $category'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedCategory = category);
                    },
                    selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('添加'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryIcon(String category) {
    const icons = {
      '餐饮': '🍜',
      '交通': '🚗',
      '购物': '🛒',
      '教育': '📚',
      '医疗': '💊',
    };
    return icons[category] ?? '📝';
  }
}

class _EditBudgetSheet extends StatefulWidget {
  final Map<String, dynamic> budget;
  final VoidCallback onUpdated;

  const _EditBudgetSheet({
    required this.budget,
    required this.onUpdated,
  });

  @override
  State<_EditBudgetSheet> createState() => _EditBudgetSheetState();
}

class _EditBudgetSheetState extends State<_EditBudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.budget['amount'].toString(),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await DatabaseService.instance.updateBudget(
        widget.budget['id'],
        {'amount': double.parse(_amountController.text)},
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onUpdated();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '编辑预算',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '预算金额',
                  hintText: '请输入预算金额',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入预算金额';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return '请输入有效的金额';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('更新'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}