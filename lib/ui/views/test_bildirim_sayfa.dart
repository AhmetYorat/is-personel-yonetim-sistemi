import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:personel_takip/services/notification_service.dart';

class TestBildirimSayfa extends StatefulWidget {
  const TestBildirimSayfa({super.key});

  @override
  State<TestBildirimSayfa> createState() => _TestBildirimSayfaState();
}

class _TestBildirimSayfaState extends State<TestBildirimSayfa> {
  final _notificationService = NotificationService();
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _tokenAl();
  }

  void _tokenAl() {
    setState(() {
      _fcmToken = _notificationService.fcmToken;
    });
    print('🔑 Alınan Token: $_fcmToken');
  }

  void _tokenKopyala() {
    if (_fcmToken != null) {
      Clipboard.setData(ClipboardData(text: _fcmToken!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Token panoya kopyalandı!'),
          backgroundColor: Colors.indigo,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _tokenYenile() async {
    await _notificationService.initialize();
    _tokenAl();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔄 Token yenilendi!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Test Merkezi'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Token Yenile',
            onPressed: _tokenYenile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // FCM TOKEN KARTI
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade50, Colors.indigo.shade100],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.indigo,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.key, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'FCM Token',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: _tokenKopyala,
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.indigo.shade200),
                      ),
                      child: _fcmToken != null
                          ? SelectableText(
                        _fcmToken!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'Courier',
                        ),
                      )
                          : const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Token alınıyor...')
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // TEST SENARYOLARI
            _buildTestButton(
              icon: Icons.notifications,
              title: 'Basit Bildirim',
              description: 'Standart bildirim testi',
              color: Colors.indigo,
              onPressed: () {
                _notificationService.showTestNotification(
                  title: 'Test Bildirimi 🔔',
                  body: 'Merhaba! Bildirim sistemi çalışıyor.',
                );
                _showSuccess('Basit bildirim gönderildi');
              },
            ),

            const SizedBox(height: 12),

            _buildTestButton(
              icon: Icons.work,
              title: 'Yeni İş Atandı',
              description: 'İş atama bildirimi',
              color: Colors.blue,
              onPressed: () {
                _notificationService.showTestNotification(
                  title: '💼 Yeni İş Atandı!',
                  body: 'Villa Tadilat İşi size atandı.',
                  payload: '{"type":"yeni_is","is_id":"abc123"}',
                );
                _showSuccess('İş atama bildirimi gönderildi');
              },
            ),

            const SizedBox(height: 12),

            _buildTestButton(
              icon: Icons.update,
              title: 'İş Durumu Güncellendi',
              description: 'Durum değişikliği bildirimi',
              color: Colors.orange,
              onPressed: () {
                _notificationService.showTestNotification(
                  title: '🔄 İş Durumu Değişti',
                  body: 'İş durumu güncellendi.',
                  payload: '{"type":"durum_degisti","is_id":"def456"}',
                );
                _showSuccess('Durum bildirimi gönderildi');
              },
            ),

            const SizedBox(height: 12),

            _buildTestButton(
              icon: Icons.warning_amber,
              title: 'Acil Bildirim',
              description: 'Yüksek öncelikli bildirim',
              color: Colors.red,
              onPressed: () {
                _notificationService.showTestNotification(
                  title: '🚨 ACİL!',
                  body: 'İş iptal edildi.',
                  payload: '{"type":"acil","is_id":"ghi789"}',
                );
                _showSuccess('Acil bildirim gönderildi');
              },
            ),

            const SizedBox(height: 12),

            _buildTestButton(
              icon: Icons.check_circle,
              title: 'İş Tamamlandı',
              description: 'Tamamlanma bildirimi',
              color: Colors.green,
              onPressed: () {
                _notificationService.showTestNotification(
                  title: '✅ İş Tamamlandı!',
                  body: 'İş başarıyla tamamlandı.',
                  payload: '{"type":"tamamlandi","is_id":"jkl012"}',
                );
                _showSuccess('Tamamlanma bildirimi gönderildi');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: Icon(Icons.play_arrow, color: color),
        onTap: onPressed,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
