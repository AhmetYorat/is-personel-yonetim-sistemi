import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personel_takip/ui/views/dashboard_sayfa.dart';
import 'package:personel_takip/ui/views/isler_sayfa.dart';
import 'package:personel_takip/ui/views/personeller_sayfa.dart';
import 'package:personel_takip/ui/views/tahsilatlar_sayfa.dart';
import '../cubit/auth_cubit.dart';

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        // ✅ Kullanıcı rolünü al
        bool isAdmin = false;
        if (authState is AuthAuthenticated) {
          isAdmin = authState.kullanici.rol == 'admin';
        }

        // ✅ Sayfa listesi - role göre
        final List<Widget> _sayfalar = isAdmin
            ? [
          DashboardSayfa(), // 0 - Ana Sayfa
          PersonellerSayfa(), // 1 - Sadece admin
          IslerSayfa(), // 2
          TahsilatlarSayfa(),
        ]
            : [
          DashboardSayfa(), // 0 - Ana Sayfa
          IslerSayfa(), // 1 - Personel için işler
        ];

        // ✅ BottomNavigationBar items - role göre
        final List<BottomNavigationBarItem> _navItems = isAdmin
            ? const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Personeller',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'İşler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments),
            label: 'Tahsilatlar',
          ),
        ]
            : const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'İşlerim',
          ),
        ];

        return Scaffold(
          body: _sayfalar[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            items: _navItems,
            selectedItemColor: Colors.indigo.shade700,
          ),
        );
      },
    );
  }
}