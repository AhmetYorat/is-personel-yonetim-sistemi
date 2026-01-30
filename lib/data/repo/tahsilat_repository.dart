import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../entity/tahsilat.dart';

class TahsilatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'tahsilatlar';
  final Uuid _uuid = Uuid();

  // Tahsilat ekle
  Future<void> tahsilatEkle(Tahsilat tahsilat) async {
    tahsilat.id = _uuid.v4();
    await _firestore.collection(_collection).doc(tahsilat.id).set(tahsilat.toMap());
  }

  // Tüm tahsilatları getir
  Stream<List<Tahsilat>> tahsilatlariGetir() {
    return _firestore
        .collection(_collection)
        .where('aktif', isEqualTo: true)
        .orderBy('olusturulma_tarihi', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Tahsilat.fromMap(doc.data());
      }).toList();
    });
  }

  // Duruma göre tahsilatları getir
  Stream<List<Tahsilat>> tahsilatlariDurumaGoreGetir(String durum) {
    return _firestore
        .collection(_collection)
        .where('aktif', isEqualTo: true)
        .where('durum', isEqualTo: durum)
        .orderBy('olusturulma_tarihi', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Tahsilat.fromMap(doc.data());
      }).toList();
    });
  }

  // Tek tahsilat getir
  Future<Tahsilat?> tahsilatGetir(String id) async {
    var doc = await _firestore.collection(_collection).doc(id).get();
    if (doc.exists) {
      return Tahsilat.fromMap(doc.data()!);
    }
    return null;
  }

  // Tahsilat güncelle
  Future<void> tahsilatGuncelle(Tahsilat tahsilat) async {
    await _firestore.collection(_collection).doc(tahsilat.id).update(tahsilat.toMap());
  }

  // Ödeme ekle
  Future<void> odemeEkle(String tahsilatId, OdemeKayit odeme) async {
    var tahsilat = await tahsilatGetir(tahsilatId);
    if (tahsilat == null) return;

    // Ödemeyi ekle
    tahsilat.odemeler.add(odeme);
    tahsilat.odenenTutar += odeme.tutar;
    tahsilat.sonOdemeTarihi = odeme.tarih;

    // Durumu güncelle
    if (tahsilat.odenenTutar >= tahsilat.toplamTutar) {
      tahsilat.durum = 'tamamlandi';
    } else if (tahsilat.odenenTutar > 0) {
      tahsilat.durum = 'kismen';
    } else {
      tahsilat.durum = 'bekliyor';
    }

    await tahsilatGuncelle(tahsilat);
  }

  // Tahsilat sil (soft delete)
  Future<void> tahsilatSil(String id) async {
    await _firestore.collection(_collection).doc(id).update({'aktif': false});
  }

  // İş'e ait tahsilat getir
  Future<Tahsilat?> iseTahsilatGetir(String isId) async {
    var snapshot = await _firestore
        .collection(_collection)
        .where('is_id', isEqualTo: isId)
        .where('aktif', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return Tahsilat.fromMap(snapshot.docs.first.data());
    }
    return null;
  }

  // Müşteri ara
  Stream<List<Tahsilat>> tahsilatAra(String arama) {
    return _firestore
        .collection(_collection)
        .where('aktif', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      var tahsilatlar = snapshot.docs.map((doc) {
        return Tahsilat.fromMap(doc.data());
      }).toList();

      return tahsilatlar.where((t) {
        return t.musteriAdi.toLowerCase().contains(arama.toLowerCase()) ||
            t.aciklama.toLowerCase().contains(arama.toLowerCase());
      }).toList();
    });
  }
}