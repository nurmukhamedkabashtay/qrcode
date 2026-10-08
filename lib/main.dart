import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  runApp(const QrGeneratorApp());
}

class QrGeneratorApp extends StatefulWidget {
  const QrGeneratorApp({super.key});

  @override
  State<QrGeneratorApp> createState() => _QrGeneratorAppState();
}

class _QrGeneratorAppState extends State<QrGeneratorApp> {
  // ThemeMode күйін басқару (Light / Dark)
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF5B4DF0);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QR Code Generator',
      // Light және Dark Theme орнату
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: _themeMode,
      home: QrHomeScreen(
        onThemeChanged: _toggleTheme,
        currentThemeMode: _themeMode,
      ),
    );
  }
}

class QrHomeScreen extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;
  final ThemeMode currentThemeMode;

  const QrHomeScreen({
    super.key,
    required this.onThemeChanged,
    required this.currentThemeMode,
  });

  @override
  State<QrHomeScreen> createState() => _QrHomeScreenState();
}

class _QrHomeScreenState extends State<QrHomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();

  String _qrData = 'https://mnu.kz';
  double _qrSize = 200.0;
  Color _qrColor = Colors.black;
  bool _isUrlMode = true;

  final List<Color> _availableColors = [
    Colors.black,
    Colors.indigo,
    Colors.teal,
    Colors.deepOrange,
    Colors.purple,
  ];

  @override
  void initState() {
    super.initState();
    _textController.text = _qrData;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _resetFields() {
    setState(() {
      _textController.text = 'https://mnu.kz';
      _qrData = 'https://mnu.kz';
      _qrSize = 200.0;
      _qrColor = Colors.black;
      _isUrlMode = true;
      _formKey.currentState?.reset();
    });
  }

  // URL валидациясы
  bool _isValidUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https'));
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.currentThemeMode == ThemeMode.dark ||
        (widget.currentThemeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Generator'),
        actions: [
          Row(
            children: [
              Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
              Switch(
                value: isDarkMode,
                onChanged: widget.onThemeChanged,
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset',
            onPressed: _resetFields,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Режимді таңдау (Text / URL)
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('URL Mode'),
                  icon: Icon(Icons.link),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Text Mode'),
                  icon: Icon(Icons.text_fields),
                ),
              ],
              selected: {_isUrlMode},
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() {
                  _isUrlMode = newSelection.first;
                  _formKey.currentState?.validate();
                });
              },
            ),
            const SizedBox(height: 16),

            // Енгізу формасы
            Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: TextFormField(
                controller: _textController,
                maxLength: 150,
                decoration: InputDecoration(
                  labelText: _isUrlMode ? 'Enter URL' : 'Enter Text',
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(_isUrlMode ? Icons.link : Icons.text_snippet),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Өріс бос болмауы керек';
                  }
                  if (value.length > 150) {
                    return 'Мәтін тым ұзын (максимум 150 символ)';
                  }
                  if (_isUrlMode && !_isValidUrl(value.trim())) {
                    return 'Дұрыс URL енгізіңіз (мысалы: https://example.com)';
                  }
                  return null;
                },
                onChanged: (val) {
                  if (_formKey.currentState?.validate() ?? false) {
                    setState(() {
                      _qrData = val;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // Баптаулар: Өлшем (Slider)
            Row(
              children: [
                const Text('Size:'),
                Expanded(
                  child: Slider(
                    value: _qrSize,
                    min: 120.0,
                    max: 300.0,
                    divisions: 18,
                    label: _qrSize.round().toString(),
                    onChanged: (val) {
                      setState(() {
                        _qrSize = val;
                      });
                    },
                  ),
                ),
              ],
            ),

            // Баптаулар: Түс таңдау
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Color: '),
                const SizedBox(width: 8),
                Wrap(
                  spacing: 8,
                  children: _availableColors.map((color) {
                    return GestureDetect(
                      color: color,
                      isSelected: _qrColor == color,
                      onTap: () {
                        setState(() {
                          _qrColor = color;
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Анимацияланған QR көрсетілімі (AnimatedSwitcher)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: QrImageView(
                    key: ValueKey('$_qrData-$_qrColor-$_qrSize'),
                    data: _qrData.isEmpty ? ' ' : _qrData,
                    version: QrVersions.auto,
                    size: _qrSize,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: _qrColor,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: _qrColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Түсті таңдауға арналған көмекші виджет
class GestureDetect extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const GestureDetect({
    super.key,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
            width: 3,
          ),
        ),
      ),
    );
  }
}