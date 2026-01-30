import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:personel_takip/services/notification_service.dart';
import 'package:uuid/uuid.dart';
import '../entity/kullanici.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'kullanicilar';

  // Mevcut kullanıcıyı getir
  User? get mevcutKullanici => _auth.currentUser;

  // Auth durumu (stream)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 1. Google ile Giriş Yap
  Future<Kullanici?> googleIleGirisYap() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('❌ Kullanıcı iptal etti');
        return null;
      }

      print('✅ Google user: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null) {
        print('❌ Firebase user null');
        return null;
      }

      print('✅ Firebase user: ${user.uid}');

      final docSnapshot = await _firestore.collection(_collection).doc(user.uid).get();

      Kullanici kullanici;

      if (!docSnapshot.exists) {
        print('📝 Yeni kullanıcı oluşturuluyor');

        final kullaniciSayisi = await _firestore.collection(_collection).count().get();

        kullanici = Kullanici(
          uid: user.uid,
          email: user.email ?? '',
          rol: kullaniciSayisi.count == 0 ? 'admin' : 'personel',
          olusturulmaTarihi: DateTime.now(),
        );

        await _firestore.collection(_collection).doc(user.uid).set(kullanici.toMap());
        print('✅ Firestore\'a kaydedildi: ${kullanici.rol}');

        // ✅ YENİ: Otomatik personel kaydı oluştur
        await _otomatikPersonelOlustur(user, kullanici.rol);
      } else {
        print('✅ Mevcut kullanıcı bulundu');
        kullanici = Kullanici.fromMap(docSnapshot.data()!);

        // ✅ YENİ: Personel kaydı var mı kontrol et, yoksa oluştur
        await _personelKaydiKontrolEt(user, kullanici);
      }

      print('🎉 Kullanıcı döndürülüyor: ${kullanici.email} - ${kullanici.rol}');
      await NotificationService().saveUserToken(user.uid);
      print('✅ FCM Token kaydedildi');
      return kullanici;
    } catch (e) {
      print('🔥 HATA: $e');
      rethrow;
    }
  }

// Otomatik personel oluştur
  Future<void> _otomatikPersonelOlustur(User user, String rol) async {
    try {
      // Personel koleksiyonunda bu kullanıcı var mı kontrol et
      var personelSnapshot = await _firestore
          .collection('personeller')
          .where('kullanici_uid', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (personelSnapshot.docs.isEmpty) {

        String personelId = Uuid().v4();

        await _firestore.collection('personeller').doc(personelId).set({
          'id': personelId,
          'ad_soyad': user.displayName ?? user.email?.split('@')[0] ?? 'İsimsiz',
          'telefon': user.phoneNumber ?? '',
          'email': user.email ?? '',
          'pozisyon': rol == 'admin' ? 'Yönetici' : 'Personel',
          'maas': 0,
          'baslangic_tarihi': DateTime.now().toIso8601String(),
          'aktif': true,
          'kullanici_uid': user.uid,
        });

        print('✅ Personel kaydı oluşturuldu: $personelId');
      }
    } catch (e) {
      print('❌ Personel oluşturma hatası: $e');
    }
  }

// Personel kaydı kontrol et
  Future<void> _personelKaydiKontrolEt(User user, Kullanici kullanici) async {
    try {
      var personelSnapshot = await _firestore
          .collection('personeller')
          .where('kullanici_uid', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (personelSnapshot.docs.isEmpty) {
        // Eski kullanıcı ama personel kaydı yok, oluştur
        await _otomatikPersonelOlustur(user, kullanici.rol);
      }
    } catch (e) {
      print('❌ Personel kontrol hatası: $e');
    }
  }

  // 2. Kullanıcı Bilgisini Getir (UID ile)
  Future<Kullanici?> kullaniciBilgisiGetir(String uid) async {
    try {
      final docSnapshot = await _firestore.collection(_collection).doc(uid).get();

      if (docSnapshot.exists) {
        return Kullanici.fromMap(docSnapshot.data()!);
      }
      return null;
    } catch (e) {
      print('Kullanıcı bilgisi getirme hatası: $e');
      return null;
    }
  }

  // 3. Çıkış Yap
  Future<void> cikisYap() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}