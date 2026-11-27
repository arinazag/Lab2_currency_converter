import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'currency_rate.dart';

class CurrencyApi {
  static const String _baseUrl = 'https://api.frankfurter.dev/v2/rate';

  Future<CurrencyRate> getRate(String base, String quote) async {
    final url = Uri.parse('$_baseUrl/$base/$quote');

    late http.Response response;

    try {
      response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );
    } on TimeoutException {
      throw Exception(
        'Сервер не ответил за 10 секунд. '
        'Проверьте интернет и попробуйте ещё раз.',
      );
    } on SocketException {
      throw Exception(
        'Не удалось подключиться к сети. Проверьте интернет.',
      );
    } on http.ClientException {
      throw Exception(
        'Не удалось получить ответ. Проверьте интернет '
        'или доступность сервера.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Ошибка сервера: код ${response.statusCode}',
      );
    }

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return CurrencyRate.fromJson(data);
    } on FormatException {
      throw Exception('Сервер вернул некорректные данные.');
    } on TypeError {
      throw Exception('Формат курса валют не соответствует ожиданиям.');
    }
  }
}