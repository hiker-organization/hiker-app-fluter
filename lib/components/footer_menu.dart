import 'package:app_hiker/components/user_avatar.dart';
import 'package:app_hiker/src/utils/pallete.dart';
import 'package:flutter/material.dart';

class FooterMenu extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String? photoUrl;

  const FooterMenu({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: Pallete.backgroundColor,
      selectedItemColor: Pallete.primaryColor,
      unselectedItemColor: Pallete.whiteColor,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Feed'),
        const BottomNavigationBarItem(
          icon: Icon(Icons.terrain),
          label: 'Trilhas',
        ),
        BottomNavigationBarItem(
          icon: _ProfileIcon(photoUrl: photoUrl, isActive: currentIndex == 2),
          label: 'Perfil',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.add_circle),
          label: 'Avaliar',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Pesquisar',
        ),
      ],
    );
  }
}

class _ProfileIcon extends StatelessWidget {
  final String? photoUrl;
  final bool isActive;

  const _ProfileIcon({required this.photoUrl, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 32,
      backgroundColor: isActive ? Pallete.primaryColor : Colors.transparent,
      child: UserAvatar(photoUrl: photoUrl, radius: 30),
    );
  }
}
