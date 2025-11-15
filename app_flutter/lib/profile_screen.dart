import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'app_drawer.dart';

class UserProfile {
  final int id;
  final String nome;
  final String email;

  UserProfile({required this.id, required this.nome, required this.email});

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      nome: json['nome'],
      email: json['email'],
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<UserProfile> futureProfile;

  @override
  void initState() {
    super.initState();
    futureProfile = fetchProfile();
  }

  String getApiUrl(String endpoint) {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/$endpoint';
    } else {
      return 'http://127.0.0.1:5000/$endpoint';
    }
  }

  Future<UserProfile> fetchProfile() async {
    final String apiUrl = getApiUrl('perfil');
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        return UserProfile.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Falha ao carregar perfil');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Minha Conta",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black54),
      ),
      endDrawer: const AppDrawer(),
      body: FutureBuilder<UserProfile>(
        future: futureProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Erro: ${snapshot.error}"));
          } else if (snapshot.hasData) {
            final user = snapshot.data!;
            return _buildProfileView(user);
          } else {
            return Center(child: Text("Nenhum usuário encontrado"));
          }
        },
      ),
    );
  }

  Widget _buildProfileView(UserProfile user) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(
                  "https://i.imgur.com/9783fR7.png"),
              backgroundColor: Colors.grey[200],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Nome:",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          Text(
            user.nome,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Text(
            "E-mail:",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          Text(
            user.email,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              // TODO: Implementar lógica de editar perfil
            },
            child: Text("Editar Perfil"),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
              backgroundColor: Color(0xFF0D47A1),
              foregroundColor: Colors.white,
            ),
          )
        ],
      ),
    );
  }
}