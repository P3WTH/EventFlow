import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';


class Categoria {
  final int id;
  final String nome;
  Categoria({required this.id, required this.nome});
  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(id: json['id'], nome: json['nome']);
  }
}

class Local {
  final int id;
  final String nome;
  final double latitude;
  final double longitude;

  Local({
    required this.id,
    required this.nome,
    required this.latitude,
    required this.longitude,
  });

  factory Local.fromJson(Map<String, dynamic> json) {
    return Local(
      id: json['id'],
      nome: json['nome'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}


class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({Key? key}) : super(key: key);

  @override
  _CreateEventScreenState createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _horaIniController = TextEditingController();
  final TextEditingController _horaFimController = TextEditingController();
  final TextEditingController _precoController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  List<Categoria> _categorias = [];
  List<Local> _locais = [];
  Categoria? _categoriaSelecionada;
  Local? _localSelecionado;

  late Future<void> _loadingData;


  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  GoogleMapController? _mapController;
  Marker? _marker;
  final CameraPosition _initialCamera = CameraPosition(
    target: LatLng(-23.550520, -46.633308),
    zoom: 12,
  );

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
      } else {
        throw Exception('Falha ao carregar categorias');
      }

      if (localResponse.statusCode == 200) {
        List<dynamic> jsonLocais =
        json.decode(utf8.decode(localResponse.bodyBytes));
        _locais = jsonLocais.map((json) => Local.fromJson(json)).toList();
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

  @override
  void initState() {
    super.initState();
    _loadingData = _fetchDropdownData();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dataController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.format(context);
      });
    }
  }


  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Falha ao selecionar imagem: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      _marker = Marker(
        markerId: MarkerId('new_local_marker'),
        position: position,
      );
      _latitudeController.text = position.latitude.toStringAsFixed(7);
      _longitudeController.text = position.longitude.toStringAsFixed(7);
      _localSelecionado = null;
    });
  }

  void _onLocalSelecionado(Local? local) {
    if (local == null) return;
    setState(() {
      _localSelecionado = local;
      _latitudeController.text = local.latitude.toStringAsFixed(7);
      _longitudeController.text = local.longitude.toStringAsFixed(7);
      final position = LatLng(local.latitude, local.longitude);
      _marker = Marker(
        markerId: MarkerId(local.id.toString()),
        position: position,
      );
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: position, zoom: 15),
        ),
      );
    });
  }

  Future<void> _salvarEvento() async {


    if (_formKey.currentState!.validate() &&
        _categoriaSelecionada != null &&
        _localSelecionado != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await http.post(
          Uri.parse(getApiUrl('eventos')),
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

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Evento criado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          throw Exception('Falha ao criar evento');
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor, preencha todos os campos, incluindo categoria e local.'),
          backgroundColor: Colors.orange,
        ),
      );
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
              "Cadastrar Evento",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildImageUpload(),
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
            _buildTextFormField(
              _dataController,
              "Data do Evento",
              icon: Icons.calendar_today,
              readOnly: true,
              onTap: () => _selectDate(context),
            ),
            Row(
              children: [
                Expanded(
                  child: _buildTextFormField(
                    _horaIniController,
                    "Horário Inicial",
                    icon: Icons.access_time,
                    readOnly: true,
                    onTap: () => _selectTime(context, _horaIniController),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextFormField(
                    _horaFimController,
                    "Horário Final",
                    icon: Icons.access_time,
                    readOnly: true,
                    onTap: () => _selectTime(context, _horaFimController),
                  ),
                ),
              ],
            ),
            _buildTextFormField(_precoController, "Preço",
                keyboardType: TextInputType.number),
            _buildDropdown<Local>(
              hint: "Selecione os Locais Cadastrados",
              value: _localSelecionado,
              items: _locais,
              onChanged: (Local? newValue) {
                _onLocalSelecionado(newValue);
              },
              itemBuilder: (Local item) => item.nome,
            ),
            const SizedBox(height: 16),
            Center(child: Text("Ou")),
            const SizedBox(height: 16),
            Container(
              height: 200,
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
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                    Factory<EagerGestureRecognizer>(
                          () => EagerGestureRecognizer(),
                    ),
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildTextFormField(_latitudeController, "Latitude (Automático)",
                keyboardType: TextInputType.number),
            _buildTextFormField(_longitudeController, "Longitude (Automático)",
                keyboardType: TextInputType.number),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _salvarEvento,
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
    );
  }


  Widget _buildImageUpload() {
    return Row(
      children: [
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            color: lightGray,
            borderRadius: BorderRadius.circular(8),
            image: _imageFile != null
                ? DecorationImage(
              image: FileImage(_imageFile!),
              fit: BoxFit.cover,
            )
                : null,
          ),
          child: _imageFile == null
              ? Center(child: Icon(Icons.image, color: Colors.grey[600]))
              : null,
        ),
        SizedBox(width: 16),

        InkWell(
          onTap: () => _pickImage(ImageSource.camera),
          child: Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: lightGray, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt, color: Colors.grey[600]),
                SizedBox(height: 4),
                Text("Câmera", style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
        ),
        SizedBox(width: 16),

        InkWell(
          onTap: () => _pickImage(ImageSource.gallery),
          child: Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: lightGray, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library, color: Colors.grey[600]),
                SizedBox(height: 4),
                Text("Galeria", style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildTextFormField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text,
        int maxLines = 1,
        IconData? icon,
        bool readOnly = false,
        VoidCallback? onTap,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: readOnly ? Colors.grey[100] : lightGray,
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