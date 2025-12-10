import 'package:flutter/material.dart';

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String userName;
  final VoidCallback onMenuPressed;

  const DashboardAppBar({
    Key? key,
    required this.title,
    required this.userName,
    required this.onMenuPressed,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 20);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Colors.white),
          ),
          Text(
            'Bonjour, $userName',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal,color:  Colors.white),
          ),
        ],
      ),
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: onMenuPressed,
      ),
      actions: [
        IconButton(icon: const Icon(Icons.notifications), onPressed: () {},
          color: Colors.white,
        ),
        IconButton(icon: const Icon(Icons.person), onPressed: () {},
          color: Colors.white,
        ),
      ],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade500, Colors.indigo.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }
}
