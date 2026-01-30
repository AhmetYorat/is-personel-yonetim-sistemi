import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../data/entity/tahsilat.dart';
import '../cubit/tahsilat_cubit.dart';
import '../cubit/auth_cubit.dart';
import 'tahsilat_detay_sayfa.dart';
import 'tahsilat_ekle_sayfa.dart';

class TahsilatlarSayfa extends StatefulWidget {
  const TahsilatlarSayfa({super.key});

  @override
  State<TahsilatlarSayfa> createState() => _TahsilatlarSayfaState();
}

class _TahsilatlarSayfaState extends State<TahsilatlarSayfa> {
  String secilenDurum = "Tümü";
  var aramaController = TextEditingController();

  final List<String> durumlar = [
    'Tümü',
    'bekliyor',
    'kismen',
    'tamamlandi',
  ];

  @override
  void initState() {
    super.initState();
    context.read<TahsilatCubit>().tahsilatlariYukle();
  }

  @override
  void dispose() {
    aramaController.dispose();
    super.dispose();
  }

  void durumFiltrele(String durum) {
    setState(() {
      secilenDurum = durum;
      aramaController.clear();
    });
    if (durum == "Tümü") {
      context.read<TahsilatCubit>().tahsilatlariYukle();
    } else {
      context.read<TahsilatCubit>().tahsilatlariDurumaGoreYukle(durum);
    }
  }

  void aramaYap(String arama) {
    if (secilenDurum != 'Tümü') {
      setState(() {
        secilenDurum = 'Tümü';
      });
    }
    context.read<TahsilatCubit>().tahsilatAra(arama);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alacaklar / Tahsilatlar'),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        actions: [
          // Sadece admin ekleyebilir
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated && state.kullanici.isAdmin) {
                return IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TahsilatEkleSayfa(),
                      ),
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
          // Arama
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: aramaController,
              onChanged: aramaYap,
              decoration: InputDecoration(
                hintText: "Müşteri veya açıklama ara",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: aramaController.text.isNotEmpty
                    ? IconButton(
                    onPressed: () {
                      aramaController.clear();
                      context.read<TahsilatCubit>().tahsilatlariYukle();
                    },
                    icon: const Icon(Icons.clear))
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Durum Filtreleri
          SizedBox(
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
                    label: Text(
                      durum == 'Tümü'
                          ? 'Tümü'
                          : Tahsilat.getDurumText(durum),
                    ),
                    selected: secili,
                    onSelected: (_) => durumFiltrele(durum),
                    backgroundColor: Colors.grey.shade200,
                    selectedColor: durum == 'Tümü'
                        ? Colors.indigo.shade100
                        : Tahsilat.getDurumColor(durum).withOpacity(0.3),
                    checkmarkColor: durum == 'Tümü'
                        ? Colors.indigo
                        : Tahsilat.getDurumColor(durum),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Tahsilat Listesi
          Expanded(
            child: BlocBuilder<TahsilatCubit, List<Tahsilat>>(
              builder: (context, tahsilatlar) {
                if (tahsilatlar.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.payment_outlined, size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          aramaController.text.isNotEmpty
                              ? 'Arama sonucu bulunamadı'
                              : secilenDurum == 'Tümü'
                              ? 'Henüz tahsilat eklenmemiş'
                              : '${Tahsilat.getDurumText(secilenDurum)} durumunda tahsilat yok',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tahsilatlar.length,
                  itemBuilder: (context, index) {
                    var tahsilat = tahsilatlar[index];
                    return _TahsilatKarti(
                      tahsilat: tahsilat,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TahsilatDetaySayfa(tahsilat: tahsilat),
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

// Tahsilat Kartı Widget
class _TahsilatKarti extends StatelessWidget {
  final Tahsilat tahsilat;
  final VoidCallback onTap;

  const _TahsilatKarti({required this.tahsilat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final durumRenk = Tahsilat.getDurumColor(tahsilat.durum);
    final durumIkon = Tahsilat.getDurumIcon(tahsilat.durum);
    final odemeYuzdesi = (tahsilat.odenenTutar / tahsilat.toplamTutar * 100).clamp(0, 100);

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
              // Üst kısım: Müşteri + Durum
              Row(
                children: [
                  Icon(Icons.person, size: 20, color: Colors.indigo.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tahsilat.musteriAdi,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
                          Tahsilat.getDurumText(tahsilat.durum),
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

              // Açıklama
              Text(
                tahsilat.aciklama,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Tutar bilgileri
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Toplam Tutar',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        Text(
                          NumberFormat('#,##0', 'tr_TR').format(tahsilat.toplamTutar) + ' ₺',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ödenen',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        Text(
                          NumberFormat('#,##0', 'tr_TR').format(tahsilat.odenenTutar) + ' ₺',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kalan',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        Text(
                          NumberFormat('#,##0', 'tr_TR').format(tahsilat.kalanTutar) + ' ₺',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: odemeYuzdesi / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(durumRenk),
                ),
              ),

              const SizedBox(height: 8),

              // Alt bilgiler
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd.MM.yyyy').format(tahsilat.olusturulmaTarihi),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  if (tahsilat.istenOlusturuldu) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.work, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'İş\'ten oluşturuldu',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}