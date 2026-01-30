import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:personel_takip/ui/views/is_duzenle_sayfa.dart';
import '../../data/entity/is.dart';
import '../../data/entity/personel.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/is_cubit.dart';
import '../cubit/personel_cubit.dart';

class IsDetaySayfa extends StatefulWidget {
  final Is is_;

  const IsDetaySayfa({super.key, required this.is_});

  @override
  State<IsDetaySayfa> createState() => _IsDetaySayfaState();
}

class _IsDetaySayfaState extends State<IsDetaySayfa> {
  late Is guncelIs;

  @override
  void initState() {
    super.initState();
    guncelIs = widget.is_;
    // Personelleri yükle
    context.read<PersonelCubit>().personelleriYukle();
  }

  void _durumGuncelle() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Durum Güncelle',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ...[
                'Beklemede',
                'Devam Ediyor',
                'Tamamlandı',
                'İptal'
              ].map((durum) {
                final secili = guncelIs.durum == durum;
                return Card(
                  color: secili ? Is.getDurumColor(durum).withOpacity(0.2) : null,
                  child: ListTile(
                    leading: Icon(
                      Is.getDurumIcon(durum),
                      color: Is.getDurumColor(durum),
                    ),
                    title: Text(
                      durum,
                      style: TextStyle(
                        fontWeight: secili ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: secili
                        ? Icon(Icons.check_circle, color: Is.getDurumColor(durum))
                        : null,
                    onTap: () async {
                      await context
                          .read<IsCubit>()
                          .isDurumuGuncelle(guncelIs.id, durum);

                      setState(() {
                        guncelIs.durum = durum;
                        if (durum == 'Tamamlandı') {
                          guncelIs.bitisTarihi = DateTime.now();
                        }
                      });

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ Durum güncellendi: $durum'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                  ),
                );
              }).toList(),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _personelEkle() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_add, color: Colors.indigo),
                      const SizedBox(width: 8),
                      const Text(
                        'Personel Ekle',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: BlocBuilder<PersonelCubit, List<Personel>>(
                    builder: (context, personeller) {
                      // Zaten ekli olmayanları filtrele
                      final eklenebilirPersoneller = personeller
                          .where((p) => !guncelIs.atananPersonelIdler.contains(p.id))
                          .toList();

                      if (eklenebilirPersoneller.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 64,
                                color: Colors.green.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tüm personeller zaten eklendi',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: eklenebilirPersoneller.length,
                        itemBuilder: (context, index) {
                          final personel = eklenebilirPersoneller[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.indigo.shade100,
                                child: Text(
                                  personel.adSoyad[0].toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.indigo.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                personel.adSoyad,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(personel.pozisyon),
                              trailing: IconButton(
                                icon: const Icon(Icons.add_circle, color: Colors.green),
                                onPressed: () async {
                                  await context
                                      .read<IsCubit>()
                                      .isePersonelEkle(guncelIs.id, personel.id);

                                  setState(() {
                                    guncelIs.atananPersonelIdler.add(personel.id);
                                  });

                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            '✅ ${personel.adSoyad} işe eklendi'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _personelCikar(String personelId, String personelAd) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Personeli Çıkar'),
          content: Text('$personelAd personelini bu işten çıkarmak istediğinize emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal', style: TextStyle(color: Colors.black),),
            ),
            ElevatedButton(
              onPressed: () async {
                await context
                    .read<IsCubit>()
                    .istenPersonelCikar(guncelIs.id, personelId);

                setState(() {
                  guncelIs.atananPersonelIdler.remove(personelId);
                });

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ $personelAd işten çıkarıldı'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Çıkar'),
            ),
          ],
        );
      },
    );
  }

  void _isSil() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('İşi Sil'),
          content: Text(
            '"${guncelIs.baslik}" işini silmek istediğinize emin misiniz?\n\nBu işlem geri alınamaz.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                await context.read<IsCubit>().isSil(guncelIs.id);

                if (mounted) {
                  Navigator.pop(context); // Dialog kapat
                  Navigator.pop(context); // Detay sayfasından çık
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ İş silindi'),
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
    final durumRenk = Is.getDurumColor(guncelIs.durum);
    final durumIkon = Is.getDurumIcon(guncelIs.durum);

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        //  Admin kontrolü
        bool isAdmin = false;
        if (authState is AuthAuthenticated) {
          isAdmin = authState.kullanici.rol == 'admin';
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('İş Detayı'),
            actions: isAdmin ? [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  // Düzenleme sayfasına git
                  final yeniIs = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => IsDuzenleSayfa(is_: guncelIs),
                    ),
                  );

                  if (yeniIs != null && mounted) {
                    setState(() {
                      guncelIs = yeniIs; // State'i güncelle
                    });
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _isSil,
              ),
            ] : null,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Durum Kartı
              // Durum Kartı
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: durumRenk, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Müşteri Adı + Durum EN ÜSTE
                      Row(
                        children: [
                          Icon(Icons.person, size: 24, color: Colors.indigo.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              guncelIs.musteriAdi,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo.shade700,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: _durumGuncelle,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: durumRenk.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: durumRenk, width: 2),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(durumIkon, size: 18, color: durumRenk),
                                  const SizedBox(width: 6),
                                  Text(
                                    guncelIs.durum,
                                    style: TextStyle(
                                      color: durumRenk,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.edit, size: 14, color: durumRenk),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Başlık
                      Text(
                        guncelIs.baslik,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        guncelIs.aciklama,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bilgiler Kartı
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bilgiler',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 24),
                      _buildBilgiSatiri(
                        Icons.location_on,
                        'Adres',
                        guncelIs.adres,
                        Colors.red,
                      ),
                      const SizedBox(height: 12),
                      _buildBilgiSatiri(
                        Icons.calendar_today,
                        'Başlangıç',
                        DateFormat('dd MMMM yyyy', 'tr_TR')
                            .format(guncelIs.baslangicTarihi),
                        Colors.blue,
                      ),
                      if (guncelIs.bitisTarihi != null) ...[
                        const SizedBox(height: 12),
                        _buildBilgiSatiri(
                          Icons.event_available,
                          'Bitiş',
                          DateFormat('dd MMMM yyyy', 'tr_TR')
                              .format(guncelIs.bitisTarihi!),
                          Colors.green,
                        ),
                      ],
                      if (guncelIs.maliyet != null) ...[
                        const SizedBox(height: 12),
                        _buildBilgiSatiri(
                          Icons.attach_money,
                          'Maliyet',
                          '${guncelIs.maliyet!.toStringAsFixed(0)} ₺',
                          Colors.orange,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Personel Kartı
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Atanan Personeller',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.indigo,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${guncelIs.atananPersonelIdler.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // ✅ Sadece admin personel ekleyebilir
                          if (isAdmin) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.green),
                              onPressed: _personelEkle,
                            ),
                          ],
                        ],
                      ),
                      const Divider(height: 24),
                      BlocBuilder<PersonelCubit, List<Personel>>(
                        builder: (context, personeller) {
                          if (guncelIs.atananPersonelIdler.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Henüz personel atanmamış',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final atananPersoneller = personeller
                              .where((p) => guncelIs.atananPersonelIdler.contains(p.id))
                              .toList();

                          return Column(
                            children: atananPersoneller.map((personel) {
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                color: Colors.indigo.shade50,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.indigo,
                                    child: Text(
                                      personel.adSoyad[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    personel.adSoyad,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(personel.pozisyon),
                                  // ✅ Sadece admin personel çıkarabilir
                                  trailing: isAdmin
                                      ? IconButton(
                                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                                    onPressed: () => _personelCikar(
                                      personel.id,
                                      personel.adSoyad,
                                    ),
                                  )
                                      : null,
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
}