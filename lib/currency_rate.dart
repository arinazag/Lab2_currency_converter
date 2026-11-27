
class CurrencyRate {
  final String date;
  final String base;
  final String quote;
  final double rate;

  const CurrencyRate({
    required this.date,
    required this.base,
    required this.quote,
    required this.rate,
  });

  factory CurrencyRate.fromJson(Map<String, dynamic> json) {
    return CurrencyRate(
      date: json['date'] as String,
      base: json['base'] as String,
      quote: json['quote'] as String,
      rate: (json['rate'] as num).toDouble(),
    );
  }
}
