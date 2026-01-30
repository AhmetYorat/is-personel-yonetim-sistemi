import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/entity/kullanici.dart';
import '../../data/repo/auth_repository.dart';

// Auth State
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final Kullanici kullanici;
  AuthAuthenticated(this.kullanici);
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String hata;
  AuthError(this.hata);
}

// Auth Cubit
class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  final AuthRepository _repo = AuthRepository();

  // Auth durumunu dinle
  void authDurumunuKontrolEt() {
    _repo.authStateChanges.listen((User? user) async {
      print('🔄 Auth state changed: ${user?.email}');  // ✅ Debug

      if (user != null) {
        emit(AuthLoading());
        final kullanici = await _repo.kullaniciBilgisiGetir(user.uid);

        if (kullanici != null) {
          print('✅ Authenticated: ${kullanici.email}');  // ✅ Debug
          emit(AuthAuthenticated(kullanici));
        } else {
          print('❌ Kullanıcı bilgisi bulunamadı');  // ✅ Debug
          emit(AuthUnauthenticated());
        }
      } else {
        print('❌ User null - Unauthenticated');  // ✅ Debug
        emit(AuthUnauthenticated());
      }
    });
  }

  // Google ile giriş
  Future<void> googleIleGirisYap() async {
    try {
      emit(AuthLoading());
      print('🚀 Google giriş başlatılıyor...');

      final kullanici = await _repo.googleIleGirisYap();

      if (kullanici != null) {
        print('✅ Google giriş başarılı: ${kullanici.email}');
        emit(AuthAuthenticated(kullanici));  // ✅ Direkt emit et!
      } else {
        print('❌ Kullanıcı null döndü');
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      print('🔥 Google giriş hatası: $e');
      emit(AuthError(e.toString()));
      Future.delayed(const Duration(seconds: 2), () {
        emit(AuthUnauthenticated());
      });
    }
  }

  // Çıkış yap
  Future<void> cikisYap() async {
    try {
      await _repo.cikisYap();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}