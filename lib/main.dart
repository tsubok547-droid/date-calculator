import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja_JP');

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(const DateCalculatorApp());
  });
}

// アプリ全体で色を管理するためにStatefulWidgetに変更
class DateCalculatorApp extends StatefulWidget {
  const DateCalculatorApp({super.key});

  @override
  State<DateCalculatorApp> createState() => _DateCalculatorAppState();
}

class _DateCalculatorAppState extends State<DateCalculatorApp> {
  Color _primaryColor = Colors.indigo; // 色の初期値を設定（保存機能はない）

  void changeColor(Color color) {
    setState(() {
      _primaryColor = color; // アプリの色を更新
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '日付計算ツール',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja', ''),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _primaryColor),
        useMaterial3: true,
      ),
      home: CalculatorPage(
        onColorChanged: changeColor,
      ),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  final Function(Color) onColorChanged;
  const CalculatorPage({super.key, required this.onColorChanged});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

enum Menu { color, info }

class _CalculatorPageState extends State<CalculatorPage> {
  DateTime _selectedDate = DateTime.now();
  String _expression = '0';
  String _resultDate = '';

  final Map<String, Color> _predefinedColors = {
    'インディゴ': Colors.indigo,
    'パープル': Colors.deepPurple,
    'レッド': Colors.red.shade400,
    'イエロー': Colors.amber.shade700,
    'グリーン': Colors.green,
    'オレンジ': Colors.orange,
    'ブラウン': Colors.brown,
    'モノクロ': Colors.grey,
  };

  void _onButtonPressed(String text) {
    setState(() {
      if (text == 'C') {
        _expression = '0';
        _resultDate = '';
        return;
      }
      if (text == '←') {
        if (_expression.length > 1) {
          _expression = _expression.substring(0, _expression.length - 1);
        } else {
          _expression = '0';
        }
        return;
      }
      if (text == 'Ent') {
        _calculateDate();
        return;
      }
      if (_expression == '0' && "0123456789".contains(text)) {
        _expression = text;
        return;
      }
      if ("+-".contains(text)) {
        String lastChar = _expression.substring(_expression.length - 1);
        if ("+-".contains(lastChar)) {
          _expression = _expression.substring(0, _expression.length - 1) + text;
        } else {
          _expression += text;
        }
        return;
      }
      _expression += text;
    });
  }

  void _calculateDate() {
    try {
      String finalExpression = _expression;
      String lastChar = _expression.substring(_expression.length - 1);
      if ("+-".contains(lastChar)) {
        finalExpression = _expression.substring(0, _expression.length - 1);
      }
      Parser p = Parser();
      Expression exp = p.parse(finalExpression);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);
      final int days = eval.toInt();
      final DateTime futureDate = _selectedDate.add(Duration(days: days));
      final String formattedDate = DateFormat('yyyy年M月d日(E)', 'ja_JP').format(futureDate);
      setState(() {
        _resultDate = '→ $formattedDate';
        _expression = eval.toInt().toString();
      });
    } catch (e) {
      setState(() {
        _resultDate = '式が正しくありません';
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      if (_expression.isNotEmpty && _expression != '0') {
        final lastChar = _expression.substring(_expression.length - 1);
        if (!"+-".contains(lastChar)) {
          _calculateDate();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日付 計算ツール'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          MenuAnchor(
            builder: (BuildContext context, MenuController controller, Widget? child) {
              return IconButton(
                onPressed: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
                icon: const Icon(Icons.more_vert),
                tooltip: 'メニュー',
              );
            },
            menuChildren: [
              SubmenuButton(
                menuChildren: [
                  ..._predefinedColors.entries.map((entry) {
                    return MenuItemButton(
                      onPressed: () => widget.onColorChanged(entry.value),
                      child: Text(entry.key),
                    );
                  }).toList(),
                  const Divider(),
                  MenuItemButton(
                    onPressed: () => _showColorPicker(context),
                    child: const Text('カスタム...'),
                  ),
                ],
                child: const Text('テーマカラーを変更'),
              ),
              MenuItemButton(
                onPressed: () => _showVersionInfo(context),
                child: const Text('バージョン情報'),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('開始日:', style: TextStyle(fontSize: 16)),
                TextButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    DateFormat('yyyy年M月d日(E)', 'ja_JP').format(_selectedDate),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _selectDate(context),
                ),
              ],
            ),
            const Divider(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: Text(
                _expression,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 50,
              child: Center(
                child: Text(
                  _resultDate,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                ),
              ),
            ),
            Expanded(child: _buildKeypad()),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        Expanded(child: Row(children: [_buildKeypadButton('7'), _buildKeypadButton('8'), _buildKeypadButton('9'), _buildKeypadButton('+')])),
        Expanded(child: Row(children: [_buildKeypadButton('4'), _buildKeypadButton('5'), _buildKeypadButton('6'), _buildKeypadButton('-')])),
        Expanded(child: Row(children: [_buildKeypadButton('1'), _buildKeypadButton('2'), _buildKeypadButton('3'), _buildKeypadButton('←')])),
        Expanded(
          child: Row(
            children: [
              _buildKeypadButton('C'),
              _buildKeypadButton('0', flex: 2),
              _buildKeypadButton('Ent'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKeypadButton(String text, {int flex = 1}) {
    final bool isNumberButton = "0123456789".contains(text);
    final Color? buttonColor = isNumberButton 
      ? null 
      : Theme.of(context).colorScheme.primaryContainer;
    
    final Color? textColor = isNumberButton
      ? null
      : Theme.of(context).colorScheme.onPrimaryContainer;

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(double.infinity),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            backgroundColor: buttonColor,
            foregroundColor: textColor,
            textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          onPressed: () => _onButtonPressed(text),
          child: Text(text),
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    Color pickerColor = Theme.of(context).colorScheme.primary;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('カスタムカラーを選択'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (Color color) {
                pickerColor = color;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('決定'),
              onPressed: () {
                widget.onColorChanged(pickerColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showVersionInfo(BuildContext context) async {
    final packageInfo = await PackageInfo.fromPlatform();
    showAboutDialog(
      context: context,
      applicationName: '日付計算ツール',
      applicationVersion: packageInfo.version,
      applicationLegalese: '© 2025 t-BocSoft',
    );
  }
}