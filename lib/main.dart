import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja_JP');

  final prefs = await SharedPreferences.getInstance();
  final colorValue = prefs.getInt('primaryColor') ?? Colors.indigo.value;
  final primaryColor = Color(colorValue);

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(DateCalculatorApp(primaryColor: primaryColor));
  });
}

class DateCalculatorApp extends StatefulWidget {
  final Color primaryColor;
  const DateCalculatorApp({super.key, required this.primaryColor});

  @override
  State<DateCalculatorApp> createState() => _DateCalculatorAppState();
}

class _DateCalculatorAppState extends State<DateCalculatorApp> {
  late Color _primaryColor;

  @override
  void initState() {
    super.initState();
    _primaryColor = widget.primaryColor;
  }

  void changeColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('primaryColor', color.value);
    setState(() {
      _primaryColor = color;
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
  List<String> _history = []; // ① 履歴を保持するリスト

  @override
  void initState() {
    super.initState();
    _loadHistory(); // ② アプリ起動時に履歴を読み込む
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _history = prefs.getStringList('calcHistory') ?? [];
    });
  }

  final Map<String, Color> _predefinedColors = {
    'インディゴ': Colors.indigo,
    'アッシュグレー': Color(0xFF78909C),
    'ダスティミント': Color(0xFF80CBC4),
    'スカイブルー': Color(0xFF64B5F6),
    'ラベンダー': Color(0xFFB39DDB),
    'アイボリー': Color(0xFFFFF9C4),
    'ダスティローズ': Color(0xFFE57373),
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
        // ③ Entボタン押下時のみ履歴に保存する
        _calculateDate(saveToHistory: true);
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

  // ④ 履歴に保存するかどうかを引数で制御
  void _calculateDate({bool saveToHistory = false}) async {
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
      final String formattedDate =
          DateFormat('yyyy年M月d日(E)', 'ja_JP').format(futureDate);
      
      if (saveToHistory) {
        final historyEntry =
            "${DateFormat('yyyy/MM/dd').format(_selectedDate)} ${finalExpression.replaceAllMapped(RegExp(r'(\d+)'), (m) => m.group(0)!).replaceAll('-', ' - ').replaceAll('+', ' + ')} = ${DateFormat('yyyy/MM/dd').format(futureDate)}";
        
        setState(() {
          _history.insert(0, historyEntry); // 新しい履歴をリストの先頭に追加
          
          // 履歴が30件を超えたら古いものを削除
          while (_history.length > 30) {
            _history.removeLast();
          }
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('calcHistory', _history); // 履歴を保存
      }

      setState(() {
        _resultDate = '→ $formattedDate';
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
          _calculateDate(saveToHistory: false); // ⑤ 開始日変更時は履歴に保存しない
        }
      }
    }
  }

  // ⑥ 履歴ページへ移動する処理
  void _navigateToHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryPage(),
      ),
    );
    // 履歴ページから戻ってきたら、履歴を再読み込みする（クリアされた場合を反映するため）
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日付 計算ツール'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          MenuAnchor(
            builder:
                (BuildContext context, MenuController controller, Widget? child) {
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
              // ⑦ メニューに「計算履歴」を追加
              MenuItemButton(
                onPressed: _navigateToHistory,
                child: const Text('計算履歴'),
              ),
              const Divider(),
              SubmenuButton(
                menuChildren: [
                  ..._predefinedColors.entries.map((entry) {
                    return MenuItemButton(
                      onPressed: () => widget.onColorChanged(entry.value),
                      child: Text(entry.key),
                    );
                  }),
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
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
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
                style:
                    const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 50,
              child: Center(
                child: Text(
                  _resultDate,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor),
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
    // ... （このウィジェットのコードは変更ありません）
    return Column(
      children: [
        Expanded(
            child: Row(children: [
          _buildKeypadButton('7'),
          _buildKeypadButton('8'),
          _buildKeypadButton('9'),
          _buildKeypadButton('+')
        ])),
        Expanded(
            child: Row(children: [
          _buildKeypadButton('4'),
          _buildKeypadButton('5'),
          _buildKeypadButton('6'),
          _buildKeypadButton('-')
        ])),
        Expanded(
            child: Row(children: [
          _buildKeypadButton('1'),
          _buildKeypadButton('2'),
          _buildKeypadButton('3'),
          _buildKeypadButton('←')
        ])),
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
    // ... （このウィジェットのコードは変更ありません）
    final bool isNumberButton = "0123456789".contains(text);
    final Color? buttonColor =
        isNumberButton ? null : Theme.of(context).colorScheme.primaryContainer;

    final Color? textColor =
        isNumberButton ? null : Theme.of(context).colorScheme.onPrimaryContainer;

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(double.infinity),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12))),
            backgroundColor: buttonColor,
            foregroundColor: textColor,
            textStyle:
                const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          onPressed: () => _onButtonPressed(text),
          child: Text(text),
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    // ... （このメソッドのコードは変更ありません）
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
    // ... （このメソッドのコードは変更ありません）
    final packageInfo = await PackageInfo.fromPlatform();
    if (!context.mounted) return;
    showAboutDialog(
      context: context,
      applicationName: '日付計算ツール',
      applicationVersion: packageInfo.version,
      applicationLegalese: '© 2025 t-BocSoft',
    );
  }
}

// ⑧ 履歴表示用の新しいページウィジェット
class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _history = prefs.getStringList('calcHistory') ?? [];
    });
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('calcHistory');
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('計算履歴'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline),
            tooltip: '履歴をクリア',
            onPressed: _history.isEmpty ? null : () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('履歴をクリア'),
                  content: Text('すべての計算履歴を削除しますか？'),
                  actions: [
                    TextButton(
                      child: Text('キャンセル'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    TextButton(
                      child: Text('削除'),
                      onPressed: () {
                        _clearHistory();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _history.isEmpty
          ? Center(
              child: Text(
                '計算履歴はありません。',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            )
          : ListView.separated(
              itemCount: _history.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    _history[index],
                    style: TextStyle(fontSize: 16),
                  ),
                );
              },
              separatorBuilder: (context, index) => const Divider(),
            ),
    );
  }
}