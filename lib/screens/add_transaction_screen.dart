import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';

class AddTransactionScreen extends StatefulWidget {
  final int userId;
  final Map<String, dynamic>? transaction;

  const AddTransactionScreen({
    super.key,
    required this.userId,
    this.transaction,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _type = 'income';
  String? _selectedCategory;
  bool _isLoading = false;

  final List<String> _incomeCategories = ['工资', '奖金', '兼职'];
  final List<String> _expenseCategories = ['餐饮', '交通', '购物', '教育', '医疗'];

  Map<String, String> get categoryIcons => {
        '工资': '💰',
        '奖金': '🎁',
        '兼职': '💼',
        '餐饮': '🍜',
        '交通': '🚗',
        '购物': '🛒',
        '教育': '📚',
        '医疗': '💊',
      };

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _type = widget.transaction!['type'];
      _selectedCategory = widget.transaction!['category'];
      _amountController.text = widget.transaction!['amount'].toString();
      _noteController.text = widget.transaction!['note'] ?? '';
      _selectedDate = DateTime.fromMillisecondsSinceEpoch(
        widget.transaction!['date'] * 1000,
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择分类')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final transactionData = {
        'type': _type,
        'category': _selectedCategory,
        'amount': double.parse(_amountController.text),
        'date': _selectedDate.millisecondsSinceEpoch ~/ 1000,
        'note': _noteController.text.trim(),
      };

      if (widget.transaction != null) {
        await DatabaseService.instance.updateTransaction(
          widget.transaction!['id'],
          transactionData,
        );
      } else {
        transactionData['user_id'] = widget.userId;
        await DatabaseService.instance.addTransaction(transactionData);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.transaction != null ? "更新" : "添加"}失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _type == 'income' ? _incomeCategories : _expenseCategories;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction != null ? '编辑记录' : '添加记录'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 收入/支出切换
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'income',
                  label: Text('💰 收入'),
                ),
                ButtonSegment(
                  value: 'expense',
                  label: Text('💸 支出'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _type = newSelection.first;
                  _selectedCategory = null;
                });
              },
            ),
            const SizedBox(height: 24),

            // 金额输入
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '金额',
                hintText: '请输入金额',
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入金额';
                }
                if (double.tryParse(value) == null || double.parse(value) <= 0) {
                  return '请输入有效的金额';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 日期选择
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '日期',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  DateFormat('yyyy-MM-dd').format(_selectedDate),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 分类选择
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
              children: categories.map((category) {
                final isSelected = _selectedCategory == category;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: FilterChip(
                    label: Text('${categoryIcons[category]} $category'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedCategory = category);
                    },
                    selectedColor: Colors.transparent,
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // 备注输入
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
                hintText: '请输入备注',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // 提交按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
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
                    : Text(widget.transaction != null ? '更新' : '添加'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}