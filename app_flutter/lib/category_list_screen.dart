import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'app_drawer.dart';

class Categoria {
  final int id;
  String nome;

  Categoria({required this.id, required this.nome});

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(id: json['id'], nome: json['nome']);
  }
}

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({Key? key}) : super(key: key);

  @override
  _CategoryListScreenState createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  late Future<List<Categoria>> futureCategorias;
  final TextEditingController _categoryNameController = TextEditingController();

  final Color primaryBlue = Color(0xFF0D47A1);

  @override
  void initState() {
    super.initState();
    futureCategorias = fetchCategorias();
  }

  String getApiUrl(String endpoint) {
    String host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    return 'http://$host:5000/$endpoint';
  }

  Future<List<Categoria>> fetchCategorias() async {
    try {
      final response = await http.get(Uri.parse(getApiUrl('categorias')));
      if (response.statusCode == 200) {
        List<dynamic> jsonResponse =
        json.decode(utf8.decode(response.bodyBytes));
        return jsonResponse.map((json) => Categoria.fromJson(json)).toList();
      } else {
        throw Exception('Falha ao carregar categorias');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  Future<void> _saveCategory({Categoria? categoria}) async {
    final nome = _categoryNameController.text;
    if (nome.isEmpty) return;

    final isEditing = categoria != null;
    final url = isEditing
        ? getApiUrl('categorias/${categoria.id}')
        : getApiUrl('categorias');

    final body = jsonEncode({'nome': nome});

    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };

    try {
      final response = isEditing
          ? await http.put(Uri.parse(url), headers: headers, body: body)
          : await http.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Categoria ${isEditing ? 'atualizada' : 'criada'} com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          futureCategorias = fetchCategorias();
        });
      } else {
        throw Exception('Falha ao salvar categoria');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    _categoryNameController.clear();
    Navigator.of(context).pop();
  }

  Future<void> _deleteCategory(int id) async {
    final String apiUrl = getApiUrl('categorias/$id');
    try {
      final response = await http.delete(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Categoria deletada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          futureCategorias = fetchCategorias();
        });
      } else {
        throw Exception('Falha ao deletar categoria');
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

  void _showCategoryDialog({Categoria? categoria}) {
    final isEditing = categoria != null;
    _categoryNameController.text = isEditing ? categoria.nome : '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar Categoria' : 'Nova Categoria'),
          content: TextField(
            controller: _categoryNameController,
            autofocus: true,
            decoration: InputDecoration(hintText: "Nome da Categoria"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                _categoryNameController.clear();
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Salvar'),
              onPressed: () => _saveCategory(categoria: categoria),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Gerenciar Categorias",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black54),
      ),
      body: FutureBuilder<List<Categoria>>(
        future: futureCategorias,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Erro: ${snapshot.error}"));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final categorias = snapshot.data!;
            return ListView.builder(
              itemCount: categorias.length,
              itemBuilder: (context, index) {
                final categoria = categorias[index];
                return ListTile(
                  title: Text(categoria.nome),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: yellowButton),
                        onPressed: () => _showCategoryDialog(categoria: categoria),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: redButton),
                        onPressed: () => _deleteCategory(categoria.id),
                      ),
                    ],
                  ),
                );
              },
            );
          } else {
            return Center(child: Text("Nenhuma categoria cadastrada"));
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(),
        child: Icon(Icons.add),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      endDrawer: const AppDrawer(),
    );
  }

  final Color yellowButton = Color(0xFFFFC107);
  final Color redButton = Color(0xFFD32F2F);
}