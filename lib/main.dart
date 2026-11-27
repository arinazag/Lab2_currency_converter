import 'package:flutter/material.dart';
import 'currency_api.dart';
import 'currency_rate.dart';

void main() => runApp(const CurrencyConverterApp());

class CurrencyConverterApp extends StatelessWidget {
  const CurrencyConverterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Конвертер валют',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        scaffoldBackgroundColor: const Color(0xFFF3F6FB),
      ),
      home: const ConverterPage(),
    );
  }
}

class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key});

  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage> {
  final _api = CurrencyApi();
  final _amountController = TextEditingController(text: '100');
  final _cache = <String, CurrencyRate>{};

  static const List<String> _currencies = [
    'EUR',
    'RUB',
    'USD',
    'GBP',
    'CNY',
    'PLN',
    'JPY',
    'CHF',
    'CAD',
    'AUD',
    'INR',
    'TRY',
    'BRL',
    'KRW',
    'SEK',
    'NOK',
  ];

  String _fromCurrency = 'EUR';
  String _toCurrency = 'RUB';

  CurrencyRate? _currentRate;
  double? _result;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _convert({bool refresh = false}) async {
    final amountText = _amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(amountText);

    if (amount == null || !amount.isFinite || amount <= 0) {
      setState(() {
        _result = null;
        _errorMessage = 'Введите корректную сумму больше нуля';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final CurrencyRate rate;

      if (_fromCurrency == _toCurrency) {
        rate = CurrencyRate(
          date: DateTime.now().toIso8601String().substring(0, 10),
          base: _fromCurrency,
          quote: _toCurrency,
          rate: 1.0,
        );
      } else {
        final cacheKey = '$_fromCurrency-$_toCurrency';

        if (!refresh && _cache.containsKey(cacheKey)) {
          rate = _cache[cacheKey]!;
        } else {
          rate = await _api.getRate(_fromCurrency, _toCurrency);
          _cache[cacheKey] = rate;
        }
      }

      if (!mounted) return;

      setState(() {
        _currentRate = rate;
        _result = amount * rate.rate;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _result = null;
        _currentRate = null;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
      _result = null;
      _currentRate = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Конвертер валют',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF3F6FB),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.currency_exchange,
                    size: 48,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Переводите деньги между валютами',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Сумма',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Введите сумму',
                              prefixIcon: Icon(Icons.payments_outlined),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => setState(() {
                              _result = null;
                              _errorMessage = null;
                            }),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Из валюты',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            // ключ нужен, чтобы список обновлялся после swap
                            key: ValueKey('from-$_fromCurrency'),
                            initialValue: _fromCurrency,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            items: _currencies
                                .map((c) =>
                                    DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (val) {
                              if (val == null) return;
                              setState(() {
                                _fromCurrency = val;
                                _result = null;
                                _currentRate = null;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          IconButton.filledTonal(
                            onPressed: _swapCurrencies,
                            tooltip: 'Поменять валюты местами',
                            icon: const Icon(Icons.swap_vert, size: 28),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'В валюту',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            key: ValueKey('to-$_toCurrency'),
                            initialValue: _toCurrency,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            items: _currencies
                                .map((c) =>
                                    DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (val) {
                              if (val == null) return;
                              setState(() {
                                _toCurrency = val;
                                _result = null;
                                _currentRate = null;
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: _isLoading ? null : () => _convert(),
                            icon: const Icon(Icons.calculate),
                            label: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: Text('Конвертировать'),
                            ),
                          ),
                          if (_isLoading) ...[
                            const SizedBox(height: 20),
                            const Center(child: CircularProgressIndicator()),
                          ],
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                          if (_result != null && _currentRate != null) ...[
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDBEAFE),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Результат конвертации',
                                    style: TextStyle(color: Color(0xFF1E3A8A)),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${_result!.toStringAsFixed(2)} $_toCurrency',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF172554),
                                    ),
                                  ),
                                  const Divider(height: 24),
                                  Text(
                                    '1 $_fromCurrency = ${_currentRate!.rate} $_toCurrency',
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Дата курса: ${_currentRate!.date}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: _isLoading
                                        ? null
                                        : () => _convert(refresh: true),
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Обновить курс'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
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
}
