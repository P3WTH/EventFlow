import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'local_list_screen.dart';

class EditLocalScreen extends StatefulWidget {
  final Local local;

  const EditLocalScreen({Key? key, required this.local}) : super(key: key);

  @override
  _EditLocalScreenState createState() => _EditLocalScreenState();
}

class _EditLocalScreenState extends State<EditLocalScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomeController;
  late TextEditingController _enderecoController;
  late TextEditingController _bairroController;
  late TextEditingController _cidadeController;
  late TextEditingController _cepController;
  late TextEditingController _numeroController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _nomeController = TextEditingController(text: widget.local.nome);
    _enderecoController = TextEditingController(text: widget.local.endereco);
    _bairroController = TextEditingController(text: "Bairro Exemplo");
    _cidadeController = TextEditingController(text: "Cidade Exemplo");
    _cepController = TextEditingController(text: "CEP Exemplo");
    _numeroController = TextEditingController(text: "123");
    _latitudeController = TextEditingController(text: widget.local.latitude.toString());
    _longitudeController = TextEditingController(text: widget.local.longitude.toString());
  }

  String getApiUrl(int id) {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/locais/$id';
    } else {
      return 'http://127.0.0.1:5000/locais/$id';
    }
  }

  Future<void> _salvarEdicao() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final String apiUrl = getApiUrl(widget.local.id);

      try {
        final response = await http.put(
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

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Local atualizado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          throw Exception('Falha ao atualizar local');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar local: $e'),
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
          "Editar Local",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Editar Local: ${widget.local.nome}",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: lightGray,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Center(
                  child: Text(
                    "[Widget do Mapa]",
                    style: TextStyle(color: Colors.black54),
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
              _buildTextFormField(_latitudeController, "Latitude",
                  keyboardType: TextInputType.number),
              _buildTextFormField(_longitudeController, "Longitude",
                  keyboardType: TextInputType.number),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _salvarEdicao,
                      child: _isLoading
                          ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text("Salvar Alterações"),
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