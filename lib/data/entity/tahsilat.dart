import 'dart:ui';

import 'package:flutter/material.dart';

class Tahsilat {
  String id;
  String? isId;  // ✅ Opsiyonel - İş'e bağlıysa dolu
  String musteriAdi;  // ✅ Zorunlu - Her tahsilatın müşterisi var
  String aciklama;  // Tahsilat açıklaması
  double toplamTutar;
  double odenenTutar;
  String durum;  // 'bekliyor', 'kismen', 'tamamlandi'
  DateTime olusturulmaTarihi;
  DateTime? sonOdemeTarihi;  // En son ne zaman ödeme yapıldı
  List<OdemeKayit> odemeler;
  bool aktif;

  Tahsilat({
    required this.id,
    this.isId,
    required this.musteriAdi,
    required this.aciklama,
    required this.toplamTutar,
    this.odenenTutar = 0,
    required this.durum,
    required this.olusturulmaTarihi,
    this.sonOdemeTarihi,
    required this.odemeler,
    this.aktif = true,
  });

  double get kalanTutar => toplamTutar - odenenTutar;
  bool get istenOlusturuldu => isId != null && isId!.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'is_id': isId,
      'musteri_adi': musteriAdi,
      'aciklama': aciklama,
      'toplam_tutar': toplamTutar,
      'odenen_tutar': odenenTutar,
      'durum': durum,
      'olusturulma_tarihi': olusturulmaTarihi.toIso8601String(),
      'son_odeme_tarihi': sonOdemeTarihi?.toIso8601String(),
      'odemeler': odemeler.map((o) => o.toMap()).toList(),
      'aktif': aktif,
    };
  }

  factory Tahsilat.fromMap(Map<String, dynamic> map) {
    return Tahsilat(
      id: map['id'] ?? '',
      isId: map['is_id'],
      musteriAdi: map['musteri_adi'] ?? '',
      aciklama: map['aciklama'] ?? '',
      toplamTutar: (map['toplam_tutar'] ?? 0).toDouble(),
      odenenTutar: (map['odenen_tutar'] ?? 0).toDouble(),
      durum: map['durum'] ?? 'bekliyor',
      olusturulmaTarihi: DateTime.parse(map['olusturulma_tarihi']),
      sonOdemeTarihi: map['son_odeme_tarihi'] != null
          ? DateTime.parse(map['son_odeme_tarihi'])
          : null,
      odemeler: (map['odemeler'] as List? ?? [])
          .map((o) => OdemeKayit.fromMap(o))
          .toList(),
      aktif: map['aktif'] ?? true,
    );
  }

  // Durum rengi
  static getDurumColor(String durum) {
    switch (durum) {
      case 'bekliyor':
        return const Color(0xFFFFA726); // Turuncu
      case 'kismen':
        return const Color(0xFF42A5F5); // Mavi
      case 'tamamlandi':
        return const Color(0xFF66BB6A); // Yeşil
      default:
        return const Color(0xFF9E9E9E); // Gri
    }
  }

  // Durum ikonu
  static getDurumIcon(String durum) {
    switch (durum) {
      case 'bekliyor':
        return Icons.schedule;
      case 'kismen':
        return Icons.payments;
      case 'tamamlandi':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  // Durum text
  static String getDurumText(String durum) {
    switch (durum) {
      case 'bekliyor':
        return 'Ödeme Bekliyor';
      case 'kismen':
        return 'Kısmi Ödendi';
      case 'tamamlandi':
        return 'Tamamlandı';
      default:
        return 'Bilinmiyor';
    }
  }
}

// Ödeme Kaydı
class OdemeKayit {
  DateTime tarih;
  double tutar;
  String odemeSekli;  // 'Nakit', 'Kredi Kartı', 'Havale', 'EFT'
  String not;

  OdemeKayit({
    required this.tarih,
    required this.tutar,
    required this.odemeSekli,
    this.not = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'tarih': tarih.toIso8601String(),
      'tutar': tutar,
      'odeme_sekli': odemeSekli,
      'not': not,
    };
  }

  factory OdemeKayit.fromMap(Map<String, dynamic> map) {
    return OdemeKayit(
      tarih: DateTime.parse(map['tarih']),
      tutar: (map['tutar'] ?? 0).toDouble(),
      odemeSekli: map['odeme_sekli'] ?? 'Nakit',
      not: map['not'] ?? '',
    );
  }
}