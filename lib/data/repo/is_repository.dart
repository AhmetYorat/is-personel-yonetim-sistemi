import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:personel_takip/data/entity/is.dart';
import 'package:uuid/uuid.dart';

class IsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'isler';
  final Uuid _uuid = Uuid();

  Future<String> isEkle(Is is_) async {
    is_.id = _uuid.v4();
    await _firestore.collection(_collection).doc(is_.id).set(is_.toMap());
    return is_.id;
  }

  Stream<List<Is>> isleriGetir(){
    return _firestore
        .collection(_collection)
        .where('aktif', isEqualTo: true)
        .orderBy('baslangicTarihi', descending: true)
        .snapshots()
        .map((snapshot){
          return snapshot.docs.map((doc){
            return Is.fromMap(doc.data());
          }).toList();
        });
  }

  // Personel ID ile işleri getir
  Stream<List<Is>> personelIdIleIsleriGetir(String personelId) {
    return _firestore
        .collection(_collection)
        .where('aktif', isEqualTo: true)
        .where('atananPersonelIdler', arrayContains: personelId)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Is.fromMap(doc.data())).toList());
  }

  Stream<List<Is>> isleriDurumaGoreGetir(String durum) {
    return _firestore
        .collection(_collection)
        .where('aktif', isEqualTo: true)
        .where('durum', isEqualTo: durum)
        .orderBy('baslangicTarihi', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Is.fromMap(doc.data());
      }).toList();
    });
  }

  Stream<List<Is>> personelIsleriGetir(String kullaniciUid) async* {
    // Önce bu kullanıcının personel kaydını bul
    var personelSnapshot = await _firestore
        .collection('personeller')
        .where('kullanici_uid', isEqualTo: kullaniciUid)
        .where('aktif', isEqualTo: true)
        .limit(1)
        .get();

    if (personelSnapshot.docs.isEmpty) {
      yield [];
      return;
    }

    String personelId = personelSnapshot.docs.first.data()['id'];

    // Bu personele atanan işleri dinle
    await for (var snapshot in _firestore
        .collection(_collection)
        .where('aktif', isEqualTo: true)
        .where('atananPersonelIdler', arrayContains: personelId)
        .orderBy('baslangicTarihi', descending: true)
        .snapshots()) {
      yield snapshot.docs.map((doc) => Is.fromMap(doc.data())).toList();
    }
  }
  Future<Is?> isGetir(String id) async {
    var doc = await _firestore.collection(_collection).doc(id).get();

    if (doc.exists) {
      return Is.fromMap(doc.data()!);
    }
    return null;
  }

  Future<void> isGuncelle(Is is_) async {
    await _firestore.collection(_collection).doc(is_.id).update(is_.toMap());
  }

  // (durum değişince hızlı güncelleme)
  Future<void> isDurumuGuncelle(String id, String yeniDurum) async {
    await _firestore.collection(_collection).doc(id).update({
      'durum': yeniDurum,
      'bitisTarihi': yeniDurum == 'Tamamlandı' ? DateTime.now() : null,
    });
  }

  Future<void> isePersonelEkle(String isId, String personelId) async {
    await _firestore.collection(_collection).doc(isId).update({
      'atananPersonelIdler': FieldValue.arrayUnion([personelId]),
    });
  }

  Future<void> istenPersonelCikar(String isId, String personelId) async {
    await _firestore.collection(_collection).doc(isId).update({
      'atananPersonelIdler': FieldValue.arrayRemove([personelId]),
    });
  }

  Future<void> isSil(String id) async {
    await _firestore.collection(_collection).doc(id).update({'aktif': false});
  }

  Stream<List<Is>> isAra(String arama) {
    return _firestore
        .collection(_collection)
        .where('aktif', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      var isler = snapshot.docs.map((doc) {
        return Is.fromMap(doc.data());
      }).toList();

      return isler.where((is_) {
        return is_.baslik.toLowerCase().contains(arama.toLowerCase()) ||
            is_.adres.toLowerCase().contains(arama.toLowerCase());
      }).toList();
    });
  }

  Future<Map<String, int>> isIstatistikleriGetir() async {
    var snapshot = await _firestore
        .collection(_collection)
        .where('aktif', isEqualTo: true)
        .get();

    var isler = snapshot.docs.map((doc) => Is.fromMap(doc.data())).toList();

    return {
      'toplam': isler.length,
      'beklemede': isler.where((is_) => is_.durum == 'Beklemede').length,
      'devamEdiyor': isler.where((is_) => is_.durum == 'Devam Ediyor').length,
      'tamamlandi': isler.where((is_) => is_.durum == 'Tamamlandı').length,
      'iptal': isler.where((is_) => is_.durum == 'İptal').length,
    };
  }

}