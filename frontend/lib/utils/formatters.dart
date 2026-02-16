import 'package:intl/intl.dart';

/// Utilitários de formatação centralizados para o OSMECH.
/// Formatação monetária e de datas no padrão pt_BR.

final _currencyFormat = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
  decimalDigits: 2,
);

final _dateFormat = DateFormat('dd/MM/yyyy');
final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

/// Formata valor monetário no padrão brasileiro: R$ 1.234,56
String formatCurrency(dynamic value) {
  final num val = (value is num) ? value : 0;
  return _currencyFormat.format(val);
}

/// Formata data ISO (String ou DateTime) para dd/MM/yyyy
String formatDateBR(dynamic date) {
  if (date == null) return '-';
  if (date is DateTime) return _dateFormat.format(date);
  if (date is String && date.isNotEmpty) {
    try {
      return _dateFormat.format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }
  return '-';
}

/// Formata data+hora ISO para dd/MM/yyyy HH:mm
String formatDateTimeBR(dynamic date) {
  if (date == null) return '-';
  if (date is DateTime) return _dateTimeFormat.format(date);
  if (date is String && date.isNotEmpty) {
    try {
      return _dateTimeFormat.format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }
  return '-';
}
