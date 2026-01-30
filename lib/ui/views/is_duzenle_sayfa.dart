import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:personel_takip/data/entity/tahsilat.dart';
import 'package:personel_takip/data/repo/tahsilat_repository.dart';
import 'package:personel_takip/ui/cubit/tahsilat_cubit.dart';
import '../../data/entity/is.dart';
import '../../data/entity/personel.dart';
import '../cubit/is_cubit.dart';
import '../cubit/personel_cubit.dart';

class IsDuzenleSayfa extends StatefulWidget {
  final Is is_;

  const IsDuzenleSayfa({super.key, required this.is_});

  @override
  State<IsDuzenleSayfa> createState() => _IsDuzenleSayfaState();
}

class _IsDuzenleSayfaState extends State<IsDuzenleSayfa> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _baslikController;
  late TextEditingController _aciklamaController;
  late TextEditingController _musteriAdiController;
  late TextEditingController _adresController;
  late TextEditingController _maliyetController;

  late String secilenDurum;
  late DateTime secilenTarih;
  late List<String> secilenPersonelIdler;

  final List<String> durumlar = [
    'Beklemede',
    'Devam Ediyor',
    'Tamamlandı',
    'İptal'
  ];

  @override
  void initState() {
    super.initState();

    // Mevcut değerleri doldur
    _baslikController = TextEditingController(text: widget.is_.baslik);
    _aciklamaController = TextEditingController(text: widget.is_.aciklama);
    _musteriAdiController = TextEditingController(text: widget.is_.musteriAdi);
    _adresController = TextEditingController(text: widget.is_.adres);
    _maliyetController = TextEditingController(
      text: widget.is_.maliyet != null ? widget.is_.maliyet.toString() : '',
    );

    secilenDurum = widget.is_.durum;
    secilenTarih = widget.is_.baslangicTarihi;
    secilenPersonelIdler = List.from(widget.is_.atananPersonelIdler);

    // Personelleri yükle
    context.read<PersonelCubit>().personelleriYukle();
  }

  @override
  void dispose() {
    _baslikController.dispose();
    _aciklamaController.dispose();
    _adresController.dispose();
    _musteriAdiController.dispose();
    _maliyetController.dispose();
    super.dispose();
  }

  Future<void> _tarihSec() async {
    final DateTime? secilen = await showDatePicker(
      context: context,
      initialDate: secilenTarih,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
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

  void _personelSec() {
    List<String> tempSecilenler = List.from(secilenPersonelIdler);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (BuildContext stateContext, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    // Başlık
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
                          const Icon(Icons.people, color: Colors.indigo),
                          const SizedBox(width: 8),
                          const Text(
                            'Personel Seç',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.indigo,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${tempSecilenler.length} seçili',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Personel listesi
                    Expanded(
                      child: BlocBuilder<PersonelCubit, List<Personel>>(
                        builder: (context, personeller) {
                          if (personeller.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Personel bulunamadı',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: personeller.length,
                            itemBuilder: (context, index) {
                              final personel = personeller[index];
                              final secili = tempSecilenler.contains(personel.id);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: secili ? 3 : 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: secili
                                        ? Colors.indigo
                                        : Colors.grey.shade300,
                                    width: secili ? 2 : 1,
                                  ),
                                ),
                                child: CheckboxListTile(
                                  value: secili,
                                  onChanged: (bool? value) {
                                    setModalState(() {
                                      if (value == true) {
                                        if (!tempSecilenler.contains(personel.id)) {
                                          tempSecilenler.add(personel.id);
                                        }
                                      } else {
                                        tempSecilenler.remove(personel.id);
                                      }
                                    });
                                  },
                                  title: Text(
                                    personel.adSoyad,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      personel.pozisyon,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                  secondary: CircleAvatar(
                                    backgroundColor: secili
                                        ? Colors.indigo
                                        : Colors.grey.shade300,
                                    child: Text(
                                      personel.adSoyad[0].toUpperCase(),
                                      style: TextStyle(
                                        color: secili
                                            ? Colors.white
                                            : Colors.grey.shade700,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  activeColor: Colors.indigo,
                                  controlAffinity: ListTileControlAffinity.trailing,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),

                    // Alt butonlar
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade300,
                            blurRadius: 10,
                            offset: const Offset(0, -3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(
                                  color: Colors.grey.shade400,
                                  width: 2,
                                ),
                              ),
                              child: const Text(
                                'İptal',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  secilenPersonelIdler = List.from(tempSecilenler);
                                });
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check, size: 20, color: Colors.white,),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tamam (${tempSecilenler.length})',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _kaydet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (secilenPersonelIdler.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('En az bir personel seçmelisiniz!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final eskiMaliyet = widget.is_.maliyet;
    final yeniMaliyet = _maliyetController.text.isNotEmpty
        ? double.tryParse(_maliyetController.text)
        : null;

    // Güncellenmiş iş oluştur
    final guncelIs = Is(
      id: widget.is_.id,
      baslik: _baslikController.text.trim(),
      aciklama: _aciklamaController.text.trim(),
      musteriAdi: _musteriAdiController.text.trim(),
      adres: _adresController.text.trim(),
      durum: secilenDurum,
      baslangicTarihi: secilenTarih,
      bitisTarihi: widget.is_.bitisTarihi,
      atananPersonelIdler: secilenPersonelIdler,
      maliyet: yeniMaliyet,
      aktif: widget.is_.aktif,
    );

    // Güncelle
    await context.read<IsCubit>().isGuncelle(guncelIs);

    // ✅ Tahsilat kontrolü ve güncelleme
    final tahsilatRepo = TahsilatRepository();
    final mevcutTahsilat = await tahsilatRepo.iseTahsilatGetir(widget.is_.id);

    if (yeniMaliyet != null && yeniMaliyet > 0) {
      if (mevcutTahsilat != null) {
        // Mevcut tahsilat var, güncelle
        mevcutTahsilat.musteriAdi = guncelIs.musteriAdi;
        mevcutTahsilat.aciklama = '${guncelIs.baslik} - Otomatik tahsilat';
        mevcutTahsilat.toplamTutar = yeniMaliyet;

        // Durum kontrolü
        if (mevcutTahsilat.odenenTutar >= yeniMaliyet) {
          mevcutTahsilat.durum = 'tamamlandi';
        } else if (mevcutTahsilat.odenenTutar > 0) {
          mevcutTahsilat.durum = 'kismen';
        } else {
          mevcutTahsilat.durum = 'bekliyor';
        }

        await context.read<TahsilatCubit>().tahsilatGuncelle(mevcutTahsilat);
      } else if (eskiMaliyet == null) {
        // Eskiden maliyet yoktu, şimdi var - yeni tahsilat oluştur
        final yeniTahsilat = Tahsilat(
          id: '',
          isId: widget.is_.id,
          musteriAdi: guncelIs.musteriAdi,
          aciklama: '${guncelIs.baslik} - Otomatik tahsilat',
          toplamTutar: yeniMaliyet,
          durum: 'bekliyor',
          olusturulmaTarihi: DateTime.now(),
          odemeler: [],
        );
        await context.read<TahsilatCubit>().tahsilatEkle(yeniTahsilat);
      }
    } else if (mevcutTahsilat != null && mevcutTahsilat.odenenTutar == 0) {
      // Maliyet silindi ve hiç ödeme yapılmadıysa tahsilatı sil
      await context.read<TahsilatCubit>().tahsilatSil(mevcutTahsilat.id);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ "${guncelIs.baslik}" güncellendi!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, guncelIs);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İş Düzenle'),
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
            // Başlık
            TextFormField(
              controller: _baslikController,
              decoration: InputDecoration(
                labelText: 'İş Başlığı *',
                hintText: 'Örn: Villa Güvenlik Sistemi',
                prefixIcon: const Icon(Icons.title),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Başlık boş olamaz';
                }
                if (value.trim().length < 3) {
                  return 'Başlık en az 3 karakter olmalı';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _musteriAdiController,
              decoration: InputDecoration(
                labelText: 'Müşteri Adı *',
                hintText: 'Örn: Ahmet Yılmaz',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Müşteri adı boş olamaz';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Açıklama
            TextFormField(
              controller: _aciklamaController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Açıklama *',
                hintText: 'İş detaylarını yazın...',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Açıklama boş olamaz';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Adres
            TextFormField(
              controller: _adresController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Adres *',
                hintText: 'İş adresi',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Adres boş olamaz';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Durum
            DropdownButtonFormField<String>(
              value: secilenDurum,
              decoration: InputDecoration(
                labelText: 'Durum',
                prefixIcon: Icon(
                  Is.getDurumIcon(secilenDurum),
                  color: Is.getDurumColor(secilenDurum),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: durumlar.map((durum) {
                return DropdownMenuItem(
                  value: durum,
                  child: Row(
                    children: [
                      Icon(
                        Is.getDurumIcon(durum),
                        size: 20,
                        color: Is.getDurumColor(durum),
                      ),
                      const SizedBox(width: 8),
                      Text(durum),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  secilenDurum = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            // Başlangıç Tarihi
            InkWell(
              onTap: _tarihSec,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Başlangıç Tarihi',
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

            // Personel Seçimi
            InkWell(
              onTap: _personelSec,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Atanan Personel *',
                  prefixIcon: const Icon(Icons.people),
                  suffixIcon: const Icon(Icons.arrow_forward_ios, size: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  secilenPersonelIdler.isEmpty
                      ? 'Personel seçin'
                      : '${secilenPersonelIdler.length} personel seçildi',
                  style: TextStyle(
                    fontSize: 16,
                    color: secilenPersonelIdler.isEmpty
                        ? Colors.grey.shade600
                        : Colors.black,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Maliyet
            TextFormField(
              controller: _maliyetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Alınacak Para (₺)',
                hintText: 'Opsiyonel',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final maliyet = double.tryParse(value);
                  if (maliyet == null || maliyet < 0) {
                    return 'Geçerli bir tutar girin';
                  }
                }
                return null;
              },
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