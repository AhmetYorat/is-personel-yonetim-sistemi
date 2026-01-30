import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personel_takip/services/notification_service.dart';
import 'package:personel_takip/ui/cubit/auth_cubit.dart';
import 'package:personel_takip/ui/cubit/is_cubit.dart';
import 'package:personel_takip/ui/cubit/personel_cubit.dart';
import 'package:personel_takip/ui/cubit/tahsilat_cubit.dart';
import 'package:personel_takip/ui/views/ana_sayfa.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:personel_takip/ui/views/login_sayfa.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🌙 Background bildirim: ${message.notification?.title}');
}

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('tr_TR', null);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // ✅ Bildirim servisini başlat
  await NotificationService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => PersonelCubit()),
        BlocProvider(create: (context) => IsCubit()),
        BlocProvider(create: (context) => AuthCubit()..authDurumunuKontrolEt()),
        BlocProvider(create: (context) => TahsilatCubit()),
      ],
      child: MaterialApp(
        title: 'Personel Takip',

        locale: const Locale('tr', 'TR'),

        supportedLocales: const [
          Locale('tr', 'TR'),
          Locale('en', 'US'),
        ],

        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: .fromSeed(seedColor: Colors.deepPurple),
        ),
        home: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is AuthLoading) {
              return Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            } else if (state is AuthAuthenticated) {
              // ✅ Giriş yapıldığında token kaydet
              NotificationService().saveUserToken(state.kullanici.uid);
              return AnaSayfa();
            } else {
              return LoginSayfa();
            }
          },
        ),
      ),
    );
  }
}

