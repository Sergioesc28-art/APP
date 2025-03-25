import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'chat.dart';
import 'home_screen.dart';
import 'match.dart';
import 'dog_detail_screen.dart'; // Importa DogDetailScreen

class Dog {
  final String name;
  final String breed;
  final String age;
  final String gender;
  final String imageUrl;
  final String vaccines;
  final String certificate;
  final String behavior;
  final String description;

  Dog({
    required this.name,
    required this.breed,
    required this.age,
    required this.gender,
    required this.imageUrl,
    required this.vaccines,
    required this.certificate,
    required this.behavior,
    required this.description,
  });

  factory Dog.fromJson(Map<String, dynamic> json) {
    return Dog(
      name: json['nombre'],
      breed: json['raza'],
      age: json['edad'].toString(),
      gender: json['sexo'],
      imageUrl: json['fotos'] != null && json['fotos'].isNotEmpty ? json['fotos'][0] : '',
      vaccines: json['vacunas'] != null ? json['vacunas'].join(', ') : '',
      certificate: json['certificado'] ?? '',
      behavior: json['comportamiento'] ?? '',
      description: json['caracteristicas'] ?? '',
    );
  }
}

class MascotasScreen extends StatefulWidget {
  const MascotasScreen({super.key});

  @override
  _MascotasScreenState createState() => _MascotasScreenState();
}

class _MascotasScreenState extends State<MascotasScreen> {
  final _supabase = Supabase.instance.client;
  List<Dog> _dogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDogs();
  }

  Future<void> _loadDogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId != null) {
        final response = await _supabase
            .from('mascotas')
            .select()
            .eq('id_usuario', userId);

        final List<Dog> dogs = [];
        for (var item in response) {
          try {
            final dog = Dog.fromJson(item);
            dogs.add(dog);
          } catch (e) {
            print('Error parsing dog: $e');
            print('Problematic record: $item');
          }
        }

        setState(() {
          _dogs = dogs;
          _isLoading = false;
        });
      } else {
        // Si no hay usuario, redirigir al login
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print('Error loading dogs: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar perros: ${e.toString()}')),
      );
    }
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
        break;
      case 1:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MatchScreen()));
        break;
      case 2:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ChatScreen()));
        break;
      case 3:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MascotasScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Mascotas',
          style: TextStyle(
            fontSize: 24,
            color: Colors.brown[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _dogs.isEmpty
              ? Center(child: Text('No hay perros disponibles'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _dogs.length,
                  itemBuilder: (context, index) {
                    final dog = _dogs[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: dog.imageUrl.isNotEmpty
                              ? (dog.imageUrl.startsWith('http') 
                                  ? NetworkImage(dog.imageUrl) 
                                  : MemoryImage(base64Decode(dog.imageUrl.split(',').last)) as ImageProvider)
                              : null,
                          backgroundColor: Colors.purple[100],
                          child: dog.imageUrl.isEmpty
                              ? Icon(Icons.pets, color: Colors.purple[700])
                              : null,
                        ),
                        title: Text(dog.name),
                        subtitle: Text('${dog.breed} • ${dog.age} • ${dog.gender}'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DogDetailScreen(
                                name: dog.name,
                                breed: dog.breed,
                                age: dog.age,
                                gender: dog.gender,
                                imageUrl: dog.imageUrl,
                                vaccines: dog.vaccines,
                                certificate: dog.certificate,
                                behavior: dog.behavior,
                                description: dog.description,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      backgroundColor: Color(0xFFF9F6E8),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3, // Índice activo para Mascotas
        selectedItemColor: Colors.purple[700],
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => _onItemTapped(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Match',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'Mascotas',
          ),
        ],
      ),
    );
  }
}