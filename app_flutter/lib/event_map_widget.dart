import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'full_map_screen.dart';

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

class EventMapWidget extends StatefulWidget {
  const EventMapWidget({Key? key}) : super(key: key);

  @override
  _EventMapWidgetState createState() => _EventMapWidgetState();
}

class _EventMapWidgetState extends State<EventMapWidget> {
  late Future<List<Local>> futureLocais;

  String getApiUrl() {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/locais';
    } else {
      return 'http://127.0.0.1:5000/locais';
    }
  }

  Future<List<Local>> fetchLocais() async {
    final String apiUrl = getApiUrl();
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        List<dynamic> jsonResponse =
        json.decode(utf8.decode(response.bodyBytes));
        return jsonResponse.map((json) => Local.fromJson(json)).toList();
      } else {
        throw Exception('Falha ao carregar locais');
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

  Set<Marker> _createMarkers(List<Local> locais) {
    return locais.map((local) {
      return Marker(
        markerId: MarkerId(local.id.toString()),
        position: LatLng(local.latitude, local.longitude),
        infoWindow: InfoWindow(
          title: local.nome,
        ),
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FullMapScreen()),
        );
      },
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: FutureBuilder<List<Local>>(
          future: futureLocais,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Erro ao carregar mapa"));
            } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final locais = snapshot.data!;
              return ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(locais.first.latitude, locais.first.longitude),
                    zoom: 12,
                  ),
                  markers: _createMarkers(locais),
                  zoomControlsEnabled: false,
                  scrollGesturesEnabled: false,
                  liteModeEnabled: true,
                ),
              );
            } else {
              return Center(child: Text("Nenhum local para exibir no mapa"));
            }
          },
        ),
      ),
    );
  }
}