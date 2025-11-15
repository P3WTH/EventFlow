import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'detalhes_de_eventos.dart';
import 'app_drawer.dart';



class EventoParaMapa {
  final int id;
  final String nome;
  final String data;
  final double preco;
  final String localizacaoNome;

  EventoParaMapa({
    required this.id,
    required this.nome,
    required this.data,
    required this.preco,
    required this.localizacaoNome,
  });

  factory EventoParaMapa.fromJson(Map<String, dynamic> json) {
    return EventoParaMapa(
      id: json['id'],
      nome: json['nome'],
      data: json['data'],
      preco: (json['preco'] as num).toDouble(),
      localizacaoNome: json['localizacao_nome'] ?? 'Local não definido',
    );
  }
}

class LocalParaMapa {
  final String nome;
  final double latitude;
  final double longitude;

  LocalParaMapa({
    required this.nome,
    required this.latitude,
    required this.longitude,
  });

  factory LocalParaMapa.fromJson(Map<String, dynamic> json) {
    return LocalParaMapa(
      nome: json['nome'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}



class FullMapScreen extends StatefulWidget {
  const FullMapScreen({Key? key}) : super(key: key);

  @override
  _FullMapScreenState createState() => _FullMapScreenState();
}

class _FullMapScreenState extends State<FullMapScreen> {
  late Future<Map<String, dynamic>> _dataFuture;
  Set<Marker> _markers = {};


  final CameraPosition _initialCamera = CameraPosition(
    target: LatLng(-23.550520, -46.633308),
    zoom: 11,
  );

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchEventAndLocalData();
  }

  String getApiUrl(String endpoint) {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/$endpoint';
    } else {
      return 'http://127.0.0.1:5000/$endpoint';
    }
  }

  Future<Map<String, dynamic>> _fetchEventAndLocalData() async {
    try {
      final [eventResponse, localResponse] = await Future.wait([
        http.get(Uri.parse(getApiUrl('eventos'))),
        http.get(Uri.parse(getApiUrl('locais'))),
      ]);

      if (eventResponse.statusCode == 200 && localResponse.statusCode == 200) {
        final List<dynamic> jsonEventos =
        json.decode(utf8.decode(eventResponse.bodyBytes));
        final List<dynamic> jsonLocais =
        json.decode(utf8.decode(localResponse.bodyBytes));

        final List<EventoParaMapa> eventos =
        jsonEventos.map((json) => EventoParaMapa.fromJson(json)).toList();
        final List<LocalParaMapa> locais =
        jsonLocais.map((json) => LocalParaMapa.fromJson(json)).toList();

        _createMarkers(eventos, locais);
        return {'eventos': eventos, 'locais': locais};
      } else {
        throw Exception('Falha ao carregar dados da API');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  void _createMarkers(List<EventoParaMapa> eventos, List<LocalParaMapa> locais) {
    final Map<String, LocalParaMapa> localMap = {
      for (var local in locais) local.nome: local
    };

    Set<Marker> markers = {};

    for (var evento in eventos) {
      final LocalParaMapa? localDoEvento = localMap[evento.localizacaoNome];

      if (localDoEvento != null) {
        markers.add(
          Marker(
            markerId: MarkerId(evento.id.toString()),
            position: LatLng(localDoEvento.latitude, localDoEvento.longitude),
            infoWindow: InfoWindow(
              title: evento.nome,
              snippet: 'Data: ${evento.data} - R\$ ${evento.preco.toStringAsFixed(2)}',
              onTap: () {
                _navigateToDetail(evento.id);
              },
            ),
          ),
        );
      }
    }
    setState(() {
      _markers = markers;
    });
  }

  void _navigateToDetail(int eventoId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(eventoId: eventoId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Mapa de Eventos",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black54),
      ),
      endDrawer: const AppDrawer(),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Erro ao carregar dados: ${snapshot.error}"));
          } else if (snapshot.hasData) {
            return GoogleMap(
              initialCameraPosition: _initialCamera,
              markers: _markers,
            );
          } else {
            return Center(child: Text("Nenhum dado encontrado"));
          }
        },
      ),
    );
  }
}