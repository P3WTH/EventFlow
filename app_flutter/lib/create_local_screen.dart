import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';

class CreateLocalScreen extends StatefulWidget {
  const CreateLocalScreen({Key? key}) : super(key: key);

  @override
  _CreateLocalScreenState createState() => _CreateLocalScreenState();
}

class _CreateLocalScreenState extends State<CreateLocalScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _enderecoController = TextEditingController();
  final TextEditingController _bairroController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  bool _isLoading = false;

  GoogleMapController? _mapController;
  Marker? _marker;
  final CameraPosition _initialCamera = CameraPosition(
    target: LatLng(-23.550520, -46.633308),
    zoom: 12,
  );

  void _onMapTapped(LatLng position) {
    setState(() {
      _marker = Marker(
        markerId: MarkerId('new_local_marker'),
        position: position,
      );
      _latitudeController.text = position.latitude.toStringAsFixed(7);
      _longitudeController.text = position.longitude.toStringAsFixed(7);
    });
  }

  String getApiUrl() {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/locais';
    } else {
      return 'http://127.0.0.1:5000/locais';
    }
  }

  Future<void> _salvarLocal() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final String apiUrl = getApiUrl();

      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, dynamic>{
            'nome': _nomeController.text,
            'endereco': _enderecoController.text,
            'bairro': _bairroController.text,
            'cidade': _cidadeController.text,
            'cep': _cepController.text,
            'numero': _numeroController.text,
            'latitude': double.tryParse(_latitudeController.text) ?? 0.0,
            'longitude': double.tryParse(_longitudeController.text) ?? 0.0,
          }),
        );

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Local criado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          throw Exception('Falha ao criar local (Status: ${response.statusCode})');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar local: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _enderecoController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _cepController.dispose();
    _numeroController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  final Color primaryBlue = Color(0xFF0D47A1);
  final Color redButton = Color(0xFFD32F2F);
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.menu, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Cadastrar Local",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 250,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: GoogleMap(
                    initialCameraPosition: _initialCamera,
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                    },
                    onTap: _onMapTapped,
                    markers: _marker == null ? {} : {_marker!},
                    // --- ESTA É A CORREÇÃO ---
                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                      Factory<EagerGestureRecognizer>(
                            () => EagerGestureRecognizer(),
                      ),
                    },

                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildTextFormField(_nomeController, "Nome"),
              _buildTextFormField(_enderecoController, "Endereço"),
              _buildTextFormField(_bairroController, "Bairro"),
              _buildTextFormField(_cidadeController, "Cidade"),
              Row(
                children: [
                  Expanded(
                    child: _buildTextFormField(_cepController, "CEP"),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextFormField(_numeroController, "Numero"),
                  ),
                ],
              ),
              _buildTextFormField(_latitudeController, "Latitude (Toque no mapa)",
                  keyboardType: TextInputType.number),
              _buildTextFormField(_longitudeController, "Longitude (Toque no mapa)",
                  keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  "Ou Marque no Mapa o Local Desejado",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _salvarLocal,
                      child: _isLoading
                          ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text("Salvar"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text("Cancelar"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: redButton,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: lightGray,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: primaryBlue, width: 2),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor, preencha este campo';
          }
          return null;
        },
      ),
    );
  }
}