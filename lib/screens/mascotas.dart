import 'package:flutter/material.dart';
import 'chat.dart';
import 'home_screen.dart';
import 'match.dart';

class MascotasScreen extends StatelessWidget {
  const MascotasScreen({super.key});

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
        break;
      case 1:

        break;
      case 2:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ChatScreen()));
        break;
      case 3:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MatchScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3, // Cambia esto por el número real de mascotas
        itemBuilder: (context, index) {
          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.purple[100],
                child: Icon(Icons.pets, color: Colors.purple[700]),
              ),
              title: Text('Mascota ${index + 1}'),
              subtitle: Text('Raza • Edad • Género'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Aquí puedes navegar a detalles si quieres
              },
            ),
          );
        },
      ),
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
