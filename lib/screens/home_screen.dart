import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'notifications.dart';
import 'create_pet.dart';
import 'swipe.dart';
import 'mascotas.dart';
import 'chat.dart';
import 'match.dart';
import '../controllers/payment_controller.dart';

class Mascota {
  final String? id;
  final String? nombre;
  final int? edad;
  final String? raza;
  final String? sexo;
  final List<String>? vacunas; // Changed to List<String>?
  final String? caracteristicas;
  final String? certificado;
  final dynamic fotos; // Keep as dynamic to handle different formats
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
        vacunasList = List<String>.from(
          json['vacunas'].map((x) => x.toString()),
        );
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
      fotos: json['fotos'], // Keep as dynamic
      comportamiento: json['comportamiento'],
      idUsuario: json['id_usuario'],
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;
  String _userName = '';
  String _email = '';
  String _userId = '';
  List<Mascota> _mascotas = [];
  bool _isLoading = true;
  int _unreadNotificationsCount = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkNotifications();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final nombreCompleto = prefs.getString('NombreCompleto');
      final email = prefs.getString('email');

      if (userId != null) {
        setState(() {
          _userId = userId;
          _userName = nombreCompleto ?? 'Usuario';
          _email = email ?? '';
        });

        await _loadMascotas(userId);
      } else {
        // Si no hay usuario, redirigir al login
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print('Error loading user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: ${e.toString()}')),
      );
    }
  }

  Future<void> _loadMascotas(String userId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Loading pets for user ID: $userId');

      final response = await _supabase
          .from('mascotas')
          .select()
          .eq('id_usuario', userId);

      print('Supabase response type: ${response.runtimeType}');

      final List<Mascota> mascotas = [];

      for (var item in response) {
        try {
          final mascota = Mascota.fromJson(item);
          mascotas.add(mascota);
        } catch (e) {
          print('Error parsing mascota: $e');
          print('Problematic record: $item');
        }
      }

      setState(() {
        _mascotas = mascotas;
        _isLoading = false;
      });

      print('Loaded ${mascotas.length} mascotas successfully');
    } catch (e) {
      print('Error loading mascotas: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar mascotas: ${e.toString()}')),
      );
    }
  }

  String? _extractImageData(dynamic fotos) {
    if (fotos == null) return null;

    try {
      if (fotos is String && fotos.startsWith('[') && fotos.endsWith(']')) {
        List<dynamic> parsed = jsonDecode(fotos);
        return parsed.isNotEmpty ? parsed[0].toString() : null;
      }

      if (fotos is List) {
        return fotos.isNotEmpty ? fotos[0].toString() : null;
      }

      if (fotos is String) {
        return fotos;
      }

      return fotos.toString();
    } catch (e) {
      print('Error extracting image data: $e');
      return null;
    }
  }

  Future<void> _checkNotifications() async {
    setState(() {
      _unreadNotificationsCount = 3;
    });
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cerrar sesión'),
          content: Text('¿Estás seguro que deseas cerrar sesión?'),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Cerrar sesión'),
              onPressed: () async {
                await _supabase.auth.signOut();
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.settings, color: Colors.brown[700]),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Text(
          'Dogzline',
          style: TextStyle(
            fontSize: 24,
            color: Colors.brown[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications,
                  color: const Color.fromARGB(255, 93, 64, 55),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationsPage(),
                    ),
                  );
                },
              ),
              if (_unreadNotificationsCount > 0)
                Positioned(
                  right: 11,
                  top: 11,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.red,
                    child: Text(
                      '$_unreadNotificationsCount',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.brown[700]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage('assets/Logo_dogzline.png'),
                    backgroundColor: Colors.transparent,
                  ),
                  SizedBox(height: 10),
                  Text(
                    _userName,
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    _email,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Cerrar sesión'),
              onTap: () {
                Navigator.pop(context);
                _showLogoutConfirmationDialog();
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadUserData(),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Mensaje de bienvenida
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      'Bienvenido $_userName',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[700],
                      ),
                    ),
                    Text(
                      _email,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // Nivel de suscripción
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dogzline',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[700],
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '¿Qué incluye?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[700],
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.check, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Recomendaciones Personalizadas'),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.check, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Coincidencias Prioritarias'),
                      ],
                    ),
                  ],
                ),
              ),
              // Perros registrados
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Perros registrados',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    _isLoading
                        ? Center(child: CircularProgressIndicator())
                        : _mascotas.isEmpty
                        ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.pets,
                                  size: 60,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'No hay perros registrados',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Registra a tu mascota para encontrar amistades o pareja',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 20),
                                ElevatedButton.icon(
                                  icon: Icon(Icons.add),
                                  label: Text('Agregar mascota'),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.brown[700],
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CreatePetScreen(),
                                      ),
                                    ).then((_) => _loadUserData());
                                  },
                                ),
                              ],
                            ),
                          ),
                        )
                        : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 3 / 4,
                                ),
                            itemCount: _mascotas.length,
                            itemBuilder: (context, index) {
                              final mascota = _mascotas[index];
                              // Extract the image correctly
                              final imageData = _extractImageData(
                                mascota.fotos,
                              );

                              Widget imageWidget;
                              if (imageData != null &&
                                  imageData.contains('base64')) {
                                try {
                                  // For base64 encoded images
                                  final base64String =
                                      imageData.split(',').last;
                                  imageWidget = Image.memory(
                                    base64Decode(base64String),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      print('Error loading image: $error');
                                      return Icon(
                                        Icons.pets,
                                        size: 40,
                                        color: Colors.grey[400],
                                      );
                                    },
                                  );
                                } catch (e) {
                                  print('Error decoding image: $e');
                                  imageWidget = Icon(
                                    Icons.pets,
                                    size: 40,
                                    color: Colors.grey[400],
                                  );
                                }
                              } else if (imageData != null &&
                                  (imageData.startsWith('http://') ||
                                      imageData.startsWith('https://'))) {
                                // For URL images
                                imageWidget = Image.network(
                                  imageData,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.pets,
                                      size: 40,
                                      color: Colors.grey[400],
                                    );
                                  },
                                );
                              } else {
                                // Default icon when no image is available
                                imageWidget = Icon(
                                  Icons.pets,
                                  size: 40,
                                  color: Colors.grey[400],
                                );
                              }

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => SwipeScreen(
                                            mascotaId: mascota.id!,
                                          ),
                                    ),
                                  );
                                },
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 5,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(15),
                                          ),
                                          child: imageWidget,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          mascota.nombre ?? '',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.brown[700],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Color(0xFFF9F6E8),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.brown[700],
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          switch (index) {
            case 0:
              // Ya estamos en HomeScreen
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MatchScreen()),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ChatScreen()),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MascotasScreen()),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Match'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Mascotas'),
        ],
      ),
      floatingActionButton:
          _mascotas.isEmpty
              ? null
              : FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CreatePetScreen()),
                  ).then((_) => _loadUserData());
                },
                backgroundColor: const Color.fromARGB(255, 93, 64, 55),
                child: Icon(
                  Icons.add,
                  color: Colors.white, // Cambia el color del ícono aquí
                ),
              ),
    );
  }
}
