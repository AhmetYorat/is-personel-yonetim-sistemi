import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/entity/tahsilat.dart';
import '../../data/repo/tahsilat_repository.dart';

class TahsilatCubit extends Cubit<List<Tahsilat>> {
  TahsilatCubit() : super([]);

  final TahsilatRepository _repo = TahsilatRepository();

  // Tahsilatları yükle
  void tahsilatlariYukle() {
    _repo.tahsilatlariGetir().listen((tahsilatlar) {
      emit(tahsilatlar);
    });
  }

  // Duruma göre yükle
  void tahsilatlariDurumaGoreYukle(String durum) {
    _repo.tahsilatlariDurumaGoreGetir(durum).listen((tahsilatlar) {
      emit(tahsilatlar);
    });
  }

  // Tahsilat ekle
  Future<void> tahsilatEkle(Tahsilat tahsilat) async {
    await _repo.tahsilatEkle(tahsilat);
  }

  // Tahsilat güncelle
  Future<void> tahsilatGuncelle(Tahsilat tahsilat) async {
    await _repo.tahsilatGuncelle(tahsilat);
  }

  // Ödeme ekle
  Future<void> odemeEkle(String tahsilatId, OdemeKayit odeme) async {
    await _repo.odemeEkle(tahsilatId, odeme);
  }

  // Tahsilat sil
  Future<void> tahsilatSil(String id) async {
    await _repo.tahsilatSil(id);
  }

  // Ara
  void tahsilatAra(String arama) {
    if (arama.isEmpty) {
      tahsilatlariYukle();
    } else {
      _repo.tahsilatAra(arama).listen((tahsilatlar) {
        emit(tahsilatlar);
      });
    }
  }
}