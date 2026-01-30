import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../data/entity/personel.dart';
import '../cubit/personel_cubit.dart';

class PersonelDuzenleSayfa extends StatefulWidget {
  final Personel personel;

  const PersonelDuzenleSayfa({super.key, required this.personel});

  @override
  State<PersonelDuzenleSayfa> createState() => _PersonelDuzenleSayfaState();
}

class _PersonelDuzenleSayfaState extends State<PersonelDuzenleSayfa> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _adSoyadController;
  late TextEditingController _telefonController;
  late TextEditingController _emailController;
  late TextEditingController _pozisyonController;
  late TextEditingController _maasController;

  late DateTime secilenTarih;
  late bool aktifDurum;

  @override
  void initState() {
    super.initState();

    // Mevcut değerleri doldur
    _adSoyadController = TextEditingController(text: widget.personel.adSoyad);
    _telefonController = TextEditingController(text: widget.personel.telefon);
    _emailController = TextEditingController(text: widget.personel.email);
    _pozisyonController = TextEditingController(text: widget.personel.pozisyon);
    _maasController = TextEditingController(
      text: widget.personel.maas > 0 ? widget.personel.maas.toString() : '',
    );

    secilenTarih = widget.personel.baslangicTarihi;
    aktifDurum = widget.personel.aktif;
  }

  @override
  void dispose() {
    _adSoyadController.dispose();
    _telefonController.dispose();
    _emailController.dispose();
    _pozisyonController.dispose();
    _maasController.dispose();
    super.dispose();
  }

  Future<void> _tarihSec() async {
    final DateTime? secilen = await showDatePicker(
      context: context,
      initialDate: secilenTarih,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.indigo,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (secilen != null) {
      setState(() {
        secilenTarih = secilen;
      });
    }
  }

  void _kaydet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Güncellenmiş personel oluştur
    final guncelPersonel = Personel(
      id: widget.personel.id,
      adSoyad: _adSoyadController.text.trim(),
      telefon: _telefonController.text.trim(),
      email: _emailController.text.trim(),
      pozisyon: _pozisyonController.text.trim(),
      maas: _maasController.text.isNotEmpty
          ? double.parse(_maasController.text)
          : 0,
      baslangicTarihi: secilenTarih,
      aktif: aktifDurum,
    );

    // Güncelle
    await context.read<PersonelCubit>().personelGuncelle(guncelPersonel);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${guncelPersonel.adSoyad} güncellendi!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, guncelPersonel); // Güncel personeli geri döndür
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personel Düzenle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _kaydet,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Avatar
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.indigo.shade100,
                child: Text(
                  _adSoyadController.text.isNotEmpty
                      ? _adSoyadController.text[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Ad Soyad
            TextFormField(
              controller: _adSoyadController,
              decoration: InputDecoration(
                labelText: 'Ad Soyad *',
                hintText: 'Örn: Ahmet Yılmaz',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {}); // Avatar'ı güncelle
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ad Soyad boş olamaz';
                }
                if (value.trim().length < 3) {
                  return 'Ad Soyad en az 3 karakter olmalı';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Telefon
            TextFormField(
              controller: _telefonController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Telefon *',
                hintText: '05XX XXX XX XX',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Telefon boş olamaz';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'E-posta',
                hintText: 'ornek@email.com',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!value.contains('@')) {
                    return 'Geçerli bir e-posta adresi girin';
                  }
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Pozisyon
            TextFormField(
              controller: _pozisyonController,
              decoration: InputDecoration(
                labelText: 'Pozisyon *',
                hintText: 'Örn: Usta, Kalfa, İşçi',
                prefixIcon: const Icon(Icons.work),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Pozisyon boş olamaz';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Maaş
            TextFormField(
              controller: _maasController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Maaş (₺)',
                hintText: 'Opsiyonel',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final maas = double.tryParse(value);
                  if (maas == null || maas < 0) {
                    return 'Geçerli bir maaş girin';
                  }
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Başlangıç Tarihi
            InkWell(
              onTap: _tarihSec,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'İşe Başlama Tarihi',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  DateFormat('dd MMMM yyyy', 'tr_TR').format(secilenTarih),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Aktif Durumu
            Card(
              child: SwitchListTile(
                value: aktifDurum,
                onChanged: (value) {
                  setState(() {
                    aktifDurum = value;
                  });
                },
                title: const Text(
                  'Aktif Durum',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  aktifDurum ? 'Personel aktif' : 'Personel pasif',
                  style: TextStyle(
                    color: aktifDurum ? Colors.green : Colors.red,
                  ),
                ),
                secondary: Icon(
                  aktifDurum ? Icons.check_circle : Icons.cancel,
                  color: aktifDurum ? Colors.green : Colors.red,
                ),
                activeColor: Colors.green,
              ),
            ),

            const SizedBox(height: 24),

            // Kaydet Butonu
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _kaydet,
                icon: const Icon(Icons.save, color: Colors.white,),
                label: const Text(
                  'Değişiklikleri Kaydet',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
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