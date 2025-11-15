import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'detalhes_de_eventos.dart';
import 'app_drawer.dart';
import 'create_event_screen.dart';
import 'event_map_widget.dart';
import 'login_screen.dart';

void main() {
  runApp(const EventFlowApp());
}

class EventFlowApp extends StatelessWidget {
  const EventFlowApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EventFlow',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AuthCheckScreen(),
    );
  }
}


class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({Key? key}) : super(key: key);

  @override
  _AuthCheckScreenState createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('user_token');

    if (token != null) {

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const EventListScreen()),
      );
    } else {

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}




class Evento {
  final int id;
  final String nome;
  final String data;
  final double preco;
  final String categoria;
  final String miniaturaUrl;

  Evento({
    required this.id,
    required this.nome,
    required this.data,
    required this.preco,
    required this.categoria,
    required this.miniaturaUrl,
  });

  factory Evento.fromJson(Map<String, dynamic> json) {
    return Evento(
      id: json['id'],
      nome: json['nome'],
      data: json['data'],
      preco: (json['preco'] as num).toDouble(),
      categoria: json['categoria'],
      miniaturaUrl: json['miniatura_url'],
    );
  }
}

class EventListScreen extends StatefulWidget {
  const EventListScreen({Key? key}) : super(key: key);

  @override
  _EventListScreenState createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  late Future<List<Evento>> futureEventos;

  final TextEditingController _searchController = TextEditingController();
  List<Evento> _allEvents = [];
  List<Evento> _filteredEvents = [];

  @override
  void initState() {
    super.initState();
    futureEventos = fetchEventos();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    String searchTerm = _searchController.text.toLowerCase();
    setState(() {
      _filteredEvents = _allEvents.where((evento) {
        final nome = evento.nome.toLowerCase();
        final categoria = evento.categoria.toLowerCase();
        return nome.contains(searchTerm) || categoria.contains(searchTerm);
      }).toList();
    });
  }

  String getApiUrl(String endpoint) {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/$endpoint';
    } else {
      return 'http://127.0.0.1:5000/$endpoint';
    }
  }

  Future<List<Evento>> fetchEventos() async {
    final String apiUrl = getApiUrl('eventos');
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        List<dynamic> jsonResponse =
        json.decode(utf8.decode(response.bodyBytes));

        final events = jsonResponse.map((json) => Evento.fromJson(json)).toList();

        setState(() {
          _allEvents = events;
          _filteredEvents = events;
        });

        return events;
      } else {
        throw Exception('Falha ao carregar eventos da API');
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
              "Bem vindo ao Aplicativo",
              style: TextStyle(
                fontSize: 18,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Pesquise Eventos, Show e etc...",
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
                  MaterialPageRoute(builder: (context) => const CreateEventScreen()),
                );
                if (foiCriado == true) {
                  setState(() {
                    futureEventos = fetchEventos();
                  });
                }
              },
              icon: Icon(Icons.add, color: Colors.white),
              label: Text("Criar Novo Evento"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Explore os Eventos",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const EventMapWidget(),
            const SizedBox(height: 24),
            Expanded(
              child: FutureBuilder<List<Evento>>(
                future: futureEventos,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && _allEvents.isEmpty) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError && _allEvents.isEmpty) {
                    return Center(
                      child: Text(
                        "Nenhum evento Localizado\n\nErro: ${snapshot.error}",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  if (_filteredEvents.isEmpty && _searchController.text.isNotEmpty) {
                    return Center(
                      child: Text(
                        "Nenhum evento encontrado para \"${_searchController.text}\"",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    );
                  }

                  if (_filteredEvents.isEmpty) {
                    return Center(
                      child: Text(
                        "Nenhum evento\nLocalizado",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: _filteredEvents.length,
                    itemBuilder: (context, index) {
                      final evento = _filteredEvents[index];
                      return EventCard(evento: evento, primaryBlue: primaryBlue);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      endDrawer: const AppDrawer(),
    );
  }
}

class EventCard extends StatelessWidget {
  const EventCard({
    Key? key,
    required this.evento,
    required this.primaryBlue,
  }) : super(key: key);

  final Evento evento;
  final Color primaryBlue;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
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
            child: (evento.miniaturaUrl.isEmpty)
                ? Center(child: Icon(Icons.image_not_supported))
                : null,
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      evento.data,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  evento.categoria,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          evento.preco == 0.00 ? "Entrada" : "Ingresso",
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        Text(
                          evento.preco == 0.00 ? "Grátis" : "R\$ ${evento.preco.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: evento.preco == 0.00 ? Color(0xFF1B5E20) : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final bool? foiAtualizado = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EventDetailScreen(eventoId: evento.id),
                          ),
                        );
                        if (foiAtualizado == true) {
                          (context as Element).reassemble();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text("Mais Detalhes"),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios, size: 14),
                        ],
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