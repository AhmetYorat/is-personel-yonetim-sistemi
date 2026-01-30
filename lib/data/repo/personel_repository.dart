import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:personel_takip/data/entity/personel.dart';
import 'package:uuid/uuid.dart';

class PersonelRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'personeller';
  final Uuid _uuid = Uuid();

  Future<void> personelEkle(Personel personel) async {
    personel.id = _uuid.v4();
    await _firestore.collection(_collection).doc(personel.id).set(personel.toMap());
  }

  Stream<List<Personel>> personelleriGetir(){
    print('🔍 PersonelRepository: Sorgu başlatılıyor...');

    return _firestore
        .collection(_collection)
        .where('aktif', isEqualTo: true)
        .snapshots()
        .map((snapshot){
      print('📦 Aktif personel sayısı: ${snapshot.docs.length}');

      if (snapshot.docs.isEmpty) {
        print('⚠️ Hiç aktif personel bulunamadı!');
      }

      snapshot.docs.forEach((doc) {
        print('📄 Döküman ID: ${doc.id}');
        print('   ad_soyad: ${doc.data()['ad_soyad']}');
        print('   aktif: ${doc.data()['aktif']}');
      });

      return snapshot.docs.map((doc){
        try {
          var personel = Personel.fromMap(doc.data());
          print('✅ Personel parse edildi: ${personel.adSoyad} (aktif: ${personel.aktif})');
          return personel;
        } catch (e) {
          print('❌ Parse hatası: $e');
          print('❌ Hatalı data: ${doc.data()}');
          rethrow;
        }
      }).toList();
    });
  }

  Future<Personel?> personelGetir(String id) async{
    var doc = await _firestore.collection(_collection).doc(id).get();

    if(doc.exists){
      return Personel.fromMap(doc.data()!);
    }
    return null;
  }

  Future<void> personelGuncelle(Personel personel) async{
    await _firestore.collection(_collection).doc(personel.id).update(personel.toMap());
  }

  Future<void> personelSil(String id) async{
    await _firestore.collection(_collection).doc(id).update({'aktif' : false});
  }

  Stream<List<Personel>> personelAra(String arama) {
    return _firestore
        .collection(_collection)
        .where('aktif', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      var personeller = snapshot.docs.map((doc) {
        return Personel.fromMap(doc.data());
      }).toList();

      return personeller.where((p) {
        return p.adSoyad.toLowerCase().contains(arama.toLowerCase());
      }).toList();
    });
  }

}