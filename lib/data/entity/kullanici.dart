import 'package:cloud_firestore/cloud_firestore.dart';

class Kullanici {
  String uid;           // Firebase Auth UID
  String email;
  String rol;           // 'admin' veya 'personel'
  String? personelId;   // Eğer personel ise, personel ID'si
  DateTime olusturulmaTarihi;
  bool aktif;
  String? fcmToken;     // Firebase Cloud Messaging Token
  DateTime? tokenGuncellemeTarihi;  // Token güncelleme tarihi

  Kullanici({
    required this.uid,
    required this.email,
    required this.rol,
    this.personelId,
    required this.olusturulmaTarihi,
    this.aktif = true,
    this.fcmToken,
    this.tokenGuncellemeTarihi,
  });

  // Firestore'a gönder
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'rol': rol,
      'personelId': personelId,
      'olusturulmaTarihi': olusturulmaTarihi.toIso8601String(),
      'aktif': aktif,
      'fcm_token': fcmToken,
      'token_guncelleme_tarihi': tokenGuncellemeTarihi?.toIso8601String(),
    };
  }

  // Firestore'dan al
  factory Kullanici.fromMap(Map<String, dynamic> map) {
    return Kullanici(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      rol: map['rol'] ?? 'personel',
      personelId: map['personelId'],
      olusturulmaTarihi: DateTime.parse(map['olusturulmaTarihi']),
      aktif: map['aktif'] ?? true,
      fcmToken: map['fcm_token'],
      tokenGuncellemeTarihi: map['token_guncelleme_tarihi'] != null
          ? (map['token_guncelleme_tarihi'] as Timestamp).toDate()
          : null,
    );
  }

  // Yardımcı metodlar
  bool get isAdmin => rol == 'admin';
  bool get isPersonel => rol == 'personel';
}