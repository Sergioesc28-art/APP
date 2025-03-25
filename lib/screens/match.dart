import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mascotas.dart'; // Importa MascotasScreen
import 'home_screen.dart'; // Importa HomeScreen
import 'chat.dart'; // Importa ChatScreen

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  _MatchScreenState createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;
  String _userId = '';
  List<Map<String, dynamic>> _myMatches = [];
  List<Map<String, dynamic>> _myLikes = [];
  List<Map<String, dynamic>> _likesReceived = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId != null) {
        setState(() {
          _userId = userId;
        });
        await _loadMatches();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: ${e.toString()}')),
      );
    }
  }

  Future<void> _loadMatches() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Primero, obtenemos todas las mascotas del usuario
      final mascotas = await _supabase
          .from('mascotas')
          .select('id')
          .eq('id_usuario', _userId);

      List<String> mascotaIds = [];
      for (var mascota in mascotas) {
        mascotaIds.add(mascota['id']);
      }

      if (mascotaIds.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 2. Obtener matches (cuando ambos se han dado like)
      final matches = await _supabase
          .from('matches')
          .select('''
            id, mascota_id, mascota_match_id, estado, fecha_match,
            match_mascota:mascotas!mascota_match_id(id, nombre, edad, raza, sexo, fotos, comportamiento)
          ''')
          .inFilter('mascota_id', mascotaIds)
          .eq('estado', 'matched');

      // 3. Obtener likes enviados (pero aún no han hecho match)
      final likes = await _supabase
          .from('matches')
          .select('''
            id, mascota_id, mascota_match_id, estado, fecha_match,
            match_mascota:mascotas!mascota_match_id(id, nombre, edad, raza, sexo, fotos, comportamiento)
          ''')
          .inFilter('mascota_id', mascotaIds)
          .eq('estado', 'liked');

      // 4. Obtener likes recibidos (mascotas que han dado like a las nuestras)
      final likesRecibidos = await _supabase
          .from('matches')
          .select('''
            id, mascota_id, mascota_match_id, estado, fecha_match,
            mascota_origen:mascotas!mascota_id(id, nombre, edad, raza, sexo, fotos, comportamiento)
          ''')
          .inFilter('mascota_match_id', mascotaIds)
          .eq('estado', 'liked');

      setState(() {
        _myMatches = List<Map<String, dynamic>>.from(matches);
        _myLikes = List<Map<String, dynamic>>.from(likes);
        _likesReceived = List<Map<String, dynamic>>.from(likesRecibidos);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar matches: ${e.toString()}')),
      );
    }
  }

  Future<void> _acceptMatch(String matchId, String mascotaId, String mascotaMatchId) async {
    try {
      // Actualizar el estado del match a "matched"
      await _supabase
          .from('matches')
          .update({'estado': 'matched'})
          .eq('id', matchId);

      // Crear notificación para el dueño de la mascota que dio like
      final mascotaInfo = await _supabase
          .from('mascotas')
          .select('id_usuario, nombre')
          .eq('id', mascotaId)
          .single();

      await _supabase
          .from('notificaciones')
          .insert({
            'usuario_id': mascotaInfo['id_usuario'],
            'tipo': 'match',
            'contenido': '¡Has hecho match con una mascota!',
            'referencia_id': matchId,
          });

      // Recargar los datos
      await _loadMatches();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('¡Match aceptado!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al aceptar match: ${e.toString()}')),
      );
    }
  }

  Future<void> _rejectMatch(String matchId) async {
    try {
      await _supabase
          .from('matches')
          .update({'estado': 'rejected'})
          .eq('id', matchId);

      // Recargar los datos
      await _loadMatches();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Match rechazado')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al rechazar match: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Matches',
          style: TextStyle(
            fontSize: 24,
            color: Colors.brown[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.brown[700],
          labelColor: Colors.brown[700],
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: 'Matches'),
            Tab(text: 'Me gustan'),
            Tab(text: 'Les gusto'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Matches
                _buildMatchesTab(),
                // Tab 2: Me gustan
                _buildLikesTab(),
                // Tab 3: Les gusto
                _buildLikesReceivedTab(),
              ],
            ),
      backgroundColor: Color(0xFFF9F6E8),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: Colors.brown[700],
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
              break;
            case 1:
              // Ya estamos en MatchScreen
              break;
            case 2:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ChatScreen()));
              break;
            case 3:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MascotasScreen()));
              break;
          }
        },
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

  Widget _buildMatchesTab() {
    if (_myMatches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 20),
            Text(
              'Aún no tienes matches',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 10),
            Text(
              '¡Haz swipe en más perfiles para encontrar amigos para tu mascota!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              maxLines: 2,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(10),
      itemCount: _myMatches.length,
      itemBuilder: (context, index) {
        final match = _myMatches[index];
        final matchMascota = match['match_mascota'];
        
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 3,
          child: ListTile(
            contentPadding: EdgeInsets.all(12),
            leading: CircleAvatar(
              radius: 30,
              backgroundImage: matchMascota['fotos'] != null && matchMascota['fotos'].isNotEmpty
                ? MemoryImage(base64Decode(matchMascota['fotos'][0].split(',').last))
                : null,
              child: matchMascota['fotos'] == null || matchMascota['fotos'].isEmpty
                  ? Icon(Icons.pets, size: 30, color: Colors.grey[400])
                  : null,
            ),
            title: Text(
              matchMascota['nombre'] ?? 'Sin nombre',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              '${matchMascota['raza']} • ${matchMascota['edad']} años',
              style: TextStyle(fontSize: 14),
            ),
            trailing: Icon(Icons.pets_outlined, color: Colors.brown[700]),
          ),
        );
      },
    );
  }

  Widget _buildLikesTab() {
    if (_myLikes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.thumb_up_alt_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 20),
            Text(
              'Aún no has dado like a ninguna mascota',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Explora perfiles y da like a las mascotas que te interesen',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              maxLines: 2,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(10),
      itemCount: _myLikes.length,
      itemBuilder: (context, index) {
        final like = _myLikes[index];
        final likedMascota = like['match_mascota'];
        
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 3,
          child: ListTile(
            contentPadding: EdgeInsets.all(12),
            leading: CircleAvatar(
              radius: 30,
              backgroundImage: likedMascota['fotos'] != null && likedMascota['fotos'].isNotEmpty
                  ? MemoryImage(base64Decode(likedMascota['fotos'][0].split(',').last))
                  : null,
              child: likedMascota['fotos'] == null || likedMascota['fotos'].isEmpty
                  ? Icon(Icons.pets, size: 30, color: Colors.grey[400])
                  : null,
            ),
            title: Text(
              likedMascota['nombre'] ?? 'Sin nombre',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              '${likedMascota['raza']} • ${likedMascota['edad']} años',
              style: TextStyle(fontSize: 14),
            ),
            trailing: Icon(Icons.favorite, color: Colors.pink[300]),
          ),
        );
      },
    );
  }

  Widget _buildLikesReceivedTab() {
    if (_likesReceived.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 20),
            Text(
              'Aún no has recibido likes',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 10),
            Text(
              '¡Sigue participando en la comunidad y pronto recibirás likes!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              maxLines: 2,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(10),
      itemCount: _likesReceived.length,
      itemBuilder: (context, index) {
        final like = _likesReceived[index];
        final mascotaOrigen = like['mascota_origen'];
        
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 3,
          child: ListTile(
            contentPadding: EdgeInsets.all(12),
            leading: CircleAvatar(
              radius: 30,
              backgroundImage: mascotaOrigen['fotos'] != null && mascotaOrigen['fotos'].isNotEmpty
                  ? MemoryImage(base64Decode(mascotaOrigen['fotos'][0].split(',').last))
                  : null,
              child: mascotaOrigen['fotos'] == null || mascotaOrigen['fotos'].isEmpty
                  ? Icon(Icons.pets, size: 30, color: Colors.grey[400])
                  : null,
            ),
            title: Text(
              mascotaOrigen['nombre'] ?? 'Sin nombre',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              '${mascotaOrigen['raza']} • ${mascotaOrigen['edad']} años',
              style: TextStyle(fontSize: 14),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.check_circle, color: Colors.green),
                  onPressed: () => _acceptMatch(like['id'], like['mascota_id'], like['mascota_match_id']),
                ),
                IconButton(
                  icon: Icon(Icons.cancel, color: Colors.red),
                  onPressed: () => _rejectMatch(like['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}