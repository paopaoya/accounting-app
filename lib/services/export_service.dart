import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class ExportService {
  static Future<void> exportToCSV(
    List<Map<String, dynamic>> transactions,
  ) async {
    if (transactions.isEmpty) {
      throw Exception('没有数据可导出');
    }

    final buffer = StringBuffer();
    buffer.writeln('日期,类型,分类,金额,备注');

    for (var transaction in transactions) {
      final date = DateTime.fromMillisecondsSinceEpoch(
        transaction['date'] * 1000,
      );
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final type = transaction['type'] == 'income' ? '收入' : '支出';
      final category = transaction['category'];
      final amount = transaction['amount'].toString();
      final note = transaction['note']?.toString().replaceAll(',', '，') ?? '';

      buffer.writeln('$formattedDate,$type,$category,$amount,$note');
    }

    final csvData = buffer.toString();
    final fileName = '记账数据_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';

    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csvData);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '记账数据导出',
        text: '导出日期：${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
      );
    } catch (e) {
      throw Exception('导出失败: $e');
    }
  }

  static Future<void> exportToJSON(
    List<Map<String, dynamic>> transactions,
  ) async {
    if (transactions.isEmpty) {
      throw Exception('没有数据可导出');
    }

    final exportData = {
      'exportDate': DateTime.now().toIso8601String(),
      'total': transactions.length,
      'transactions': transactions.map((t) {
        return {
          'id': t['id'],
          'type': t['type'] == 'income' ? '收入' : '支出',
          'category': t['category'],
          'amount': t['amount'],
          'date': DateTime.fromMillisecondsSinceEpoch(t['date'] * 1000).toIso8601String(),
          'note': t['note'],
        };
      }).toList(),
    };

    final jsonData = JsonEncoder.withIndent('  ').convert(exportData);
    final fileName = '记账数据_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';

    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonData);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '记账数据导出',
        text: '导出日期：${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
      );
    } catch (e) {
      throw Exception('导出失败: $e');
    }
  }

  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true;
  }
}