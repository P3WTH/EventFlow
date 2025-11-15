import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'create_local_screen.dart';
import 'app_drawer.dart';
import 'edit_local_screen.dart';

class Local {
  final int id;
  final String nome;
  final String endereco;
  final double latitude;
  final double longitude;

  Local({
    required this.id,
    required this.nome,
    required this.endereco,
    required this.latitude,
    required this.longitude,
  });

  factory Local.fromJson(Map<String, dynamic> json) {
    return Local(
      id: json['id'],
      nome: json['nome'],
      endereco: json['endereco'] ?? 'Endereço não informado',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}

class LocalListScreen extends StatefulWidget {
  const LocalListScreen({Key? key}) : super(key: key);

  @override
  _LocalListScreenState createState() => _LocalListScreenState();
}

class _LocalListScreenState extends State<LocalListScreen> {
  late Future<List<Local>> futureLocais;

  String getApiUrl(String endpoint) {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/$endpoint';
    } else {
      return 'http://127.0.0.1:5000/$endpoint';
    }
  }

  Future<List<Local>> fetchLocais() async {
    final String apiUrl = getApiUrl('locais');
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        List<dynamic> jsonResponse =
        json.decode(utf8.decode(response.bodyBytes));
        return jsonResponse.map((json) => Local.fromJson(json)).toList();
      } else {
        throw Exception(
            'Falha ao carregar locais (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    futureLocais = fetchLocais();
  }

  Future<void> _deleteLocal(int localId) async {
    final String apiUrl = getApiUrl('locais/$localId');
    try {
      final response = await http.delete(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Local deletado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          futureLocais = fetchLocais();
        });
      } else {
        throw Exception('Falha ao deletar local');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  Future<void> _openMap(double latitude, double longitude) async {
    final String googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    final Uri uri = Uri.parse(googleMapsUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível abrir o mapa'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  final Color primaryBlue = Color(0xFF0D47A1);
  final Color lightGray = Color(0xFFEEEEEE);
  final Color yellowButton = Color(0xFFFFC107);
  final Color redButton = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          "Logo",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu, color: Colors.black54),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              "Listagem de Locais",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: "Pesquise Locais...",
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: lightGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final bool? foiCriado = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateLocalScreen()),
                );

                if (foiCriado == true) {
                  setState(() {
                    futureLocais = fetchLocais();
                  });
                }
              },
              icon: Icon(Icons.add, color: Colors.white),
              label: Text("Criar Local +"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                textStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: FutureBuilder<List<Local>>(
                future: futureLocais,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Erro ao carregar locais.\n${snapshot.error}",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.red),
                      ),
                    );
                  } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    final locais = snapshot.data!;
                    return ListView.builder(
                      itemCount: locais.length,
                      itemBuilder: (context, index) {
                        return _buildLocalCard(context, locais[index]);
                      },
                    );
                  } else {
                    return Center(
                      child: Text(
                        "Nenhum local cadastrado",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      endDrawer: const AppDrawer(),
    );
  }

  Widget _buildLocalCard(BuildContext context, Local local) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 120,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(local.latitude, local.longitude),
                      zoom: 15,
                    ),
                    markers: {
                      Marker(
                        markerId: MarkerId(local.id.toString()),
                        position: LatLng(local.latitude, local.longitude),
                      ),
                    },
                    liteModeEnabled: true,
                    zoomControlsEnabled: false,
                    scrollGesturesEnabled: false,
                    zoomGesturesEnabled: false,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext dialogContext) {
                        return AlertDialog(
                          title: Text('Confirmar Exclusão'),
                          content: Text(
                              'Você tem certeza que deseja excluir o local "${local.nome}"?'),
                          actions: <Widget>[
                            TextButton(
                              child: Text('Cancelar'),
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                              },
                            ),
                            TextButton(
                              child: Text('Excluir',
                                  style: TextStyle(color: Colors.red)),
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                _deleteLocal(local.id);
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                  icon: Icon(Icons.close, size: 16),
                  label: Text("Excluir Local"),
                  style: TextButton.styleFrom(
                    backgroundColor: redButton.withOpacity(0.8),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    textStyle: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  local.nome,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  local.endereco,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final bool? foiAtualizado = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditLocalScreen(local: local),
                          ),
                        );

                        if (foiAtualizado == true) {
                          setState(() {
                            futureLocais = fetchLocais();
                          });
                        }
                      },
                      child: Text("Editar"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: yellowButton,
                        foregroundColor: Colors.black87,
                      ),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton(

                      onPressed: () {
                        _openMap(local.latitude, local.longitude);
                      },
                      child: Text("Ver"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}