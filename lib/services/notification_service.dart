import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  // FCM Token
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Bildirimleri başlat
  Future<void> initialize() async {
    print('📱 Bildirim servisi başlatılıyor...');

    // ✅ İzin iste
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Bildirim izni verildi');
    } else {
      print('❌ Bildirim izni reddedildi');
      return;
    }

    // ✅ Local notifications ayarla
    await _initializeLocalNotifications();

    // ✅ FCM Token al
    _fcmToken = await _fcm.getToken();
    print('🔑 FCM Token: $_fcmToken');

    // ✅ Token yenilendiğinde
    _fcm.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      print('🔄 FCM Token yenilendi: $newToken');
      // Token'ı Firestore'a kaydet
      _saveFcmToken(newToken);
    });

    // ✅ Foreground (uygulama açıkken) bildirimleri dinle
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // ✅ Background (uygulama kapalıyken) bildirime tıklanınca
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // ✅ Uygulama tamamen kapalıyken gelen bildirim
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }

    print('🎉 Bildirim servisi hazır!');
  }

  /// Local notifications başlat
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@drawable/ic_notification');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // ✅ Android bildirim kanalı oluştur
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Yüksek Öncelikli Bildirimler',
      description: 'İş atamaları ve önemli bildirimler için kanal',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Foreground bildirim geldiğinde
  void _handleForegroundMessage(RemoteMessage message) {
    print('📬 Foreground bildirim: ${message.notification?.title}');

    if (message.notification != null) {
      _showLocalNotification(
        title: message.notification!.title ?? 'Yeni Bildirim',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  /// Background bildirime tıklanınca
  void _handleBackgroundMessage(RemoteMessage message) {
    print('🔔 Background bildirim açıldı: ${message.data}');

    // Burada isteğe göre sayfa yönlendirmesi yapabilirsin
    // Örneğin: İş detay sayfasına git
    if (message.data['type'] == 'yeni_is') {
      String? isId = message.data['is_id'];
      print('➡️ İş detay sayfasına yönlendir: $isId');
      // Navigator.push(...) - Global key ile yapılabilir
    }
  }

  /// Bildirime tıklanınca
  void _onNotificationTapped(NotificationResponse response) {
    print('👆 Bildirime tıklandı: ${response.payload}');
    // Burada da yönlendirme yapabilirsin
  }

  /// Test için public bildirim gösterme metodu
  Future<void> showTestNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _showLocalNotification(
      title: title,
      body: body,
      payload: payload,
    );
  }

  /// Local bildirim göster
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'default_channel',
      'Genel Bildirimler',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// FCM Token'ı Firestore'a kaydet
  Future<void> _saveFcmToken(String token) async {
    try {
      // Kullanıcı giriş yapmışsa token'ı kaydet
      // Bu kısmı auth_repository'den çağırabilirsin
      print('💾 FCM Token kaydedilecek: $token');
    } catch (e) {
      print('❌ Token kaydetme hatası: $e');
    }
  }

  /// Kullanıcının FCM Token'ını kaydet
  Future<void> saveUserToken(String userId) async {
    if (_fcmToken == null) {
      print('⚠️ FCM Token henüz alınmadı');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('kullanicilar')
          .doc(userId)
          .update({
        'fcm_token': _fcmToken,
        'token_guncelleme_tarihi': FieldValue.serverTimestamp(),
      });
      print('✅ FCM Token Firestore\'a kaydedildi');
    } catch (e) {
      print('❌ Token kaydetme hatası: $e');
    }
  }

  /// Belirli bir kullanıcıya bildirim gönder
  /// NOT: Bu fonksiyon Cloud Functions'tan çağrılacak
  /// Şimdilik sadece örnek olarak koyuyoruz
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // Bu kısım Cloud Functions'ta çalışacak
    // Şimdi sadece yapıyı gösteriyoruz
    print('📤 Bildirim gönderilecek: $userId - $title');
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _showLocalNotification(
      title: title,
      body: body,
      payload: payload,
    );
  }

  /// Personele iş atandığında bildirim gönder
  Future<void> isePersonelAtandiBindirimi({
    required String personelId,
    required String isBaslik,
    required String isId,
  }) async {
    try {
      // Personelin kullanıcı bilgisini al
      final personelDoc = await FirebaseFirestore.instance
          .collection('personeller')
          .doc(personelId)
          .get();

      if (!personelDoc.exists) {
        print('⚠️ Personel bulunamadı');
        return;
      }

      final personelData = personelDoc.data() as Map<String, dynamic>;
      final kullaniciUid = personelData['kullanici_uid'] as String?;

      if (kullaniciUid == null) {
        print('⚠️ Personelin kullanici_uid yok');
        return;
      }

      // Kullanıcının FCM token'ını al
      final kullaniciDoc = await FirebaseFirestore.instance
          .collection('kullanicilar')
          .doc(kullaniciUid)
          .get();

      if (!kullaniciDoc.exists) {
        print('⚠️ Kullanıcı bulunamadı');
        return;
      }

      final kullaniciData = kullaniciDoc.data() as Map<String, dynamic>;
      final fcmToken = kullaniciData['fcm_token'] as String?;

      if (fcmToken == null) {
        print('⚠️ Kullanıcının FCM token yok');
        return;
      }

      // Local bildirim göster (uygulama açıkken)
      await showLocalNotification(
        title: '💼 Yeni İş Atandı!',
        body: '$isBaslik işi size atandı.',
        payload: '{"tip":"yeni_is","is_id":"$isId"}',
      );

      // Bildirim verisini Firestore'a kaydet
      await FirebaseFirestore.instance.collection('bildirimler').add({
        'kullanici_uid': kullaniciUid,
        'fcm_token': fcmToken,
        'baslik': '💼 Yeni İş Atandı!',
        'mesaj': '$isBaslik işi size atandı.',
        'tip': 'yeni_is',
        'is_id': isId,
        'okundu': false,
        'olusturma_tarihi': FieldValue.serverTimestamp(),
      });

      print('✅ İş atama bildirimi kaydedildi');
    } catch (e) {
      print('❌ Bildirim hatası: $e');
    }
  }

  /// İş durumu değiştiğinde bildirim gönder
  Future<void> isDurumuDegistiBindirimi({
    required String isId,
    required String isBaslik,
    required String yeniDurum,
    required List<String> personelIdler,
  }) async {
    try {
      // Emoji seç
      String emoji = '🔄';
      if (yeniDurum == 'Tamamlandı') emoji = '✅';
      if (yeniDurum == 'İptal') emoji = '❌';
      if (yeniDurum == 'Devam Ediyor') emoji = '⏳';

      for (String personelId in personelIdler) {
        // Personelin kullanıcı bilgisini al
        final personelDoc = await FirebaseFirestore.instance
            .collection('personeller')
            .doc(personelId)
            .get();

        if (!personelDoc.exists) continue;

        final personelData = personelDoc.data() as Map<String, dynamic>;
        final kullaniciUid = personelData['kullanici_uid'] as String?;

        if (kullaniciUid == null) continue;

        // Kullanıcının FCM token'ını al
        final kullaniciDoc = await FirebaseFirestore.instance
            .collection('kullanicilar')
            .doc(kullaniciUid)
            .get();

        if (!kullaniciDoc.exists) continue;

        final kullaniciData = kullaniciDoc.data() as Map<String, dynamic>;
        final fcmToken = kullaniciData['fcm_token'] as String?;

        if (fcmToken == null) continue;

        // Local bildirim göster
        await showLocalNotification(
          title: '$emoji İş Durumu Güncellendi',
          body: '$isBaslik işi "$yeniDurum" durumuna geçti.',
          payload: '{"tip":"durum_degisti","is_id":"$isId"}',
        );

        // Bildirim kaydı oluştur
        await FirebaseFirestore.instance.collection('bildirimler').add({
          'kullanici_uid': kullaniciUid,
          'fcm_token': fcmToken,
          'baslik': '$emoji İş Durumu Güncellendi',
          'mesaj': '$isBaslik işi "$yeniDurum" durumuna geçti.',
          'tip': 'durum_degisti',
          'is_id': isId,
          'okundu': false,
          'olusturma_tarihi': FieldValue.serverTimestamp(),
        });
      }

      print('✅ Durum bildirimleri kaydedildi');
    } catch (e) {
      print('❌ Bildirim hatası: $e');
    }
  }

  /// İşten çıkarıldığında bildirim gönder
  Future<void> istenCikarildiBindirimi({
    required String personelId,
    required String isBaslik,
  }) async {
    try {
      // Personelin kullanıcı bilgisini al
      final personelDoc = await FirebaseFirestore.instance
          .collection('personeller')
          .doc(personelId)
          .get();

      if (!personelDoc.exists) return;

      final personelData = personelDoc.data() as Map<String, dynamic>;
      final kullaniciUid = personelData['kullanici_uid'] as String?;

      if (kullaniciUid == null) return;

      // Kullanıcının FCM token'ını al
      final kullaniciDoc = await FirebaseFirestore.instance
          .collection('kullanicilar')
          .doc(kullaniciUid)
          .get();

      if (!kullaniciDoc.exists) return;

      final kullaniciData = kullaniciDoc.data() as Map<String, dynamic>;
      final fcmToken = kullaniciData['fcm_token'] as String?;

      if (fcmToken == null) return;

      // Local bildirim göster
      await showLocalNotification(
        title: '⚠️ İşten Çıkarıldınız',
        body: '$isBaslik işinden çıkarıldınız.',
        payload: '{"tip":"is_cikarildi"}',
      );

      // Bildirim kaydı oluştur
      await FirebaseFirestore.instance.collection('bildirimler').add({
        'kullanici_uid': kullaniciUid,
        'fcm_token': fcmToken,
        'baslik': '⚠️ İşten Çıkarıldınız',
        'mesaj': '$isBaslik işinden çıkarıldınız.',
        'tip': 'is_cikarildi',
        'okundu': false,
        'olusturma_tarihi': FieldValue.serverTimestamp(),
      });

      print('✅ İşten çıkarma bildirimi kaydedildi');
    } catch (e) {
      print('❌ Bildirim hatası: $e');
    }
  }

  Future<void> isePersonelAtandiTopluBildirim({
    required String isId,
    required String isBaslik,
    required List<String> personelIdler,
  }) async {
    for (String personelId in personelIdler) {
      await isePersonelAtandiBindirimi(
        personelId: personelId,
        isBaslik: isBaslik,
        isId: isId,
      );
    }
  }

}



