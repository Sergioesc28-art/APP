import 'package:flutter/material.dart';

// Esta será nuestra pantalla principal que contiene la navegación
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  
  // Lista de pantallas entre las que navegaremos
  final List<Widget> _screens = [
    const HomeContent(),
    const MascotasContent(),
    const MatchContent(),
    const ChatContent(),
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Si no estamos en la primera pestaña, volvemos a ella en lugar de salir
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_getTitle(), style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.purple[700],
        ),
        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: Colors.purple[700],
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pets),
              label: 'Mascotas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Match',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: 'Chat',
            ),
          ],
        ),
      ),
    );
  }
  
  // Obtener el título según la pestaña actual
  String _getTitle() {
    switch (_currentIndex) {
      case 0: return 'Home';
      case 1: return 'Mis Mascotas';
      case 2: return 'Match';
      case 3: return 'Chat';
      default: return 'PetConnect';
    }
  }
}

// Componentes de contenido para cada sección
class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets,
            size: 100,
            color: Colors.purple[700],
          ),
          const SizedBox(height: 20),
          Text(
            'Bienvenido a PetConnect',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.purple[700],
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Conecta con otras mascotas y encuentra el compañero perfecto para tu mascota',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MascotasContent extends StatelessWidget {
  const MascotasContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3, // Ejemplo con 3 mascotas
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
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navegar a detalles de la mascota
            },
          ),
        );
      },
    );
  }
}

class MatchContent extends StatelessWidget {
  const MatchContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sección de Tarjetas de Mascotas
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      'https://via.placeholder.com/400x500',
                      height: double.infinity,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(15),
                          bottomRight: Radius.circular(15),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Rocky, 3',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Labrador • 5 km de distancia',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
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
        ),
        
        // Botones de acción
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                context,
                Icons.close,
                Colors.red,
                () {},
              ),
              _buildActionButton(
                context,
                Icons.favorite,
                Colors.purple,
                () {},
                size: 70,
              ),
              _buildActionButton(
                context,
                Icons.star,
                Colors.blue,
                () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    Color color,
    VoidCallback onPressed, {
    double size = 60,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }
}

class ChatContent extends StatelessWidget {
  const ChatContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 5, // Ejemplo con 5 chats
      itemBuilder: (context, index) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.purple[100],
            child: Text('U${index + 1}', style: TextStyle(color: Colors.purple[700])),
          ),
          title: Text('Usuario ${index + 1}'),
          subtitle: Text('Último mensaje...'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('12:30', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 5),
              if (index % 2 == 0) // Algunos chats con mensajes no leídos
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.purple[700],
                    shape: BoxShape.circle,
                  ),
                  child: const Text('2', style: TextStyle(color: Colors.white, fontSize: 10)),
                ),
            ],
          ),
          onTap: () {
            // Navegar a la conversación
          },
        );
      },
    );
  }
}