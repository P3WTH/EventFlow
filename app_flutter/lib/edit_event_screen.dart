import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'detalhes_de_eventos.dart';
import 'create_event_screen.dart';

class EditEventScreen extends StatefulWidget {
  final EventoDetalhe evento;

  const EditEventScreen({Key? key, required this.evento}) : super(key: key);

  @override
  _EditEventScreenState createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _nomeController;
  late TextEditingController _descController;
  late TextEditingController _dataController;
  late TextEditingController _precoController;

  List<Categoria> _categorias = [];
  List<Local> _locais = [];
  Categoria? _categoriaSelecionada;
  Local? _localSelecionado;

  late Future<void> _loadingData;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.evento.nome);
    _descController = TextEditingController(text: widget.evento.descricaoLonga);
    _dataController = TextEditingController(text: widget.evento.data);
    _precoController =
        TextEditingController(text: widget.evento.preco.toString());

    _loadingData = _fetchDropdownData();
  }

  String getApiUrl(String endpoint) {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/$endpoint';
    } else {
      return 'http://127.0.0.1:5000/$endpoint';
    }
  }

  Future<void> _fetchDropdownData() async {
    try {
      final [catResponse, localResponse] = await Future.wait([
        http.get(Uri.parse(getApiUrl('categorias'))),
        http.get(Uri.parse(getApiUrl('locais'))),
      ]);

      if (catResponse.statusCode == 200) {
        List<dynamic> jsonCats =
        json.decode(utf8.decode(catResponse.bodyBytes));
        _categorias = jsonCats.map((json) => Categoria.fromJson(json)).toList();

        setState(() {
          _categoriaSelecionada = _categorias.firstWhere(
                  (cat) => cat.nome == widget.evento.categoria,
              orElse: () => _categorias.first);
        });
      } else {
        throw Exception('Falha ao carregar categorias');
      }

      if (localResponse.statusCode == 200) {
        List<dynamic> jsonLocais =
        json.decode(utf8.decode(localResponse.bodyBytes));
        _locais = jsonLocais.map((json) => Local.fromJson(json)).toList();

        setState(() {
          _localSelecionado = _locais.firstWhere(
                  (loc) => loc.nome == widget.evento.localizacaoNome,
              orElse: () => _locais.first);
        });
      } else {
        throw Exception('Falha ao carregar locais');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar dados: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _salvarEdicao() async {
    if (_formKey.currentState!.validate() &&
        _categoriaSelecionada != null &&
        _localSelecionado != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await http.put(
          Uri.parse(getApiUrl('eventos/${widget.evento.id}')),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, dynamic>{
            'nome': _nomeController.text,
            'descricao': _descController.text,
            'data': _dataController.text,
            'preco': double.tryParse(_precoController.text) ?? 0.0,
            'categoria_nome': _categoriaSelecionada!.nome,
            'local_nome': _localSelecionado!.nome,
          }),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Evento atualizado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Retorna 'true' para atualizar
        } else {
          throw Exception('Falha ao atualizar evento');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar evento: $e'),
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
          "Editar Evento",
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
      body: FutureBuilder(
        future: _loadingData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Erro ao carregar dados. Tente novamente."));
          } else {
            return _buildForm();
          }
        },
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Editando: ${widget.evento.nome}",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            _buildTextFormField(_nomeController, "Nome"),
            _buildTextFormField(_descController, "Descrição", maxLines: 3),
            _buildDropdown<Categoria>(
              hint: "Please select Categoria",
              value: _categoriaSelecionada,
              items: _categorias,
              onChanged: (Categoria? newValue) {
                setState(() {
                  _categoriaSelecionada = newValue;
                });
              },
              itemBuilder: (Categoria item) => item.nome,
            ),
            _buildTextFormField(_dataController, "Data do Evento",
                icon: Icons.calendar_today),
            _buildTextFormField(_precoController, "Preço",
                keyboardType: TextInputType.number),
            _buildDropdown<Local>(
              hint: "Selecione os Locais Cadastrados",
              value: _localSelecionado,
              items: _locais,
              onChanged: (Local? newValue) {
                setState(() {
                  _localSelecionado = newValue;
                });
              },
              itemBuilder: (Local item) => item.nome,
            ),
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
    );
  }

  Widget _buildTextFormField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text,
        int maxLines = 1,
        IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: lightGray,
          suffixIcon: icon != null ? Icon(icon, color: Colors.grey[600]) : null,
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

  Widget _buildDropdown<T>({
    required String hint,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    required String Function(T) itemBuilder,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<T>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: hint,
          filled: true,
          fillColor: lightGray,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
        ),
        hint: Text(hint, style: TextStyle(color: Colors.grey[600])),
        items: items.map((T item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(itemBuilder(item), overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (value) {
          if (value == null) {
            return 'Por favor, selecione uma opção';
          }
          return null;
        },
      ),
    );
  }
}