import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/entity/tahsilat.dart';
import '../cubit/tahsilat_cubit.dart';

class TahsilatDuzenleSayfa extends StatefulWidget {
  final Tahsilat tahsilat;

  const TahsilatDuzenleSayfa({super.key, required this.tahsilat});

  @override
  State<TahsilatDuzenleSayfa> createState() => _TahsilatDuzenleSayfaState();
}

class _TahsilatDuzenleSayfaState extends State<TahsilatDuzenleSayfa> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _musteriAdiController;
  late TextEditingController _aciklamaController;
  late TextEditingController _tutarController;

  @override
  void initState() {
    super.initState();
    _musteriAdiController = TextEditingController(text: widget.tahsilat.musteriAdi);
    _aciklamaController = TextEditingController(text: widget.tahsilat.aciklama);
    _tutarController = TextEditingController(text: widget.tahsilat.toplamTutar.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _musteriAdiController.dispose();
    _aciklamaController.dispose();
    _tutarController.dispose();
    super.dispose();
  }

  void _tahsilatGuncelle() async {
    if (_formKey.currentState!.validate()) {
      final yeniTutar = double.parse(_tutarController.text.trim());

      // Eğer toplam tutar ödenen tutardan küçükse uyar
      if (yeniTutar < widget.tahsilat.odenenTutar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Toplam tutar, ödenen tutardan (${widget.tahsilat.odenenTutar.toStringAsFixed(0)} ₺) küçük olamaz'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final guncelTahsilat = Tahsilat(
        id: widget.tahsilat.id,
        isId: widget.tahsilat.isId,
        musteriAdi: _musteriAdiController.text.trim(),
        aciklama: _aciklamaController.text.trim(),
        toplamTutar: yeniTutar,
        odenenTutar: widget.tahsilat.odenenTutar,
        durum: widget.tahsilat.durum,
        olusturulmaTarihi: widget.tahsilat.olusturulmaTarihi,
        sonOdemeTarihi: widget.tahsilat.sonOdemeTarihi,
        odemeler: widget.tahsilat.odemeler,
        aktif: widget.tahsilat.aktif,
      );

      // Durum kontrolü (tutar değişirse durum da değişebilir)
      if (guncelTahsilat.odenenTutar >= guncelTahsilat.toplamTutar) {
        guncelTahsilat.durum = 'tamamlandi';
      } else if (guncelTahsilat.odenenTutar > 0) {
        guncelTahsilat.durum = 'kismen';
      } else {
        guncelTahsilat.durum = 'bekliyor';
      }

      await context.read<TahsilatCubit>().tahsilatGuncelle(guncelTahsilat);

      Navigator.pop(context, guncelTahsilat);  // Güncel tahsilatı geri döndür
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Tahsilat güncellendi'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tahsilat Düzenle'),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        actions: [  
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _tahsilatGuncelle,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Ödeme bilgisi (değiştirilemez)
            if (widget.tahsilat.odenenTutar > 0)
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Bu tahsilat için ${widget.tahsilat.odenenTutar.toStringAsFixed(0)} ₺ ödeme alınmış. Toplam tutar bu miktardan az olamaz.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Müşteri Adı
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.indigo.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'Müşteri Bilgileri',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _musteriAdiController,
                      decoration: InputDecoration(
                        labelText: 'Müşteri Adı *',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Müşteri adı gerekli';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tahsilat Bilgileri
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.description, color: Colors.indigo.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'Tahsilat Bilgileri',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _aciklamaController,
                      decoration: InputDecoration(
                        labelText: 'Açıklama *',
                        prefixIcon: Icon(Icons.notes),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: 'Örn: Mutfak dolabı montajı',
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Açıklama gerekli';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _tutarController,
                      decoration: InputDecoration(
                        labelText: 'Toplam Tutar (₺) *',
                        prefixIcon: Icon(Icons.payments),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: '0',
                        suffixText: '₺',
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Tutar gerekli';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Geçerli bir tutar girin';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Tutar 0\'dan büyük olmalı';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Güncelle Butonu
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _tahsilatGuncelle,
                icon: const Icon(Icons.save),
                label: const Text(
                  'Değişiklikleri Kaydet',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}