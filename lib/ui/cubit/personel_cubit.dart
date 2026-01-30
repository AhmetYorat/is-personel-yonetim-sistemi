import 'package:personel_takip/data/entity/personel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personel_takip/data/repo/personel_repository.dart';

class PersonelCubit extends Cubit<List<Personel>> {
  PersonelCubit() : super([]);

  final PersonelRepository _repo = PersonelRepository();

  void personelleriYukle(){
    _repo.personelleriGetir().listen((personeller){
      emit(personeller);
    });
  }


  Future<void> personelEkle(Personel personel) async {
    await _repo.personelEkle(personel);
    // Stream otomatik güncelleyecek, ondan emit'e gerek yok
  }

  Future<void> personelGuncelle(Personel personel) async{
    await _repo.personelGuncelle(personel);
  }

  Future<void> personelSil(String id) async {
    await _repo.personelSil(id);
  }

  void personelAra(String arama) {
    if (arama.isEmpty) {
      personelleriYukle();
    } else {
      _repo.personelAra(arama).listen((personeller) {
        emit(personeller);
      });
    }
  }

}