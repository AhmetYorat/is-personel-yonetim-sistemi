class Personel {
  String id;
  String adSoyad;
  String telefon;
  String email;
  String pozisyon;
  double maas;
  DateTime baslangicTarihi;
  bool aktif;
  String? kullaniciUid;

  Personel({
    required this.id,
    required this.adSoyad,
    required this.telefon,
    this.email = '',
    required this.pozisyon,
    this.maas = 0,
    required this.baslangicTarihi,
    this.aktif = true,
    this.kullaniciUid,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ad_soyad': adSoyad,
      'telefon': telefon,
      'email': email,
      'pozisyon': pozisyon,
      'maas': maas,
      'baslangic_tarihi': baslangicTarihi.toIso8601String(),
      'aktif': aktif,
      'kullanici_uid': kullaniciUid,
    };
  }

  factory Personel.fromMap(Map<String, dynamic> map) {
    return Personel(
      id: map['id'] ?? '',
      adSoyad: map['ad_soyad'] ?? '',
      telefon: map['telefon'] ?? '',
      email: map['email'] ?? '',
      pozisyon: map['pozisyon'] ?? '',
      maas: (map['maas'] ?? 0).toDouble(),
      baslangicTarihi: DateTime.parse(map['baslangic_tarihi']),
      aktif: map['aktif'] ?? true,
      kullaniciUid: map['kullanici_uid'],
    );
  }
}