import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_list_screen.dart';
import 'main.dart';
import 'login_screen.dart';
import 'category_list_screen.dart';
import 'profile_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  final Color primaryBlue = const Color(0xFF0D47A1);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          _buildDrawerHeader(),
          _buildListTile(
            context: context,
            icon: Icons.event_note,
            title: 'Eventos',
            targetScreen: const EventListScreen(),
          ),
          _buildListTile(
            context: context,
            icon: Icons.location_on,
            title: 'Locais',
            targetScreen: const LocalListScreen(),
          ),
          _buildListTile(
            context: context,
            icon: Icons.category,
            title: 'Categorias',
            targetScreen: const CategoryListScreen(),
          ),
          _buildListTile(
            context: context,
            icon: Icons.account_circle,
            title: 'Minha Conta',
            targetScreen: const ProfileScreen(),
          ),
          _buildListTile(
            context: context,
            icon: Icons.description,
            title: 'Termos de Uso',
            targetScreen: null,
          ),
          _buildListTile(
            context: context,
            icon: Icons.notifications,
            title: 'Notificações',
            targetScreen: null,
          ),
          Divider(color: Colors.grey[300]),
          ListTile(
            leading: Icon(Icons.exit_to_app, color: Colors.red[700]),
            title: Text(
              'Sair',
              style: TextStyle(color: Colors.red[700], fontSize: 16),
            ),
            onTap: () async {


              final SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.remove('user_token');
              // --- FIM DA LÓGICA ---

              if (!Navigator.of(context).mounted) return;
              Navigator.of(context).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return UserAccountsDrawerHeader(
      accountName: Text(
        "Yara de Oliveira Matos",
        style: TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      accountEmail: Text(
        "yara@email.com",
        style: TextStyle(color: Colors.black54),
      ),
      currentAccountPicture: CircleAvatar(
        backgroundImage: NetworkImage(
            "https://i.imgur.com/9783fR7.png"),
        backgroundColor: Colors.grey[300],
      ),
      decoration: BoxDecoration(
        color: Colors.white,
      ),
    );
  }

  Widget _buildListTile(
      {required BuildContext context,
        required IconData icon,
        required String title,
        required Widget? targetScreen}) {
    return ListTile(
      leading: Icon(icon, color: primaryBlue),
      title: Text(title, style: TextStyle(fontSize: 16)),
      onTap: () {
        Navigator.of(context).pop();
        if (targetScreen != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => targetScreen),
          );
        }
      },
    );
  }
}