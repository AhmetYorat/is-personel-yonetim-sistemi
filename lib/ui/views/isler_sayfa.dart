import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:personel_takip/data/entity/is.dart';
import 'package:personel_takip/ui/cubit/auth_cubit.dart';
import 'package:personel_takip/ui/cubit/is_cubit.dart';
import 'package:personel_takip/ui/views/is_detay_sayfa.dart';
import 'package:personel_takip/ui/views/is_ekle_sayfa.dart';

class IslerSayfa extends StatefulWidget {
  const IslerSayfa({super.key});

  @override
  State<IslerSayfa> createState() => _IslerSayfaState();
}

class _IslerSayfaState extends State<IslerSayfa> {
  String secilenDurum = "Tümü";
  var aramaController = TextEditingController();

  final List<String> durumlar = [
    'Tümü',
    'Beklemede',
    'Devam Ediyor',
    'Tamamlandı',
    'İptal'
  ];

  @override
  void initState() {
    super.initState();
    _isleriYukle();
  }

  @override
  void dispose() {
    aramaController.dispose();
    super.dispose();
  }

  // ✅ Merkezi iş yükleme metodu - Rol kontrolü ile
  void _isleriYukle() {
    final authState = context.read<AuthCubit>().state;

    if (authState is AuthAuthenticated) {
      if (authState.kullanici.rol == 'admin') {
        // Admin - Tüm işleri göster
        context.read<IsCubit>().isleriYukle();
      } else {
        // Personel - Sadece kendi işlerini göster
        context.read<IsCubit>().personelIsleriYukle(authState.kullanici.uid);
      }
    }
  }

  void durumFiltrele(String durum) {
    setState(() {
      secilenDurum = durum;
      aramaController.clear();
    });

    final authState = context.read<AuthCubit>().state;

    if (authState is AuthAuthenticated) {
      if (durum == "Tümü") {
        // ✅ Tümü seçildiğinde role göre işleri yükle
        if (authState.kullanici.rol == 'admin') {
          context.read<IsCubit>().isleriYukle();
        } else {
          context.read<IsCubit>().personelIsleriYukle(authState.kullanici.uid);
        }
      } else {
        // ✅ Durum filtreleme - Sadece admin yapabilsin
        if (authState.kullanici.rol == 'admin') {
          context.read<IsCubit>().isleriDurumaGoreYukle(durum);
        } else {
          // Personel için durum filtresi şimdilik yok
          // personelIsleriDurumaGoreYukle metodu eklenebilir
          context.read<IsCubit>().personelIsleriYukle(authState.kullanici.uid);
        }
      }
    }
  }

  void aramaYap(String arama) {
    if (secilenDurum != 'Tümü') {
      setState(() {
        secilenDurum = 'Tümü';
      });
    }

    final authState = context.read<AuthCubit>().state;

    if (authState is AuthAuthenticated) {
      if (arama.isEmpty) {
        // Arama temizlendiğinde role göre yükle
        if (authState.kullanici.rol == 'admin') {
          context.read<IsCubit>().isleriYukle();
        } else {
          context.read<IsCubit>().personelIsleriYukle(authState.kullanici.uid);
        }
      } else {
        // ✅ Arama - Sadece admin yapabilsin
        if (authState.kullanici.rol == 'admin') {
          context.read<IsCubit>().isAra(arama);
        } else {
          // Personel için arama şimdilik yok
          // İsterseniz personelIsAra metodu eklenebilir
          context.read<IsCubit>().personelIsleriYukle(authState.kullanici.uid);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is AuthAuthenticated && state.kullanici.rol != 'admin') {
              return const Text('İşlerim');
            }
            return const Text('İşler');
          },
        ),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        actions: [
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated && state.kullanici.rol == 'admin') {
                return IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => IsEkleSayfa()),
                    );
                  },
                  icon: Icon(Icons.add),
                );
              }
              return SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ Arama - Sadece admin görsün
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated && state.kullanici.rol == 'admin') {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: aramaController,
                    onChanged: aramaYap,
                    decoration: InputDecoration(
                      hintText: "İş ara (Başlık veya Adres)",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: aramaController.text.isNotEmpty
                          ? IconButton(
                          onPressed: () {
                            aramaController.clear();
                            context.read<IsCubit>().isleriYukle();
                          },
                          icon: const Icon(Icons.clear))
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                );
              }
              return SizedBox.shrink();
            },
          ),

          // ✅ Durum Filtreleri - Sadece admin görsün
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated && state.kullanici.rol == 'admin') {
                return SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: durumlar.length,
                    itemBuilder: (context, index) {
                      var durum = durumlar[index];
                      var secili = secilenDurum == durum;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(durum),
                          selected: secili,
                          onSelected: (_) => durumFiltrele(durum),
                          backgroundColor: Colors.grey.shade200,
                          selectedColor: durum == 'Tümü'
                              ? Colors.indigo.shade100
                              : Is.getDurumColor(durum).withOpacity(0.3),
                          checkmarkColor: durum == 'Tümü'
                              ? Colors.indigo
                              : Is.getDurumColor(durum),
                        ),
                      );
                    },
                  ),
                );
              }
              return SizedBox.shrink();
            },
          ),

          const SizedBox(height: 8),

          // İŞ LİSTESİ
          Expanded(
            child: BlocBuilder<IsCubit, List<Is>>(
              builder: (context, isler) {
                if (isler.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.work_off,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        BlocBuilder<AuthCubit, AuthState>(
                          builder: (context, authState) {
                            String message = 'Henüz iş eklenmemiş';

                            if (authState is AuthAuthenticated) {
                              if (authState.kullanici.rol != 'admin') {
                                message = 'Size atanmış iş bulunmuyor';
                              } else if (aramaController.text.isNotEmpty) {
                                message = 'Arama sonucu bulunamadı';
                              } else if (secilenDurum != 'Tümü') {
                                message = '$secilenDurum durumunda iş yok';
                              }
                            }

                            return Text(
                              message,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: isler.length,
                  itemBuilder: (context, index) {
                    var is_ = isler[index];
                    return _IsKarti(
                      is_: is_,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => IsDetaySayfa(is_: is_),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _IsKarti extends StatelessWidget {
  final Is is_;
  final VoidCallback onTap;

  const _IsKarti({required this.is_, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final durumRenk = Is.getDurumColor(is_.durum);
    final durumIkon = Is.getDurumIcon(is_.durum);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: durumRenk.withOpacity(0.3), width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Müşteri adı
              Row(
                children: [
                  Icon(Icons.person, size: 18, color: Colors.indigo.shade700),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      is_.musteriAdi,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                  ),
                  // Durum badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: durumRenk.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: durumRenk, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(durumIkon, size: 16, color: durumRenk),
                        const SizedBox(width: 4),
                        Text(
                          is_.durum,
                          style: TextStyle(
                            color: durumRenk,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Başlık
              Text(
                is_.baslik,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              // Açıklama
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

              // Adres
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      is_.adres,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Alt bilgiler
              Row(
                children: [
                  // Tarih
                  Icon(Icons.calendar_today,
                      size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd.MM.yyyy').format(is_.baslangicTarihi),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),

                  const SizedBox(width: 16),

                  // Personel sayısı
                  Icon(Icons.people, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${is_.atananPersonelIdler.length} Personel',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),

                  const Spacer(),

                  // Maliyet (varsa)
                  if (is_.maliyet != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${is_.maliyet!.toStringAsFixed(0)} ₺',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}