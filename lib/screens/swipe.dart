import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

class Mascota {
  final String? id;
  final String? nombre;
  final int? edad;
  final String? raza;
  final String? sexo;
  final List<String>? vacunas;  // Changed to List<String>?
  final String? caracteristicas;
  final String? certificado;
  final dynamic fotos;  // Keep as dynamic to handle different formats
  final String? comportamiento;
  final String? idUsuario;

  Mascota({
    this.id,
    this.nombre,
    this.edad,
    this.raza,
    this.sexo,
    this.vacunas,
    this.caracteristicas,
    this.certificado,
    this.fotos,
    this.comportamiento,
    this.idUsuario,
  });

  factory Mascota.fromJson(Map<String, dynamic> json) {
    // Handle vacunas field which could be a List or null
    List<String>? vacunasList;
    if (json['vacunas'] != null) {
      if (json['vacunas'] is List) {
        vacunasList = List<String>.from(json['vacunas'].map((x) => x.toString()));
      } else if (json['vacunas'] is String) {
        // If it's a single string, make it a list with one item
        vacunasList = [json['vacunas']];
      }
    }

    return Mascota(
      id: json['id'],
      nombre: json['nombre'],
      edad: json['edad'],
      raza: json['raza'],
      sexo: json['sexo'],
      vacunas: vacunasList,
      caracteristicas: json['caracteristicas'],
      certificado: json['certificado'],
      fotos: json['fotos'],  // Keep as dynamic
      comportamiento: json['comportamiento'],
      idUsuario: json['id_usuario'],
    );
  }
}

class SwipeScreen extends StatefulWidget {
  final String mascotaId;

  const SwipeScreen({super.key, required this.mascotaId});

  @override
  _SwipeScreenState createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final _supabase = Supabase.instance.client;
  List<Mascota> _mascotas = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  String _userId = '';
  String _currentMascotaId = '';
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _currentMascotaId = widget.mascotaId;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId != null) {
        setState(() {
          _userId = userId;
        });
        await _loadMascotasParaSwipe();
      } else {
        // Si no hay usuario, redirigir al login
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: ${e.toString()}')),
      );
    }
  }

  Widget _buildImageWidget(dynamic fotosData) {
    if (fotosData == null) {
      return Container(
        color: Colors.grey[300],
        child: Center(
          child: Icon(Icons.pets, size: 80, color: Colors.grey[400]),
        ),
      );
    }
    
    try {
      // Extract the first image if it's a list or JSON string array
      String imageData = '';
      
      if (fotosData is String && fotosData.startsWith('[') && fotosData.endsWith(']')) {
        try {
          List<dynamic> parsed = jsonDecode(fotosData);
          imageData = parsed.isNotEmpty ? parsed[0].toString() : '';
        } catch (e) {
          imageData = fotosData;
        }
      } else if (fotosData is List) {
        imageData = fotosData.isNotEmpty ? fotosData[0].toString() : '';
      } else {
        imageData = fotosData.toString();
      }
      
      // Handle different types of image formats
      if (imageData.contains('base64')) {
        // For base64 encoded images
        final base64String = imageData.split(',').last;
        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading base64 image: $error');
            return Container(
              color: Colors.grey[300],
              child: Center(
                child: Icon(Icons.broken_image, size: 80, color: Colors.grey[400]),
              ),
            );
          },
        );
      } else if (imageData.startsWith('http://') || imageData.startsWith('https://')) {
        // For URL images
        return Image.network(
          imageData,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading network image: $error');
            return Container(
              color: Colors.grey[300],
              child: Center(
                child: Icon(Icons.broken_image, size: 80, color: Colors.grey[400]),
              ),
            );
          },
        );
      } else {
        // Try as base64 anyway as a fallback
        try {
          return Image.memory(
            base64Decode(imageData),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              throw error; // Rethrow to be caught by outer try-catch
            },
          );
        } catch (e) {
          print('Error decoding image data: $e');
          return Container(
            color: Colors.grey[300],
            child: Center(
              child: Icon(Icons.error_outline, size: 80, color: Colors.grey[400]),
            ),
          );
        }
      }
    } catch (e) {
      print('Error processing image: $e');
      return Container(
        color: Colors.grey[300],
        child: Center(
          child: Icon(Icons.error_outline, size: 80, color: Colors.grey[400]),
        ),
      );
    }
  }

  Future<void> _loadMascotasParaSwipe() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener todas las mascotas excepto las del usuario actual
      final response = await _supabase
          .from('mascotas')
          .select()
          .neq('id_usuario', _userId);

      final List<Mascota> mascotas = (response as List)
          .map((item) => Mascota.fromJson(item))
          .toList();

      // Eliminar mascotas que ya tengan un match o rechazo
      final matchesResponse = await _supabase
          .from('matches')
          .select()
          .eq('mascota_id', _currentMascotaId);

      final List<String> matchedOrRejectedIds = (matchesResponse as List)
          .map<String>((match) => match['mascota_match_id'].toString())
          .toList();

      final filteredMascotas = mascotas.where((mascota) => 
          !matchedOrRejectedIds.contains(mascota.id)).toList();

      // Mezclar las mascotas para mostrarlas en orden aleatorio
      filteredMascotas.shuffle(Random());

      setState(() {
        _mascotas = filteredMascotas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar mascotas: ${e.toString()}')),
      );
    }
  }

  void _like() async {
    if (_currentIndex < _mascotas.length) {
      final matchedMascota = _mascotas[_currentIndex];
      
      try {
        // Guardar el match en la base de datos con estado "liked"
        await _supabase.from('matches').insert({
          'mascota_id': _currentMascotaId,
          'mascota_match_id': matchedMascota.id,
          'estado': 'liked',
          'fecha_match': DateTime.now().toIso8601String(),
        });

        // Verificar si existe un match recíproco
        final reciprocalMatchResponse = await _supabase
            .from('matches')
            .select()
            .eq('mascota_id', matchedMascota.id!)
            .eq('mascota_match_id', _currentMascotaId)
            .eq('estado', 'liked');

        final reciprocalMatches = reciprocalMatchResponse as List;
        
        if (reciprocalMatches.isNotEmpty) {
          // Actualizar ambos matches a 'matched'
          await _supabase
              .from('matches')
              .update({'estado': 'matched'})
              .eq('mascota_id', _currentMascotaId)
              .eq('mascota_match_id', matchedMascota.id!);

          await _supabase
              .from('matches')
              .update({'estado': 'matched'})
              .eq('mascota_id', matchedMascota.id!)
              .eq('mascota_match_id', _currentMascotaId);

          // Crear notificación de match
          await _supabase.from('notificaciones').insert({
            'usuario_id': _userId,
            'tipo': 'match',
            'contenido': '¡Tu mascota ${matchedMascota.nombre} ha hecho match!',
            'referencia_id': matchedMascota.id,
          });

          // Mostrar diálogo de match
          _showMatchDialog(matchedMascota);
        }

        // Pasar a la siguiente mascota
        if (_currentIndex < _mascotas.length - 1) {
          setState(() {
            _currentIndex++;
            _showDetails = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No hay más mascotas para mostrar')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar el match: ${e.toString()}')),
        );
      }
    }
  }

  void _dislike() async {
    if (_currentIndex < _mascotas.length) {
      final rejectedMascota = _mascotas[_currentIndex];
      
      try {
        // Guardar el rechazo en la base de datos
        await _supabase.from('matches').insert({
          'mascota_id': _currentMascotaId,
          'mascota_match_id': rejectedMascota.id,
          'estado': 'rejected',
          'fecha_match': DateTime.now().toIso8601String(),
        });

        // Pasar a la siguiente mascota
        if (_currentIndex < _mascotas.length - 1) {
          setState(() {
            _currentIndex++;
            _showDetails = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No hay más mascotas para mostrar')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar el rechazo: ${e.toString()}')),
        );
      }
    }
  }

  void _showMatchDialog(Mascota matchedMascota) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.pinkAccent, Colors.purpleAccent],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 60,
                ),
                SizedBox(height: 20),
                Text(
                  '¡Es un Match!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Tu mascota y ${matchedMascota.nombre} se han gustado mutuamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.purpleAccent,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        child: Text(
                          'Seguir buscando',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.brown[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        child: Text(
                          'Ver Chats',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.pushReplacementNamed(context, '/chat');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

Widget _buildSwipeCard() {
  if (_mascotas.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pets, size: 80, color: Colors.grey[400]),
          SizedBox(height: 20),
          Text(
            'No hay mascotas disponibles',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  if (_currentIndex >= _mascotas.length) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pets, size: 80, color: Colors.grey[400]),
          SizedBox(height: 20),
          Text(
            'No hay más mascotas para mostrar',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.brown[700],
            ),
            onPressed: _loadMascotasParaSwipe,
            child: Text('Refrescar'),
          ),
        ],
      ),
    );
  }

  final mascota = _mascotas[_currentIndex];
  return Column(
    children: [
      Expanded(
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _showDetails = !_showDetails;
                      });
                    },
                    child: _buildImageWidget(mascota.fotos),
                  ),
                ),
              ),
              if (!_showDetails)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${mascota.nombre ?? 'Sin nombre'}, ${mascota.edad ?? 'N/A'} años',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (mascota.sexo != null)
                            Icon(
                              mascota.sexo?.toLowerCase() == 'm'
                                  ? Icons.male
                                  : Icons.female,
                              color: mascota.sexo?.toLowerCase() == 'm'
                                  ? Colors.blue
                                  : Colors.pink,
                              size: 28,
                            ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Raza: ${mascota.raza ?? 'No especificada'}',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 4),
                
                      SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          child: Text(
                            'Más detalles',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.brown[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _showDetails = true;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              if (_showDetails)
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${mascota.nombre ?? 'Sin nombre'}, ${mascota.edad ?? 'N/A'} años',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Sexo: ',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              mascota.sexo == 'M' ? 'Macho' : 'Hembra',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              mascota.sexo == 'M' ? Icons.male : Icons.female,
                              color: mascota.sexo == 'M' ? Colors.blue : Colors.pink,
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Raza: ',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              mascota.raza ?? 'No especificada',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
            
                        SizedBox(height: 8),
                        Text(
                          'Vacunas: ',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          mascota.vacunas != null ? mascota.vacunas!.join(', ') : 'No especificadas',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Características: ',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          mascota.caracteristicas ?? 'No especificadas',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Comportamiento: ',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          mascota.comportamiento ?? 'No especificado',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            child: Text(
                              'Volver a la foto',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.brown[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _showDetails = false;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      SizedBox(height: 20),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(
            heroTag: 'dislike',
            onPressed: _dislike,
            backgroundColor: Colors.white,
            foregroundColor: Colors.red,
            child: Icon(Icons.close, size: 30),
          ),
          FloatingActionButton(
            heroTag: 'like',
            onPressed: _like,
            backgroundColor: Colors.white,
            foregroundColor: Colors.green,
            child: Icon(Icons.favorite, size: 30),
          ),
        ],
      ),
    ],
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.brown[700]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Encuentra pareja',
          style: TextStyle(
            color: Colors.brown[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildSwipeCard(),
              ),
            ),
      backgroundColor: Color(0xFFF9F6E8),
    );
  }
}