import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _supabase = Supabase.instance.client;
  String _userId = '';
  List<Map<String, dynamic>> _conversaciones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
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
        await _loadConversaciones();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: ${e.toString()}')),
      );
    }
  }

  Future<void> _loadConversaciones() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Obtener todas las mascotas del usuario
      final mascotas = await _supabase
          .from('mascotas')
          .select('id')
          .eq('id_usuario', _userId);

      if (mascotas.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      List<String> mascotaIds = [];
      for (var mascota in mascotas) {
        mascotaIds.add(mascota['id']);
      }

      // 2. Obtener todos los matches donde participan estas mascotas
      final matches = await _supabase
          .from('matches')
          .select('id, mascota_id, mascota_match_id, estado')
          .or('mascota_id.in.(${mascotaIds.join(",")}),mascota_match_id.in.(${mascotaIds.join(",")})')
          .eq('estado', 'matched');

      if (matches.isEmpty) {
        setState(() {
          _isLoading = false;
          _conversaciones = [];
        });
        return;
      }

      List<String> matchIds = [];
      for (var match in matches) {
        matchIds.add(match['id']);
      }

      // 3. Obtener conversaciones con la última actividad y último mensaje
      final conversaciones = await _supabase
          .from('conversaciones')
          .select('''
            id, match_id, fecha_creacion, ultima_actividad, activo,
            match:matches!match_id(
              id, 
              mascota_origen:mascotas!mascota_id(id, nombre, fotos, id_usuario),
              mascota_destino:mascotas!mascota_match_id(id, nombre, fotos, id_usuario)
            )
          ''')
          .inFilter('match_id', matchIds)
          .eq('activo', true)
          .order('ultima_actividad', ascending: false);

      // 4. Para cada conversación, obtenemos el último mensaje
      List<Map<String, dynamic>> conversacionesConMensajes = [];
      for (var conversacion in conversaciones) {
        final ultimoMensaje = await _supabase
            .from('mensajes')
            .select('id, contenido, fecha_envio, emisor_id, leido')
            .eq('conversacion_id', conversacion['id'])
            .order('fecha_envio', ascending: false)
            .limit(1)
            .maybeSingle();

        // 5. Contar mensajes no leídos
        final noLeidosResponse = await _supabase
          .from('mensajes')
          .select('id')
          .eq('conversacion_id', conversacion['id'])
          .eq('leido', false)
          .neq('emisor_id', _userId);

      final noLeidos = noLeidosResponse.length; // Get count from response length

        // Determinar qué mascota pertenece al usuario actual y cuál al otro usuario
        final mascotaOrigen = conversacion['match']['mascota_origen'];
        final mascotaDestino = conversacion['match']['mascota_destino'];

        Map<String, dynamic> miMascota, otraMascota;
        
        if (mascotaOrigen['id_usuario'] == _userId) {
          miMascota = mascotaOrigen;
          otraMascota = mascotaDestino;
        } else {
          miMascota = mascotaDestino;
          otraMascota = mascotaOrigen;
        }

        // Añadir la conversación con toda la información
        conversacionesConMensajes.add({
          ...conversacion,
          'ultimo_mensaje': ultimoMensaje,
          'no_leidos': noLeidos,
          'mi_mascota': miMascota,
          'otra_mascota': otraMascota
        });
      }

      setState(() {
        _conversaciones = conversacionesConMensajes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar conversaciones: ${e.toString()}')),
      );
    }
  }

  String _formatDate(String dateString) {
    try {
      final now = DateTime.now();
      final date = DateTime.parse(dateString);
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        // Hoy, mostrar la hora
        return DateFormat('HH:mm').format(date);
      } else if (difference.inDays == 1) {
        // Ayer
        return 'Ayer';
      } else if (difference.inDays < 7) {
        // Esta semana, mostrar el día
        return DateFormat('EEEE').format(date);
      } else {
        // Más de una semana, mostrar fecha
        return DateFormat('dd/MM/yyyy').format(date);
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
  title: Text(
    'Chats',
    style: TextStyle(
      fontSize: 24,
      color: Colors.brown[700],
      fontWeight: FontWeight.bold, // Añade esta línea para hacer el texto más grueso
    ),
  ),
  backgroundColor: Colors.white,
  elevation: 0,
),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.brown[700]))
          : _buildConversacionesList(),
      backgroundColor: Color(0xFFF9F6E8),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: Colors.brown[700],
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          Navigator.pushReplacementNamed(
            context, 
            index == 0 ? '/' : index == 1 ? '/match' : index == 3 ? '/mascotas' : '/chat'
          );
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

  Widget _buildConversacionesList() {
    if (_conversaciones.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 20),
            Text(
              'Aún no tienes conversaciones',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Haz match con otras mascotas para comenzar a chatear',
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
      itemCount: _conversaciones.length,
      itemBuilder: (context, index) {
        final conv = _conversaciones[index];
        final otraMascota = conv['otra_mascota'];
        final ultimoMensaje = conv['ultimo_mensaje'];
        final noLeidos = conv['no_leidos'];
        
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
              backgroundImage: otraMascota['fotos'] != null && otraMascota['fotos'].isNotEmpty
                  ? MemoryImage(base64Decode(otraMascota['fotos'][0].split(',').last))
                  : null,
              child: otraMascota['fotos'] == null || otraMascota['fotos'].isEmpty
                  ? Icon(Icons.pets, size: 30, color: Colors.grey[400])
                  : null,
            ),
            title: Text(
              otraMascota['nombre'] ?? 'Sin nombre',
              style: TextStyle(
                fontWeight: noLeidos > 0 ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
            subtitle: ultimoMensaje != null
                ? Text(
                    ultimoMensaje['contenido'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: noLeidos > 0 ? FontWeight.bold : FontWeight.normal,
                      color: noLeidos > 0 ? Colors.black87 : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : Text(
                    'Comienza la conversación',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (ultimoMensaje != null)
                  Text(
                    _formatDate(ultimoMensaje['fecha_envio']),
                    style: TextStyle(
                      fontSize: 12,
                      color: noLeidos > 0 ? Colors.brown[700] : Colors.grey,
                    ),
                  ),
                SizedBox(height: 5),
                if (noLeidos > 0)
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.brown[700],
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      noLeidos.toString(),
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatDetailScreen(
                    conversacionId: conv['id'],
                    matchId: conv['match_id'],
                    userId: _userId,
                    otraMascota: otraMascota,
                    miMascota: conv['mi_mascota'],
                  ),
                ),
              ).then((_) => _loadConversaciones());
            },
          ),
        );
      },
    );
  }
}

class ChatDetailScreen extends StatefulWidget {
  final String conversacionId;
  final String matchId;
  final String userId;
  final Map<String, dynamic> otraMascota;
  final Map<String, dynamic> miMascota;

  const ChatDetailScreen({
    super.key,
    required this.conversacionId,
    required this.matchId,
    required this.userId,
    required this.otraMascota,
    required this.miMascota,
  });

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> _mensajes = [];
  bool _isLoading = true;
  bool _isSending = false;
  late Stream<List<Map<String, dynamic>>> _mensajesStream;
  final ScrollController _scrollController = ScrollController();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadMensajes();
    _marcarMensajesComoLeidos();
    _configurarActualizacionAutomatica();
  }

  void _configurarActualizacionAutomatica() {
    // Configurar temporizador para actualizar mensajes cada 3 segundos
    _refreshTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      _marcarMensajesComoLeidos();
      _actualizarMensajes();
    });

    // Configurar stream para escuchar cambios en tiempo real
    _mensajesStream = _supabase
        .from('mensajes')
        .stream(primaryKey: ['id'])
        .eq('conversacion_id', widget.conversacionId)
        .order('fecha_envio', ascending: true);
  }

  Future<void> _actualizarMensajes() async {
    try {
      final mensajes = await _supabase
          .from('mensajes')
          .select('*')
          .eq('conversacion_id', widget.conversacionId)
          .order('fecha_envio', ascending: true);

      setState(() {
        _mensajes = List<Map<String, dynamic>>.from(mensajes);
      });

      // Desplazar hacia abajo cuando haya nuevos mensajes
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      print('Error al actualizar mensajes: ${e.toString()}');
    }
  }

  Future<void> _loadMensajes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final mensajes = await _supabase
          .from('mensajes')
          .select('*')
          .eq('conversacion_id', widget.conversacionId)
          .order('fecha_envio', ascending: true);

      setState(() {
        _mensajes = List<Map<String, dynamic>>.from(mensajes);
        _isLoading = false;
      });

      // Desplazar hacia abajo al cargar inicialmente los mensajes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar mensajes: ${e.toString()}')),
      );
    }
  }

  Future<void> _marcarMensajesComoLeidos() async {
    try {
      await _supabase
          .from('mensajes')
          .update({'leido': true})
          .eq('conversacion_id', widget.conversacionId)
          .neq('emisor_id', widget.userId)
          .eq('leido', false);
    } catch (e) {
      print('Error al marcar mensajes como leídos: ${e.toString()}');
    }
  }

  Future<void> _enviarMensaje() async {
    final mensaje = _messageController.text.trim();
    if (mensaje.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      // Guardar el mensaje localmente primero para mostrar instantáneamente
      final nuevoMensaje = {
        'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
        'conversacion_id': widget.conversacionId,
        'emisor_id': widget.userId,
        'contenido': mensaje,
        'fecha_envio': DateTime.now().toIso8601String(),
        'leido': false,
      };

      setState(() {
        _mensajes.add(nuevoMensaje);
      });

      // Limpiar el campo de texto inmediatamente
      _messageController.clear();
      
      // Desplazar al final para mostrar el nuevo mensaje
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      // Enviar a Supabase
      await _supabase.from('mensajes').insert({
        'conversacion_id': widget.conversacionId,
        'emisor_id': widget.userId,
        'contenido': mensaje,
      });

      // Actualizar la tabla de conversaciones
      await _supabase
          .from('conversaciones')
          .update({'ultima_actividad': DateTime.now().toIso8601String()})
          .eq('id', widget.conversacionId);

      // Actualizar mensajes para obtener el ID real del mensaje enviado
      _actualizarMensajes();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar mensaje: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  String _formatMessageTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('HH:mm').format(date);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: widget.otraMascota['fotos'] != null && 
                              widget.otraMascota['fotos'].isNotEmpty
                  ? MemoryImage(base64Decode(widget.otraMascota['fotos'][0].split(',').last))
                  : null,
              child: widget.otraMascota['fotos'] == null || 
                    widget.otraMascota['fotos'].isEmpty
                  ? Icon(Icons.pets, size: 20, color: Colors.grey[400])
                  : null,
            ),
            SizedBox(width: 10),
            Text(
              widget.otraMascota['nombre'] ?? 'Chat',
              style: TextStyle(color: Colors.brown[700]),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.brown[700]),
            onPressed: () {
              // Mostrar información sobre la mascota
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.brown[700]))
                : _buildMessageList(),
          ),
          Container(
            padding: EdgeInsets.all(8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.brown[700],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _isSending
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(Icons.send, color: Colors.white),
                    onPressed: _isSending ? null : _enviarMensaje,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: Color(0xFFF9F6E8),
    );
  }

  Widget _buildMessageList() {
    if (_mensajes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 20),
            Text(
              'No hay mensajes',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 10),
            Text(
              '¡Comienza la conversación!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(10),
      itemCount: _mensajes.length,
      itemBuilder: (context, index) {
        final mensaje = _mensajes[index];
        final bool esMiMensaje = mensaje['emisor_id'] == widget.userId;

        return Padding(
          padding: EdgeInsets.only(
            bottom: 8,
            left: esMiMensaje ? 60 : 0,
            right: esMiMensaje ? 0 : 60,
          ),
          child: Align(
            alignment: esMiMensaje ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: esMiMensaje ? Colors.brown[100] : Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    mensaje['contenido'] ?? '',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 5),
                  Text(
                    _formatMessageTime(mensaje['fecha_envio']),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}