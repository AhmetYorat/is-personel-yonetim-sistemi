import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:personel_takip/data/entity/is.dart';
import 'package:personel_takip/services/notification_service.dart';
import 'package:personel_takip/ui/views/test_bildirim_sayfa.dart';
import '../cubit/auth_cubit.dart';
import 'is_detay_sayfa.dart';

class DashboardSayfa extends StatelessWidget {
  const DashboardSayfa({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Sayfa'),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Bildirim Testi',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TestBildirimSayfa(),
                ),
              );
            },
          ),
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return IconButton(
                  icon: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(
                      state.kullanici.email[0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.indigo.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Çıkış Yap'),
                        content: Text(
                          '${state.kullanici.email}\n\nÇıkış yapmak istediğinize emin misiniz?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('İptal'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              context.read<AuthCubit>().cikisYap();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Çıkış Yap'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }
              return SizedBox.shrink();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hoşgeldin Mesajı
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                if (state is AuthAuthenticated) {
                  return Card(
                    color: Colors.indigo.shade700,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            child: Text(
                              state.kullanici.email[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 28,
                                color: Colors.indigo.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Hoş Geldiniz',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  state.kullanici.email,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    state.kullanici.rol.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),
            const SizedBox(height: 24),

            // İstatistik Kartları - Role Göre
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, authState) {
                if (authState is! AuthAuthenticated) {
                  return SizedBox.shrink();
                }

                bool isAdmin = authState.kullanici.rol == 'admin';

                if (isAdmin) {
                  // Admin için: Personeller | İşler | Bugünkü İşler
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.people,
                              title: 'Personeller',
                              collection: 'personeller',
                              color: Colors.indigo.shade700,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.work,
                              title: 'İşler',
                              collection: 'isler',
                              color: Colors.indigo.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildAdminBugunkunIslerStatCard(),
                    ],
                  );
                } else {
                  // Personel için: İşlerim | Bugünkü İşlerim
                  return Row(
                    children: [
                      Expanded(
                        child: _buildPersonelIsStatCard(authState.kullanici.uid),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildPersonelBugunkunIslerStatCard(authState.kullanici.uid),
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 24),

            // Bugünkü İşler
            _buildBugunkunIslerBaslik(),
            const SizedBox(height: 12),
            _buildBugunkunIsler(),
          ],
        ),
      ),
    );
  }

  // İstatistik Kartı Widget'ı (Admin için)
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String collection,
    required Color color,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .where('aktif', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        int count = snapshot.hasData ? snapshot.data!.docs.length : 0;

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(icon, size: 40, color: color),
                const SizedBox(height: 8),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Admin için bugünkü işler sayısı kartı
  Widget _buildAdminBugunkunIslerStatCard() {
    DateTime bugun = DateTime.now();
    DateTime bugunBaslangic = DateTime(bugun.year, bugun.month, bugun.day);
    DateTime bugunBitis = bugunBaslangic.add(Duration(days: 1));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('isler')
          .where('aktif', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        int count = 0;

        if (snapshot.hasData) {
          // Bugünkü işleri filtrele
          count = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            var baslangicTarihi = (data['baslangicTarihi'] as Timestamp).toDate();
            return baslangicTarihi.isAfter(bugunBaslangic) &&
                baslangicTarihi.isBefore(bugunBitis);
          }).length;
        }

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.today, size: 40, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    Text(
                      'Bugünkü İşler',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// Personel için bugünkü işler sayısı kartı
  Widget _buildPersonelBugunkunIslerStatCard(String kullaniciUid) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('personeller')
          .where('kullanici_uid', isEqualTo: kullaniciUid)
          .where('aktif', isEqualTo: true)
          .limit(1)
          .get(),
      builder: (context, personelSnapshot) {
        if (!personelSnapshot.hasData || personelSnapshot.data!.docs.isEmpty) {
          return _buildStatCardWidget(
              0, Icons.today, 'Bugünkü İşlerim', Colors.orange.shade700);
        }

        var personelData = personelSnapshot.data!.docs.first.data() as Map<String, dynamic>;
        String personelId = personelData['id'] as String;

        DateTime bugun = DateTime.now();
        DateTime bugunBaslangic = DateTime(bugun.year, bugun.month, bugun.day);
        DateTime bugunBitis = bugunBaslangic.add(Duration(days: 1));

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('isler')
              .where('aktif', isEqualTo: true)
              .where('atananPersonelIdler', arrayContains: personelId)
              .snapshots(),
          builder: (context, snapshot) {
            int count = 0;

            if (snapshot.hasData) {
              // Bugünkü işleri filtrele
              count = snapshot.data!.docs.where((doc) {
                var data = doc.data() as Map<String, dynamic>;
                var baslangicTarihi = (data['baslangicTarihi'] as Timestamp).toDate();
                return baslangicTarihi.isAfter(bugunBaslangic) &&
                    baslangicTarihi.isBefore(bugunBitis);
              }).length;
            }

            return _buildStatCardWidget(
                count, Icons.today, 'Bugünkü İşlerim', Colors.orange.shade700);
          },
        );
      },
    );
  }

  Widget _buildPersonelIsStatCard(String kullaniciUid) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('personeller')
          .where('kullanici_uid', isEqualTo: kullaniciUid)
          .where('aktif', isEqualTo: true)
          .limit(1)
          .get(),
      builder: (context, personelSnapshot) {
        if (!personelSnapshot.hasData || personelSnapshot.data!.docs.isEmpty) {
          return _buildStatCardWidget(
              0, Icons.work, 'İşlerim', Colors.indigo.shade700);
        }


        var personelData = personelSnapshot.data!.docs.first.data() as Map<String, dynamic>;
        String personelId = personelData['id'] as String;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('isler')
              .where('aktif', isEqualTo: true)
              .where('atananPersonelIdler', arrayContains: personelId)
              .snapshots(),
          builder: (context, snapshot) {
            int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
            return _buildStatCardWidget(
                count, Icons.work, 'İşlerim', Colors.indigo.shade700);
          },
        );
      },
    );
  }

  // Stat card UI widget'ı
  Widget _buildStatCardWidget(int count, IconData icon, String title, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bugünkü İşler Başlık
  Widget _buildBugunkunIslerBaslik() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return SizedBox.shrink();
        }

        bool isAdmin = authState.kullanici.rol == 'admin';

        return Text(
          isAdmin ? 'Bugünkü İşler' : 'Bugünkü İşlerim',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.indigo.shade700,
          ),
        );
      },
    );
  }

  // Bugünkü İşler - Role göre
  Widget _buildBugunkunIsler() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return SizedBox.shrink();
        }

        bool isAdmin = authState.kullanici.rol == 'admin';

        return isAdmin
            ? _buildAdminBugunkunIsler()
            : _buildPersonelBugunkunIsler(authState.kullanici.uid);
      },
    );
  }

  // Admin için tüm bugünkü işler
  Widget _buildAdminBugunkunIsler() {
    DateTime bugun = DateTime.now();
    DateTime bugunBaslangic = DateTime(bugun.year, bugun.month, bugun.day);
    DateTime bugunBitis = bugunBaslangic.add(Duration(days: 1));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('isler')
          .where('baslangicTarihi', isGreaterThanOrEqualTo: bugunBaslangic)
          .where('baslangicTarihi', isLessThan: bugunBitis)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        var aktifIsler = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return data['aktif'] == true;
        }).toList();

        if (aktifIsler.isEmpty) {
          return _buildBosIslerCard();
        }

        return _buildIslerListesi(aktifIsler);
      },
    );
  }

  // Personel için sadece kendi bugünkü işleri
  Widget _buildPersonelBugunkunIsler(String kullaniciUid) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('personeller')
          .where('kullanici_uid', isEqualTo: kullaniciUid)
          .where('aktif', isEqualTo: true)
          .limit(1)
          .get(),
      builder: (context, personelSnapshot) {
        if (!personelSnapshot.hasData || personelSnapshot.data!.docs.isEmpty) {
          return _buildBosIslerCard();
        }

        // ✅ Düzeltme burada
        var personelData = personelSnapshot.data!.docs.first.data() as Map<String, dynamic>;
        String personelId = personelData['id'] as String;

        DateTime bugun = DateTime.now();
        DateTime bugunBaslangic = DateTime(bugun.year, bugun.month, bugun.day);
        DateTime bugunBitis = bugunBaslangic.add(Duration(days: 1));

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('isler')
              .where('baslangicTarihi',
              isGreaterThanOrEqualTo: bugunBaslangic)
              .where('baslangicTarihi', isLessThan: bugunBitis)
              .where('atananPersonelIdler', arrayContains: personelId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            var aktifIsler = snapshot.data!.docs.where((doc) {
              var data = doc.data() as Map<String, dynamic>;
              return data['aktif'] == true;
            }).toList();

            if (aktifIsler.isEmpty) {
              return _buildBosIslerCard();
            }

            return _buildIslerListesi(aktifIsler);
          },
        );
      },
    );
  }

  // Boş işler kartı
  Widget _buildBosIslerCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.event_busy, size: 60, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Bugün için iş yok',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // İşler listesi
  Widget _buildIslerListesi(List<QueryDocumentSnapshot> isler) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: isler.length,
      itemBuilder: (context, index) {
        Is is_item = Is.fromMap(isler[index].data() as Map<String, dynamic>);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => IsDetaySayfa(is_: is_item),
              ),
            );
          },
          child: Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Is.getDurumColor(is_item.durum),
                child: Icon(
                  Is.getDurumIcon(is_item.durum),
                  color: Colors.white,
                ),
              ),
              title: Text(
                is_item.musteriAdi,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(is_item.adres),
              trailing: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Is.getDurumColor(is_item.durum),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  is_item.durum,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

