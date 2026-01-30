import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Is {
  String id;
  String baslik;
  String aciklama;
  String musteriAdi;
  String adres;
  String durum;
  DateTime baslangicTarihi;
  DateTime? bitisTarihi;
  List<String> atananPersonelIdler;
  double? maliyet;
  bool aktif;

  Is({
    required this.id,
    required this.baslik,
    required this.aciklama,
    required this.musteriAdi,
    required this.adres,
    required this.durum,
    required this.baslangicTarihi,
    this.bitisTarihi,
    required this.atananPersonelIdler,
    this.maliyet,
    this.aktif = true,
  });

  factory Is.fromMap(Map<String, dynamic> map) {
    return Is(
      id: map['id'] ?? '',
      baslik: map['baslik'] ?? '',
      aciklama: map['aciklama'] ?? '',
      musteriAdi: map['musteri_adi'] ?? '',
      adres: map['adres'] ?? '',
      durum: map['durum'] ?? 'Beklemede',
      baslangicTarihi: (map['baslangicTarihi'] as dynamic).toDate(),
      bitisTarihi: map['bitisTarihi'] != null
          ? (map['bitisTarihi'] as dynamic).toDate()
          : null,
      atananPersonelIdler: List<String>.from(map['atananPersonelIdler'] ?? []),
      maliyet: map['maliyet']?.toDouble(),
      aktif: map['aktif'] ?? true,
    );
  }

  Map<String, dynamic> toMap(){
    return {
      'id': id,
      'baslik': baslik,
      'aciklama': aciklama,
      'musteri_adi': musteriAdi,  // ✅ EKLE
      'adres': adres,
      'durum': durum,
      'baslangicTarihi': baslangicTarihi,
      'bitisTarihi': bitisTarihi,
      'atananPersonelIdler': atananPersonelIdler,
      'maliyet': maliyet,
      'aktif': aktif,
    };
  }


  static getDurumColor(String durum) {
    switch (durum) {
      case 'Beklemede':
        return const Color(0xFFFFA726); // Turuncu
      case 'Devam Ediyor':
        return const Color(0xFF42A5F5); // Mavi
      case 'Tamamlandı':
        return const Color(0xFF66BB6A); // Yeşil
      case 'İptal':
        return const Color(0xFFEF5350); // Kırmızı
      default:
        return const Color(0xFF9E9E9E); // Gri
    }
  }

  static getDurumIcon(String durum) {
    switch (durum) {
      case 'Beklemede':
        return Icons.schedule;
      case 'Devam Ediyor':
        return Icons.engineering;
      case 'Tamamlandı':
        return Icons.check_circle;
      case 'İptal':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

}