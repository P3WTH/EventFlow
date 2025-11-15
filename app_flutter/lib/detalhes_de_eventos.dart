import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'edit_event_screen.dart';

class EventoDetalhe {
  final int id;
  final String nome;
  final String data;
  final double preco;
  final String categoria;
  final String miniaturaUrl;
  final String descricaoLonga;
  final String localizacaoNome;
  final double latitude;
  final double longitude;
  final String endereco;
  final String bairro;
  final String cidade;

  EventoDetalhe({
    required this.id,
    required this.nome,
    required this.data,
    required this.preco,
    required this.categoria,
    required this.miniaturaUrl,
    required this.descricaoLonga,
    required this.localizacaoNome,
    required this.latitude,
    required this.longitude,
    required this.endereco,
    required this.bairro,
    required this.cidade,
  });

  factory EventoDetalhe.fromJson(Map<String, dynamic> json) {
    return EventoDetalhe(
      id: json['id'],
      nome: json['nome'],
      data: json['data'],
      preco: (json['preco'] as num).toDouble(),
      categoria: json['categoria'],
      miniaturaUrl: json['miniatura_url'],
      descricaoLonga: json['descricao_longa'],
      localizacaoNome: json['localizacao_nome'] ?? 'Local não informado',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      endereco: json['endereco'] ?? 'Endereço não informado',
      bairro: json['bairro'] ?? 'Bairro não informado',
      cidade: json['cidade'] ?? 'Cidade não informada',
    );
  }
}

class EventDetailScreen extends StatefulWidget {
  final int eventoId;

  const EventDetailScreen({Key? key, required this.eventoId}) : super(key: key);

  @override
  _EventDetailScreenState createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late Future<EventoDetalhe> futureEventoDetalhe;

  @override
  void initState() {
    super.initState();
    futureEventoDetalhe = fetchEventoDetalhe();
  }

  String getApiUrl(int id) {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/eventos/$id';
    } else {
      return 'http://127.0.0.1:5000/eventos/$id';
    }
  }

  Future<EventoDetalhe> fetchEventoDetalhe() async {
    final String apiUrl = getApiUrl(widget.eventoId);
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        return EventoDetalhe.fromJson(
            json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception(
            'Falha ao carregar detalhes do evento (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  final Color primaryBlue = Color(0xFF0D47A1);
  final Color lightGray = Color(0xFFEEEEEE);

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
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
        ),
        actions: [
          FutureBuilder<EventoDetalhe>(
            future: futureEventoDetalhe,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final evento = snapshot.data!;
                return IconButton(
                  icon: Icon(Icons.edit, color: Colors.black54),
                  onPressed: () async {
                    final bool? foiAtualizado = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditEventScreen(evento: evento),
                      ),
                    );
                    if (foiAtualizado == true) {
                      setState(() {
                        futureEventoDetalhe = fetchEventoDetalhe();
                      });
                    }
                  },
                );
              }
              return Container();
            },
          ),
          IconButton(
            icon: Icon(Icons.menu, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: FutureBuilder<EventoDetalhe>(
        future: futureEventoDetalhe,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "Erro ao carregar evento.\n${snapshot.error}",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
            );
          } else if (snapshot.hasData) {
            final evento = snapshot.data!;
            return _buildEventDetails(context, evento);
          } else {
            return Center(child: Text("Evento não encontrado."));
          }
        },
      ),
    );
  }

  Widget _buildEventDetails(BuildContext context, EventoDetalhe evento) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: lightGray,
                foregroundColor: Colors.black54,
                elevation: 0,
              ),
              child: Text("Voltar"),
            ),
          ),


          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(evento.miniaturaUrl),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) => Icon(
                  Icons.image_not_supported,
                  color: Colors.grey,
                  size: 50,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        evento.nome,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                    ),
                    Text(
                      evento.data,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  evento.categoria,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                SizedBox(height: 16),
                Text(
                  evento.descricaoLonga,
                  style:
                  TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                ),
                Divider(height: 40, thickness: 1, color: lightGray),
                Text(
                  "Informações do Evento",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: primaryBlue, size: 20),
                        SizedBox(width: 8),
                        Text("Data: ${evento.data}",
                            style: TextStyle(fontSize: 16)),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text("Horário: 08:00h - 12:30h",
                            style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Valor Ingresso",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      Text("R\$ ${evento.preco.toStringAsFixed(2)}",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Divider(height: 40, thickness: 1, color: lightGray),
                Text(
                  "Localização",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),


                Container(
                  height: 150,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(evento.latitude, evento.longitude),
                        zoom: 15,
                      ),
                      markers: {
                        Marker(
                          markerId: MarkerId(evento.id.toString()),
                          position: LatLng(evento.latitude, evento.longitude),
                        ),
                      },
                      liteModeEnabled: true,
                      zoomControlsEnabled: false,
                      scrollGesturesEnabled: false,
                      zoomGesturesEnabled: false,
                    ),
                  ),
                ),

                SizedBox(height: 16),
                Text("Endereço: ${evento.endereco}",
                    style: TextStyle(fontSize: 16)),
                Text("Bairro: ${evento.bairro}, ${evento.cidade}",
                    style: TextStyle(fontSize: 16)),
                Text("Ponto de Referência: Próximo ao Lago da Lua",
                    style: TextStyle(fontSize: 16)),
              ],
            ),
          )
        ],
      ),
    );
  }
}