import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:personel_takip/ui/views/personel_duzenle_sayfa.dart';
import '../../data/entity/personel.dart';
import '../../data/entity/is.dart';
import '../cubit/personel_cubit.dart';
import '../cubit/is_cubit.dart';
import 'is_detay_sayfa.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PersonelDetaySayfa extends StatefulWidget {
  final Personel personel;

  const PersonelDetaySayfa({super.key, required this.personel});

  @override
  State<PersonelDetaySayfa> createState() => _PersonelDetaySayfaState();
}

class _PersonelDetaySayfaState extends State<PersonelDetaySayfa> {
  late Personel guncelPersonel;
  @override
  void initState() {
    super.initState();
    // Personelin işlerini yükle
    guncelPersonel = widget.personel;
    context.read<IsCubit>().personelIdIleIsleriYukle(widget.personel.id);

    print('🔍 Personel ID: ${widget.personel.id}');
    print('🔍 Kullanici UID: ${widget.personel.kullaniciUid}');
  }

  void _personelSil() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Personeli Sil'),
          content: Text(
            '${widget.personel.adSoyad} personelini silmek istediğinize emin misiniz?\n\nBu işlem geri alınamaz.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                await context.read<PersonelCubit>().personelSil(widget.personel.id);

                if (mounted) {
                  Navigator.pop(context); // Dialog kapat
                  Navigator.pop(context); // Detay sayfasından çık
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ ${widget.personel.adSoyad} silindi'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final personel = guncelPersonel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personel Detayı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              // Düzenleme sayfasına git
              final yeniPersonel = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PersonelDuzenleSayfa(personel: guncelPersonel),
                ),
              );

              // Eğer güncelleme yapıldıysa sayfayı yenile
              if (yeniPersonel != null && mounted) {
                setState(() {
                  guncelPersonel = yeniPersonel;
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _personelSil,
          ),
        ],
      ),
      body: ListView(
        children: [
          // Üst Kart - Avatar + Temel Bilgiler
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.indigo, Colors.indigo.shade700],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Text(
                      personel.adSoyad[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    personel.adSoyad,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _rolDegistir,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            personel.pozisyon,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.edit, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        personel.aktif ? Icons.check_circle : Icons.cancel,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        personel.aktif ? 'Aktif' : 'Pasif',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // İletişim Bilgileri
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'İletişim Bilgileri',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),
                    _buildBilgiSatiri(
                      Icons.phone,
                      'Telefon',
                      personel.telefon,
                      Colors.green,
                    ),
                    if (personel.email.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildBilgiSatiri(
                        Icons.email,
                        'E-posta',
                        personel.email,
                        Colors.blue,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // İş Bilgileri
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'İş Bilgileri',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),
                    _buildBilgiSatiri(
                      Icons.calendar_today,
                      'Başlangıç Tarihi',
                      DateFormat('dd MMMM yyyy', 'tr_TR')
                          .format(personel.baslangicTarihi),
                      Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _buildBilgiSatiri(
                      Icons.attach_money,
                      'Maaş',
                      '${personel.maas.toStringAsFixed(0)} ₺',
                      Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildBilgiSatiri(
                      Icons.timer,
                      'Çalışma Süresi',
                      _calismaKideminiHesapla(personel.baslangicTarihi),
                      Colors.purple,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Atanan İşler
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.work, color: Colors.indigo, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Atanan İşler',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                BlocBuilder<IsCubit, List<Is>>(
                  builder: (context, isler) {
                    if (isler.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.work_off,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Henüz iş atanmamış',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    // İstatistikler
                    final beklemede = isler.where((i) => i.durum == 'Beklemede').length;
                    final devamEdiyor = isler.where((i) => i.durum == 'Devam Ediyor').length;
                    final tamamlandi = isler.where((i) => i.durum == 'Tamamlandı').length;

                    return Column(
                      children: [
                        // İstatistik kartları
                        Row(
                          children: [
                            Expanded(
                              child: _buildIstatistikKart(
                                'Toplam',
                                isler.length.toString(),
                                Colors.indigo,
                                Icons.list,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildIstatistikKart(
                                'Devam Ediyor',
                                devamEdiyor.toString(),
                                Colors.blue,
                                Icons.engineering,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildIstatistikKart(
                                'Tamamlandı',
                                tamamlandi.toString(),
                                Colors.green,
                                Icons.check_circle,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // İş listesi
                        ...isler.map((is_) {
                          final durumRenk = Is.getDurumColor(is_.durum);
                          final durumIkon = Is.getDurumIcon(is_.durum);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: durumRenk.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => IsDetaySayfa(is_: is_),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            is_.baslik,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: durumRenk.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: durumRenk,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                durumIkon,
                                                size: 14,
                                                color: durumRenk,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                is_.durum,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: durumRenk,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      is_.aciklama,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            is_.adres,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.calendar_today,
                                          size: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat('dd.MM.yyyy')
                                              .format(is_.baslangicTarihi),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _rolDegistir() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rol Değiştir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${guncelPersonel.adSoyad} için yeni rol seçin:'),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.admin_panel_settings, color: Colors.indigo),
              title: Text('Yönetici'),
              trailing: guncelPersonel.pozisyon == 'Yönetici'
                  ? Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: () async {
                await _rolGuncelle('Yönetici', 'admin');
                Navigator.pop(dialogContext);
              },
            ),
            ListTile(
              leading: Icon(Icons.person, color: Colors.blue),
              title: Text('Personel'),
              trailing: guncelPersonel.pozisyon == 'Personel'
                  ? Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: () async {
                await _rolGuncelle('Personel', 'personel');
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  Future<void> _rolGuncelle(String yeniPozisyon, String yeniRol) async {
    try {
      // 1. Personel koleksiyonunu güncelle
      await FirebaseFirestore.instance
          .collection('personeller')
          .doc(guncelPersonel.id)
          .update({'pozisyon': yeniPozisyon});

      // 2. Kullanıcı koleksiyonunu güncelle (eğer kullanici_uid varsa)
      if (guncelPersonel.kullaniciUid != null) {
        await FirebaseFirestore.instance
            .collection('kullanicilar')
            .doc(guncelPersonel.kullaniciUid)
            .update({'rol': yeniRol});
      }

      // 3. State'i güncelle
      setState(() {
        guncelPersonel.pozisyon = yeniPozisyon;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${guncelPersonel.adSoyad} artık $yeniPozisyon'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildBilgiSatiri(IconData icon, String baslik, String deger, Color renk) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: renk.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: renk),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              baslik,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              deger,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIstatistikKart(String baslik, String deger, Color renk, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: renk, size: 24),
            const SizedBox(height: 8),
            Text(
              deger,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: renk,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              baslik,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _calismaKideminiHesapla(DateTime baslangic) {
    final fark = DateTime.now().difference(baslangic);
    final yil = fark.inDays ~/ 365;
    final ay = (fark.inDays % 365) ~/ 30;

    if (yil > 0) {
      return '$yil yıl ${ay > 0 ? "$ay ay" : ""}';
    } else if (ay > 0) {
      return '$ay ay';
    } else {
      return '${fark.inDays} gün';
    }
  }
}
