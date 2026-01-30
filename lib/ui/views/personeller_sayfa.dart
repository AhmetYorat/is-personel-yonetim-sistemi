import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personel_takip/data/entity/personel.dart';
import 'package:personel_takip/ui/cubit/personel_cubit.dart';
import 'package:personel_takip/ui/views/personel_detay_sayfa.dart';

class PersonellerSayfa extends StatefulWidget {
  const PersonellerSayfa({super.key});

  @override
  State<PersonellerSayfa> createState() => _PersonellerSayfaState();
}

class _PersonellerSayfaState extends State<PersonellerSayfa> {
  @override
  void initState() {
    super.initState();
    context.read<PersonelCubit>().personelleriYukle();
  }
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personeller'),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<PersonelCubit, List<Personel>>(
          builder: (context, personelListesi){
            if(personelListesi.isEmpty){
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 100, color: Colors.grey,),
                    SizedBox(height: 16,),
                    Text("Henüz Personel Eklenmemiş", style: TextStyle(fontSize: 18, color: Colors.grey),)
                  ],
                ),
              );
            } //if

            return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: personelListesi.length,
                itemBuilder: (context, index){
                  var personel = personelListesi[index];
                  return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.indigo.shade700,
                        child: Text(
                          personel.adSoyad[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        personel.adSoyad,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('📞 ${personel.telefon}'),
                            const SizedBox(height: 2),
                            Text('💼 ${personel.pozisyon}'),
                          ],
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16,),
                      onTap: (){
                        Navigator.push(context, MaterialPageRoute(builder: (context) => PersonelDetaySayfa(personel: personel)));
                      },
                    )
                  );
                }
            );
          }
      ),
    );
  }
}

void _personelEkleDialog(BuildContext context){
  final formKey = GlobalKey<FormState>();
  String adSoyad = '';
  String telefon = '';
  String email = '';
  String pozisyon = 'Usta';

  showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Personel Ekle"),
        content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Ad Soyad *'),
                    validator: (value){
                      if(value == null ||value.isEmpty){
                        return 'Ad soyad gerekli';
                      }
                      return null;
                    },
                    onSaved: (value) => adSoyad = value!,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Telefon *'),
                    keyboardType: TextInputType.phone,
                    validator: (value){
                      if(value == null ||value.isEmpty){
                        return 'Telefon gerekli';
                      }
                      return null;
                    },
                    onSaved: (value) => telefon = value!,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'E-posta'),
                    keyboardType: TextInputType.emailAddress,
                    onSaved: (value) => email = value!,
                  ),
                  DropdownButtonFormField<String>(
                      initialValue: pozisyon,
                      decoration: const InputDecoration(labelText: 'Pozisyon'),
                      items: ['Patron', 'Usta', 'Çırak', 'Stajyer', 'Diğer']
                          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (value) => pozisyon = value!,
                  ),
                ],
              ),
            )
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('İptal')
          ),
          ElevatedButton(
              onPressed: (){
                if(formKey.currentState!.validate()){
                  formKey.currentState!.save();

                  Personel yeniPersonel = Personel(
                      id: '',
                      adSoyad: adSoyad,
                      telefon: telefon,
                      pozisyon: pozisyon,
                      baslangicTarihi: DateTime.now(),
                  );

                  context.read<PersonelCubit>().personelEkle(yeniPersonel);
                  Navigator.pop(dialogContext);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${adSoyad} eklendi"),backgroundColor: Colors.green,)
                  );
                }
              },
              child: Text("Ekle"))
        ],
      )
  );
}
