import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/entity/tahsilat.dart';
import '../cubit/tahsilat_cubit.dart';

class TahsilatEkleSayfa extends StatefulWidget {
  const TahsilatEkleSayfa({super.key});

  @override
  State<TahsilatEkleSayfa> createState() => _TahsilatEkleSayfaState();
}

class _TahsilatEkleSayfaState extends State<TahsilatEkleSayfa> {
  final _formKey = GlobalKey<FormState>();

  final _musteriAdiController = TextEditingController();
  final _aciklamaController = TextEditingController();
  final _tutarController = TextEditingController();

  @override
  void dispose() {
    _musteriAdiController.dispose();
    _aciklamaController.dispose();
    _tutarController.dispose();
    super.dispose();
  }

  void _tahsilatKaydet() async {
    if (_formKey.currentState!.validate()) {
      final yeniTahsilat = Tahsilat(
        id: '',
        musteriAdi: _musteriAdiController.text.trim(),
        aciklama: _aciklamaController.text.trim(),
        toplamTutar: double.parse(_tutarController.text.trim()),
        durum: 'bekliyor',
        olusturulmaTarihi: DateTime.now(),
        odemeler: [],
      );

      await context.read<TahsilatCubit>().tahsilatEkle(yeniTahsilat);

      context.read<TahsilatCubit>().tahsilatlariYukle();

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Tahsilat eklendi'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tahsilat Ekle'),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                        hintText: 'Örn: Kamera Sistemi Montajı',
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

            // Kaydet Butonu
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _tahsilatKaydet,
                icon: const Icon(Icons.save),
                label: const Text(
                  'Tahsilat Ekle',
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