import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatDetailScreen extends StatefulWidget {
  final String conversacionId;
  final String matchId;
  final String userId;
  final Map<String, dynamic> otraMascota;
  final Map<String, dynamic> miMascota;
  final VoidCallback? onNewMessage;

  const ChatDetailScreen({
    super.key,
    required this.conversacionId,
    required this.matchId,
    required this.userId,
    required this.otraMascota,
    required this.miMascota,
    this.onNewMessage,
  });

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<List<Map<String, dynamic>>> _mensajes = ValueNotifier<List<Map<String, dynamic>>>([]);
  bool _isLoading = true;
  bool _isSending = false;
  late RealtimeChannel _mensajesChannel;

  @override
  void initState() {
    super.initState();
    _loadMensajes();
    _setupRealtimeSubscription();
  }

  void _setupRealtimeSubscription() {
    // Create a realtime channel for the specific conversation
    _mensajesChannel = _supabase.channel('mensajes:${widget.conversacionId}');

    // Subscribe to INSERT events on the 'mensajes' table with a filter
    _mensajesChannel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'mensajes',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'conversacion_id',
        value: widget.conversacionId,
      ),
      callback: (payload) {
        // Access the new record using payload.newRecord
        final newRecord = payload.newRecord;
        _addMessageToList(newRecord);

        // Mark the message as read if it's from the other user
        if (newRecord['emisor_id'] != widget.userId) {
          _marcarMensajeComoLeido(newRecord['id']);
        }

        // Notify the chat screen to update
        if (widget.onNewMessage != null) {
          widget.onNewMessage!();
        }
      },
    ).subscribe();
  }

  void _addMessageToList(Map<String, dynamic> message) {
    final currentList = List<Map<String, dynamic>>.from(_mensajes.value);
    
    // Verificar si el mensaje ya existe en la lista para evitar duplicados
    if (!currentList.any((m) => m['id'] == message['id'])) {
      currentList.add(message);
      currentList.sort((a, b) => 
        DateTime.parse(a['fecha_envio']).compareTo(DateTime.parse(b['fecha_envio'])));
      
      _mensajes.value = currentList;
      
      // Hacer scroll al último mensaje
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
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

      _mensajes.value = List<Map<String, dynamic>>.from(mensajes);
      
      // Marcar todos los mensajes no leídos como leídos
      _marcarTodosMensajesComoLeidos();
      
      // Scroll al último mensaje
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar mensajes: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _marcarMensajeComoLeido(String messageId) async {
    try {
      await _supabase
          .from('mensajes')
          .update({'leido': true})
          .eq('id', messageId);
    } catch (e) {
      print('Error al marcar mensaje como leído: ${e.toString()}');
    }
  }

  Future<void> _marcarTodosMensajesComoLeidos() async {
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
      final now = DateTime.now().toIso8601String();
      
      // Crear un mensaje temporal optimista para mostrar inmediatamente
      final tempMessage = {
        'id': 'temp_$now',
        'conversacion_id': widget.conversacionId,
        'emisor_id': widget.userId,
        'contenido': mensaje,
        'fecha_envio': now,
        'leido': false,
        '_isTemp': true,
      };
      
      // Agregar mensaje temporal a la UI
      _addMessageToList(tempMessage);
      
      // Limpiar input inmediatamente
      _messageController.clear();
      
      // Enviar mensaje a la base de datos
      final response = await _supabase.from('mensajes').insert({
        'conversacion_id': widget.conversacionId,
        'emisor_id': widget.userId,
        'contenido': mensaje,
      }).select().single();

      // Actualizar la tabla de conversaciones
      await _supabase
          .from('conversaciones')
          .update({'ultima_actividad': now})
          .eq('id', widget.conversacionId);
          
      // Eliminar mensaje temporal y agregar el real (esto se manejará por el listener)
      final messages = List<Map<String, dynamic>>.from(_mensajes.value);
      messages.removeWhere((m) => m['id'] == 'temp_$now');
      _mensajes.value = messages;
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
            _buildAvatarImage(widget.otraMascota['fotos'], radius: 20),
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
                : ValueListenableBuilder<List<Map<String, dynamic>>>(
                    valueListenable: _mensajes,
                    builder: (context, mensajes, _) {
                      if (mensajes.isEmpty) {
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
                        itemCount: mensajes.length,
                        itemBuilder: (context, index) {
                          final mensaje = mensajes[index];
                          final bool esMiMensaje = mensaje['emisor_id'] == widget.userId;
                          final bool isTemp = mensaje['_isTemp'] == true;

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
                                  color: esMiMensaje 
                                      ? (isTemp ? Colors.brown[50] : Colors.brown[100]) 
                                      : Colors.white,
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
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _formatMessageTime(mensaje['fecha_envio']),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        if (esMiMensaje) SizedBox(width: 4),
                                        if (esMiMensaje && isTemp)
                                          Icon(Icons.access_time, size: 12, color: Colors.grey)
                                        else if (esMiMensaje)
                                          Icon(
                                            mensaje['leido'] == true 
                                                ? Icons.done_all 
                                                : Icons.done,
                                            size: 12,
                                            color: mensaje['leido'] == true 
                                                ? Colors.blue 
                                                : Colors.grey,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
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
                    onSubmitted: (_) => _enviarMensaje(),
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

  Widget _buildAvatarImage(dynamic fotos, {double radius = 30}) {
    if (fotos != null && fotos.isNotEmpty) {
      try {
        final String base64Image = fotos[0].split(',').last;
        return CircleAvatar(
          radius: radius,
          backgroundImage: MemoryImage(base64Decode(base64Image)),
        );
      } catch (e) {
        return CircleAvatar(
          radius: radius,
          child: Icon(Icons.pets, size: radius, color: Colors.grey[400]),
        );
      }
    }
    
    return CircleAvatar(
      radius: radius,
      child: Icon(Icons.pets, size: radius, color: Colors.grey[400]),
    );
  }

  @override
  void dispose() {
    _mensajesChannel.unsubscribe();
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}