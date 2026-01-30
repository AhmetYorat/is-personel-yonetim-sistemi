import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personel_takip/services/notification_service.dart';
import '../../data/entity/is.dart';
import '../../data/repo/is_repository.dart';

class IsCubit extends Cubit<List<Is>> {
  IsCubit() : super([]);

  final IsRepository _repo = IsRepository();

  // İşleri yükle
  void isleriYukle() {
    _repo.isleriGetir().listen((isler) {
      emit(isler);
    });
  }

  // Duruma göre işleri yükle
  void isleriDurumaGoreYukle(String durum) {
    _repo.isleriDurumaGoreGetir(durum).listen((isler) {
      emit(isler);
    });
  }

  // Personele ait işleri yükle (Kullanıcı UID ile)
  void personelIsleriYukle(String kullaniciUid) {
    _repo.personelIsleriGetir(kullaniciUid).listen((isler) {
      emit(isler);
    });
  }

  // İş ekle
  Future<String?> isEkle(Is is_) async {
    try {
      String isId = await _repo.isEkle(is_);
      print('✅ İş eklendi: ${is_.baslik}');

      // 🔔 Atanan personellere bildirim gönder
      if (is_.atananPersonelIdler.isNotEmpty) {
        NotificationService().isePersonelAtandiTopluBildirim(
          isId: isId,
          isBaslik: is_.baslik,
          personelIdler: is_.atananPersonelIdler,
        );
      }

      isleriYukle();
      return isId;
    } catch (e) {
      print('❌ İş ekleme hatası: $e');
      return null;
    }
  }


  // İş güncelle
  Future<void> isGuncelle(Is is_) async {
    await _repo.isGuncelle(is_);
  }

  // İş durumu güncelle
  Future<void> isDurumuGuncelle(String isId, String yeniDurum) async {
    try {
      await _repo.isDurumuGuncelle(isId, yeniDurum);

      // Bildirim gönder
      final isDoc = await FirebaseFirestore.instance
          .collection('isler')
          .doc(isId)
          .get();

      if (isDoc.exists) {
        final isData = isDoc.data() as Map<String, dynamic>;
        final isBaslik = isData['baslik'] as String;
        final personelIdler = List<String>.from(isData['atananPersonelIdler'] ?? []);

        NotificationService().isDurumuDegistiBindirimi(
          isId: isId,
          isBaslik: isBaslik,
          yeniDurum: yeniDurum,
          personelIdler: personelIdler,
        );
      }

      isleriYukle();
    } catch (e) {
      print('Durum güncelleme hatası: $e');
    }
  }

  // İşe personel ekle
  Future<void> isePersonelEkle(String isId, String personelId) async {
    try {
      await _repo.isePersonelEkle(isId, personelId);

      //  Bildirim gönder
      final isDoc = await FirebaseFirestore.instance
          .collection('isler')
          .doc(isId)
          .get();

      if (isDoc.exists) {
        final isData = isDoc.data() as Map<String, dynamic>;
        final isBaslik = isData['baslik'] as String;

        NotificationService().isePersonelAtandiBindirimi(
          personelId: personelId,
          isBaslik: isBaslik,
          isId: isId,
        );
      }

      isleriYukle();
    } catch (e) {
      print('Personel ekleme hatası: $e');
    }
  }

  // İşten personel çıkar
  Future<void> istenPersonelCikar(String isId, String personelId) async {
    try {
      await _repo.istenPersonelCikar(isId, personelId);

      //  Bildirim gönder
      final isDoc = await FirebaseFirestore.instance
          .collection('isler')
          .doc(isId)
          .get();

      if (isDoc.exists) {
        final isData = isDoc.data() as Map<String, dynamic>;
        final isBaslik = isData['baslik'] as String;

        NotificationService().istenCikarildiBindirimi(
          personelId: personelId,
          isBaslik: isBaslik,
        );
      }

      isleriYukle();
    } catch (e) {
      print('Personel çıkarma hatası: $e');
    }
  }

  // Personel ID ile işleri yükle
  void personelIdIleIsleriYukle(String personelId) {
    _repo.personelIdIleIsleriGetir(personelId).listen((isler) {
      emit(isler);
    });
  }

  // İş sil
  Future<void> isSil(String id) async {
    await _repo.isSil(id);
  }

  // İş ara
  void isAra(String arama) {
    if (arama.isEmpty) {
      isleriYukle();
    } else {
      _repo.isAra(arama).listen((isler) {
        emit(isler);
      });
    }
  }
}