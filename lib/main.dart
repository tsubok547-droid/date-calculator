import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

String toJapaneseEra(DateTime date) {
  final int year = date.year;
  final String dayOfWeek = DateFormat.E('ja_JP').format(date);

  if (year >= 2019) {
    final int reiwaYear = year - 2018;
    return '令和${reiwaYear == 1 ? '元' : reiwaYear}年${date.month}月${date.day}日($dayOfWeek)';
  } else if (year >= 1989) {
    final int heiseiYear = year - 1988;
    return '平成${heiseiYear == 1 ? '元' : heiseiYear}年${date.month}月${date.day}日($dayOfWeek)';
  } else if (year >= 1926) {
    final int showaYear = year - 1925;
    return '昭和${showaYear == 1 ? '元' : showaYear}年${date.month}月${date.day}日($dayOfWeek)';
  }
  return DateFormat('yyyy年M月d日(E)', 'ja_JP').format(date);
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja_JP');

  final prefs = await SharedPreferences.getInstance();
  final colorValue = prefs.getInt('primaryColor') ?? Colors.indigo.value;
  final primaryColor = Color(colorValue);
  final isJapaneseCalendar = prefs.getBool('isJapaneseCalendar') ?? false;


  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(DateCalculatorApp(primaryColor: primaryColor, isJapaneseCalendar: isJapaneseCalendar));
  });
}

class DateCalculatorApp extends StatefulWidget {
  final Color primaryColor;
  final bool isJapaneseCalendar;
  const DateCalculatorApp({super.key, required this.primaryColor, required this.isJapaneseCalendar});

  @override
  State<DateCalculatorApp> createState() => _DateCalculatorAppState();
}

class _DateCalculatorAppState extends State<DateCalculatorApp> {
  late Color _primaryColor;
  late bool _isJapaneseCalendar;

  @override
  void initState() {
    super.initState();
    _primaryColor = widget.primaryColor;
    _isJapaneseCalendar = widget.isJapaneseCalendar;
  }

  void changeColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('primaryColor', color.value);
    setState(() {
      _primaryColor = color;
    });
  }
  
  void toggleCalendarMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isJapaneseCalendar = !_isJapaneseCalendar;
    });
    await prefs.setBool('isJapaneseCalendar', _isJapaneseCalendar);
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
        isJapaneseCalendar: _isJapaneseCalendar,
        onCalendarModeChanged: toggleCalendarMode,
      ),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  final Function(Color) onColorChanged;
  final bool isJapaneseCalendar;
  final VoidCallback onCalendarModeChanged;

  const CalculatorPage({
    super.key, 
    required this.onColorChanged, 
    required this.isJapaneseCalendar,
    required this.onCalendarModeChanged
  });

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

enum ActiveField { standardDate, daysExpression, finalDate }

class CalculationState {
  DateTime standardDate;
  String daysExpression;
  DateTime? finalDate;
  ActiveField activeField;

  CalculationState({
    required this.standardDate,
    required this.daysExpression,
    this.finalDate,
    this.activeField = ActiveField.daysExpression,
  });

  Map<String, dynamic> toJson() => {
        'standardDate': standardDate.toIso8601String(),
        'daysExpression': daysExpression,
        'finalDate': finalDate?.toIso8601String(),
      };

  factory CalculationState.fromJson(Map<String, dynamic> json) =>
      CalculationState(
        standardDate: DateTime.parse(json['standardDate']),
        daysExpression: json['daysExpression'],
        finalDate: json['finalDate'] != null
            ? DateTime.parse(json['finalDate'])
            : null,
      );
}

class _CalculatorPageState extends State<CalculatorPage> {
  late CalculationState _calculationState;
  List<CalculationState> _history = [];
  bool _isFinalDateHighlighted = false;
  // 変更点: 日数フィールド用のアニメーションフラグを再度追加
  bool _isDaysExpressionHighlighted = false;


  @override
  void initState() {
    super.initState();
    _calculationState = CalculationState(
      standardDate: DateTime.now(),
      daysExpression: '0',
    );
    _loadHistory();
    _calculateDate(source: ActiveField.daysExpression);
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('calcHistory') ?? [];
    if (!mounted) return;
    setState(() {
      try {
        _history = historyJson
            .map((json) => CalculationState.fromJson(jsonDecode(json)))
            .toList();
      } catch (e) {
        prefs.remove('calcHistory');
        _history = [];
      }
    });
  }
  
  Future<void> _saveHistory() async {
    if (_calculationState.finalDate == null) return;
  
    final prefs = await SharedPreferences.getInstance();
    _history.insert(0, _calculationState);
    if (_history.length > 30) {
      _history.removeLast();
    }
    List<String> historyJson =
        _history.map((state) => jsonEncode(state.toJson())).toList();
    await prefs.setStringList('calcHistory', historyJson);
    if (!mounted) return;
    setState(() {});
  }

  final Map<String, Color> _predefinedColors = {
    'インディゴ': Colors.indigo,
    'アッシュグレー': const Color(0xFF78909C),
    'ダスティミント': const Color(0xFF80CBC4),
    'スカイブルー': const Color(0xFF64B5F6),
    'ラベンダー': const Color(0xFFB39DDB),
    'アイボリー': const Color(0xFFFFF9C4),
    'ダスティローズ': const Color(0xFFE57373),
  };

  // 変更点: メソッドのロジックを全面的に書き換え
  void _onButtonPressed(String text) {
    // Entキーはどのフォーカスでも動作する
    if (text == 'Ent') {
      // フォーカスに応じてハイライト対象を変更
      if (_calculationState.activeField == ActiveField.daysExpression) {
        if (_calculationState.finalDate != null) {
          setState(() => _isFinalDateHighlighted = true);
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) setState(() => _isFinalDateHighlighted = false);
          });
        }
      } else if (_calculationState.activeField == ActiveField.finalDate) {
        setState(() => _isDaysExpressionHighlighted = true);
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _isDaysExpressionHighlighted = false);
        });
      }
      
      _calculateDate(saveToHistory: true, source: _calculationState.activeField);
      return;
    }

    // Ent以外のキーは日数フィールドのフォーカス時のみ動作
    if (_calculationState.activeField != ActiveField.daysExpression) return;

    setState(() {
      if (text == 'C') {
        _calculationState.daysExpression = '0';
      } else if (text == '←') {
        if (_calculationState.daysExpression.length > 1) {
          _calculationState.daysExpression = _calculationState.daysExpression
              .substring(0, _calculationState.daysExpression.length - 1);
        } else {
          _calculationState.daysExpression = '0';
        }
      } else if ("+-".contains(text)) {
        String lastChar = _calculationState.daysExpression.substring(_calculationState.daysExpression.length - 1);
        if ("+-".contains(lastChar)) {
          _calculationState.daysExpression = _calculationState.daysExpression.substring(0, _calculationState.daysExpression.length - 1) + text;
        } else {
          _calculationState.daysExpression += text;
        }
      } else {
          if (_calculationState.daysExpression == '0') {
            _calculationState.daysExpression = text;
          } else {
            _calculationState.daysExpression += text;
          }
      }
      _calculateDate(source: ActiveField.daysExpression);
    });
  }

  void _onShortcutButtonPressed(int days) {
    setState(() {
      if (_calculationState.activeField == ActiveField.finalDate && _calculationState.finalDate != null) {
        _calculationState.finalDate = _calculationState.finalDate!.add(Duration(days: days));
        _calculateDate(source: ActiveField.finalDate);
      } else {
        if (_calculationState.daysExpression == '0') {
          _calculationState.daysExpression = days.toString();
        } else {
          _calculationState.daysExpression += "+$days";
        }
        _calculationState.activeField = ActiveField.daysExpression;
        _calculateDate(source: ActiveField.daysExpression);
      }
    });
  }

  void _calculateDate({bool saveToHistory = false, required ActiveField source}) {
    if (source == ActiveField.standardDate || source == ActiveField.daysExpression) {
      try {
        String finalExpression = _calculationState.daysExpression;
        if (finalExpression.endsWith('+') || finalExpression.endsWith('-')) {
          finalExpression = finalExpression.substring(0, finalExpression.length - 1);
        }
        if(finalExpression.isEmpty) {
          setState(() { _calculationState.finalDate = null; });
          return;
        }
        Parser p = Parser();
        Expression exp = p.parse(finalExpression);
        final int days = exp.evaluate(EvaluationType.REAL, ContextModel()).toInt();
        setState(() {
          _calculationState.finalDate = _calculationState.standardDate.add(Duration(days: days));
        });
      } catch (e) {
        setState(() { _calculationState.finalDate = null; });
      }
    } else if (source == ActiveField.finalDate) {
      if (_calculationState.finalDate != null) {
        final int daysDifference = _calculationState.finalDate!.difference(_calculationState.standardDate).inDays;
        setState(() {
          _calculationState.daysExpression = daysDifference.toString();
        });
      }
    }

    if (saveToHistory) {
      _saveHistory();
    }
  }

  Future<void> _selectDate(BuildContext context, ActiveField field) async {
    final DateTime initialDate = (field == ActiveField.standardDate)
        ? _calculationState.standardDate
        : (_calculationState.finalDate ?? DateTime.now());

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1926),
      lastDate: DateTime(2101),
    );
    
    if (picked == null) return;

    setState(() {
      if (field == ActiveField.standardDate) {
        _calculationState.standardDate = picked;
        if (_calculationState.activeField == ActiveField.finalDate) {
          _calculateDate(source: ActiveField.finalDate);
        } else {
          _calculateDate(source: ActiveField.standardDate);
        }
      } else if (field == ActiveField.finalDate) {
        _calculationState.activeField = field;
        _calculationState.finalDate = picked;
        _calculateDate(source: ActiveField.finalDate);
      }
    });
  }
  
  void _resetToToday() {
    setState(() {
      _calculationState.standardDate = DateTime.now();
       if (_calculationState.activeField == ActiveField.finalDate) {
        _calculateDate(source: ActiveField.finalDate);
      } else {
        _calculateDate(source: ActiveField.standardDate);
      }
    });
  }

  void _navigateToHistory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryPage(history: _history, isJapaneseCalendar: widget.isJapaneseCalendar),
      ),
    );

    if (result is CalculationState) {
      setState(() {
        _calculationState = result;
      });
    } else {
      _loadHistory();
    }
  }
  
  String _formatDate(DateTime? date) {
    if (date == null) return '----年--月--日(-)';
    if (widget.isJapaneseCalendar) {
      return toJapaneseEra(date);
    } else {
      return DateFormat('yyyy年M月d日(E)', 'ja_JP').format(date);
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
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.today, size: 18),
                      label: const Text('今日'),
                      onPressed: _resetToToday,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.switch_left, size: 18),
                      label: Text(widget.isJapaneseCalendar ? '西暦へ' : '和暦へ'),
                      onPressed: widget.onCalendarModeChanged,
                       style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildDisplayField(
              label: '基準日',
              value: _formatDate(_calculationState.standardDate),
              isBase: true,
              isFocused: _calculationState.activeField == ActiveField.standardDate,
              onTap: () => _selectDate(context, ActiveField.standardDate),
            ),
            const SizedBox(height: 8),
            _buildDisplayField(
              label: '日数',
              value: _calculationState.daysExpression,
              isBase: false,
              isFocused: _calculationState.activeField == ActiveField.daysExpression,
              onTap: () {
                setState(() {
                  _calculationState.activeField = ActiveField.daysExpression;
                });
              },
              // 変更点: 日数フィールドのアニメーション状態を渡す
              isAnimating: _isDaysExpressionHighlighted,
            ),
            const SizedBox(height: 8),
            _buildDisplayField(
              label: '最終日',
              value: _formatDate(_calculationState.finalDate),
              isBase: false,
              isFocused: _calculationState.activeField == ActiveField.finalDate,
              onTap: () => _selectDate(context, ActiveField.finalDate),
              isAnimating: _isFinalDateHighlighted,
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildKeypad()),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplayField({
    required String label,
    required String value,
    required bool isBase,
    required bool isFocused,
    required VoidCallback onTap,
    bool isAnimating = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final Color highlightColor = colorScheme.tertiaryContainer;

    final bool isHighlighted = isBase || isFocused;
    final Color baseBackgroundColor = isHighlighted
        ? colorScheme.primaryContainer
        : theme.scaffoldBackgroundColor;
    
    final Color backgroundColor = isAnimating ? highlightColor : baseBackgroundColor;
    final Color borderColor = isFocused 
        ? colorScheme.primary 
        : Colors.grey.shade300;

    final bool isDaysField = label == '日数';
    final double fontSize = 32;
    final TextAlign textAlign = isDaysField ? TextAlign.right : TextAlign.left;

    return SizedBox(
      height: 80,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: isFocused ? 2.0 : 1.0
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Align(
                      alignment: isDaysField ? Alignment.centerRight : Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: textAlign,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildKeypad() {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: Row(children: [
            _buildShortcutButton(7),
            _buildShortcutButton(14),
            _buildShortcutButton(28),
          ]),
        ),
        Expanded(
          flex: 2,
          child: Row(children: [
            _buildShortcutButton(56),
            _buildShortcutButton(84),
            _buildShortcutButton(91),
          ]),
        ),
        const SizedBox(height: 8), 
        Expanded(
          flex: 4,
            child: Row(children: [
          _buildKeypadButton('7'),
          _buildKeypadButton('8'),
          _buildKeypadButton('9'),
          _buildKeypadButton('+')
        ])),
        Expanded(
          flex: 4,
            child: Row(children: [
          _buildKeypadButton('4'),
          _buildKeypadButton('5'),
          _buildKeypadButton('6'),
          _buildKeypadButton('-')
        ])),
        Expanded(
          flex: 4,
            child: Row(children: [
          _buildKeypadButton('1'),
          _buildKeypadButton('2'),
          _buildKeypadButton('3'),
          _buildKeypadButton('←')
        ])),
        Expanded(
          flex: 4,
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
    final Color? buttonColor =
        isNumberButton ? null : Theme.of(context).colorScheme.secondaryContainer;

    final Color? textColor =
        isNumberButton ? null : Theme.of(context).colorScheme.onSecondaryContainer;

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

  Widget _buildShortcutButton(int days) {
    final Color baseColor = Theme.of(context).colorScheme.primary; 
    final HSLColor hslColor = HSLColor.fromColor(baseColor);
    final HSLColor darkerHslColor = hslColor.withLightness((hslColor.lightness - 0.15).clamp(0.0, 1.0));
    final Color buttonColor = darkerHslColor.toColor();

    final int weeks = days ~/ 7;
    final String buttonText = '+$days (${weeks}週)';

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(double.infinity),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12))),
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            textStyle:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          onPressed: () => _onShortcutButtonPressed(days),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              buttonText,
              maxLines: 1,
            ),
          ),
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
    if (!context.mounted) return;
    showAboutDialog(
      context: context,
      applicationName: '日付計算ツール',
      applicationVersion: packageInfo.version,
      applicationLegalese: '© 2025 t-BocSoft',
    );
  }
}

class HistoryPage extends StatefulWidget {
  final List<CalculationState> history;
  final bool isJapaneseCalendar;
  const HistoryPage({super.key, required this.history, required this.isJapaneseCalendar});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late List<CalculationState> _history;

  @override
  void initState() {
    super.initState();
    _history = widget.history;
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('calcHistory');
    setState(() {
      _history.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('計算履歴'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '履歴をクリア',
            onPressed: _history.isEmpty
                ? null
                : () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('履歴をクリア'),
                        content: const Text('すべての計算履歴を削除しますか？'),
                        actions: [
                          TextButton(
                            child: const Text('キャンセル'),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          TextButton(
                            child: const Text('削除'),
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
                final state = _history[index];
                
                final String standardDateStr;
                final String finalDateStr;
                if (widget.isJapaneseCalendar) {
                  standardDateStr = toJapaneseEra(state.standardDate).split('(').first;
                  finalDateStr = state.finalDate != null ? toJapaneseEra(state.finalDate!).split('(').first : '';
                } else {
                  standardDateStr = DateFormat('yyyy/MM/dd').format(state.standardDate);
                  finalDateStr = state.finalDate != null ? DateFormat('yyyy/MM/dd').format(state.finalDate!) : '';
                }

                final expressionStr = state.daysExpression.replaceAllMapped(
                  RegExp(r'([+\-])'), (match) => ' ${match.group(1)} '
                );

                return ListTile(
                  title: Text(
                    '$standardDateStr $expressionStr',
                    style: const TextStyle(fontSize: 16),
                  ),
                  subtitle: Text(
                    '= $finalDateStr',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop(state);
                  },
                );
              },
              separatorBuilder: (context, index) => const Divider(),
            ),
    );
  }
}