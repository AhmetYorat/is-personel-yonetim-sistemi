import 'package:intl/intl.dart';

class Formatters {
  // Binlik ayraçlı tutar formatı
  static String formatTutar(double tutar) {
    final formatter = NumberFormat('#,##0', 'tr_TR');
    return '${formatter.format(tutar)} ₺';
  }

  // Tarih formatı
  static String formatTarih(DateTime tarih) {
    return DateFormat('dd.MM.yyyy', 'tr_TR').format(tarih);
  }

  // Tarih + Saat formatı
  static String formatTarihSaat(DateTime tarih) {
    return DateFormat('dd.MM.yyyy HH:mm', 'tr_TR').format(tarih);
  }
}