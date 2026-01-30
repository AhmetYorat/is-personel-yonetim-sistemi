import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:personel_takip/ui/views/tahsilat_d%C3%BCzenle_sayfa.dart';
import '../../data/entity/tahsilat.dart';
import '../cubit/tahsilat_cubit.dart';

class TahsilatDetaySayfa extends StatefulWidget {
  final Tahsilat tahsilat;

  const TahsilatDetaySayfa({super.key, required this.tahsilat});

  @override
  State<TahsilatDetaySayfa> createState() => _TahsilatDetaySayfaState();
}

class _TahsilatDetaySayfaState extends State<TahsilatDetaySayfa> {
  late Tahsilat guncelTahsilat;

  @override
  void initState() {
    super.initState();
    guncelTahsilat = widget.tahsilat;
  }

  void _odemeEkle() {
    final _tutarController = TextEditingController();
    final _notController = TextEditingController();
    String secilenOdemeSekli = 'Nakit';

    showDialog(
      context: context,
      builder: (dialogContext) =>
          AlertDialog(
            title: const Text('Ödeme Ekle'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Kalan borç bilgisi
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kalan Borç',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                              Text(
                                NumberFormat('#,##0', 'tr_TR').format(guncelTahsilat.kalanTutar) + ' ₺',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tutar
                  TextFormField(
                    controller: _tutarController,
                    decoration: InputDecoration(
                      labelText: 'Ödenen Tutar (₺)',
                      prefixIcon: Icon(Icons.payments),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixText: '₺',
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                        decimal: true),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),

                  // Ödeme Şekli
                  DropdownButtonFormField<String>(
                    value: secilenOdemeSekli,
                    decoration: InputDecoration(
                      labelText: 'Ödeme Şekli',
                      prefixIcon: Icon(Icons.credit_card),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: ['Nakit', 'Kredi Kartı', 'Havale', 'EFT']
                        .map((sekil) =>
                        DropdownMenuItem(
                          value: sekil,
                          child: Text(sekil),
                        ))
                        .toList(),
                    onChanged: (value) {
                      secilenOdemeSekli = value!;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Not
                  TextFormField(
                    controller: _notController,
                    decoration: InputDecoration(
                      labelText: 'Not (Opsiyonel)',
                      prefixIcon: Icon(Icons.note),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final tutar = double.tryParse(_tutarController.text.trim());

                  if (tutar == null || tutar <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Geçerli bir tutar girin'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (tutar > guncelTahsilat.kalanTutar) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Ödeme tutarı kalan borçtan fazla olamaz'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final yeniOdeme = OdemeKayit(
                    tarih: DateTime.now(),
                    tutar: tutar,
                    odemeSekli: secilenOdemeSekli,
                    not: _notController.text.trim(),
                  );

                  await context.read<TahsilatCubit>().odemeEkle(
                    guncelTahsilat.id,
                    yeniOdeme,
                  );

                  // State'i güncelle
                  setState(() {
                    guncelTahsilat.odemeler.add(yeniOdeme);
                    guncelTahsilat.odenenTutar += tutar;
                    guncelTahsilat.sonOdemeTarihi = yeniOdeme.tarih;

                    if (guncelTahsilat.odenenTutar >=
                        guncelTahsilat.toplamTutar) {
                      guncelTahsilat.durum = 'tamamlandi';
                    } else if (guncelTahsilat.odenenTutar > 0) {
                      guncelTahsilat.durum = 'kismen';
                    }
                  });

                  if (mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ Ödeme kaydedildi'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Kaydet'),
              ),
            ],
          ),
    );
  }

  void _tahsilatSil() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Tahsilatı Sil'),
            content: Text(
              '${guncelTahsilat
                  .musteriAdi} tahsilatını silmek istediğinize emin misiniz?\n\nBu işlem geri alınamaz.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await context.read<TahsilatCubit>().tahsilatSil(
                      guncelTahsilat.id);

                  if (mounted) {
                    Navigator.pop(context); // Dialog
                    Navigator.pop(context); // Detay sayfası
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Tahsilat silindi'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Sil'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final durumRenk = Tahsilat.getDurumColor(guncelTahsilat.durum);
    final durumIkon = Tahsilat.getDurumIcon(guncelTahsilat.durum);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tahsilat Detayı'),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final yeniTahsilat = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TahsilatDuzenleSayfa(tahsilat: guncelTahsilat),
                ),
              );

              if (yeniTahsilat != null && mounted) {
                setState(() {
                  guncelTahsilat = yeniTahsilat;
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _tahsilatSil,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                  Row(
                    children: [
                      Icon(Icons.person, size: 28,
                          color: Colors.indigo.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          guncelTahsilat.musteriAdi,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
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
                              Tahsilat.getDurumText(guncelTahsilat.durum),
                              style: TextStyle(
                                color: durumRenk,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    guncelTahsilat.aciklama,
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

          // Tutar Bilgileri
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tutar Bilgileri',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTutarKart(
                          'Toplam',
                          guncelTahsilat.toplamTutar,
                          Colors.blue,
                          Icons.account_balance_wallet,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTutarKart(
                          'Ödenen',
                          guncelTahsilat.odenenTutar,
                          Colors.green,
                          Icons.check_circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTutarKart(
                          'Kalan',
                          guncelTahsilat.kalanTutar,
                          Colors.red,
                          Icons.warning,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Ödeme Geçmişi
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Ödeme Geçmişi',
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
                          '${guncelTahsilat.odemeler.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (guncelTahsilat.durum != 'tamamlandi')
                        IconButton(
                          icon: const Icon(
                              Icons.add_circle, color: Colors.green),
                          onPressed: _odemeEkle,
                        ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (guncelTahsilat.odemeler.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(
                              Icons.payment,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Henüz ödeme yapılmamış',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      children: guncelTahsilat.odemeler.reversed.map((odeme) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: Colors.green.shade50,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Icon(Icons.payment, color: Colors.white),
                            ),
                            title: Text(
                              NumberFormat('#,##0', 'tr_TR').format(odeme.tutar) + ' ₺',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${odeme.odemeSekli} • ${DateFormat(
                                      'dd.MM.yyyy HH:mm').format(odeme.tarih)}',
                                ),
                                if (odeme.not.isNotEmpty)
                                  Text(
                                    odeme.not,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: guncelTahsilat.durum != 'tamamlandi'
          ? FloatingActionButton.extended(
        onPressed: _odemeEkle,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add),
        label: const Text('Ödeme Ekle'),
      )
          : null,
    );
  }

  Widget _buildTutarKart(String baslik, double tutar, Color renk,
      IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: renk.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: renk.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: renk, size: 24),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              NumberFormat('#,##0', 'tr_TR').format(tutar) + ' ₺',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: renk,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            baslik,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}