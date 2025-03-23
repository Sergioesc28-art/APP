import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _loadUserId().then((_) => _loadNotifications());
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId != null) {
      setState(() {
        _userId = userId;
      });
    } else {
      // Si no hay usuario, redirigir al login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _loadNotifications() async {
    if (_userId.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Just fetch notifications without trying to join with mascotas
      final response = await _supabase
          .from('notificaciones')
          .select('*')
          .eq('usuario_id', _userId)
          .order('fecha', ascending: false);

      setState(() {
        _notifications = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });

      // Marcar todas las notificaciones como leídas
      await _markAllAsRead();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar notificaciones: ${e.toString()}')),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _supabase
          .from('notificaciones')
          .update({'leido': true})
          .eq('usuario_id', _userId)
          .eq('leido', false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al marcar notificaciones como leídas: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('notificaciones')
          .delete()
          .eq('id', notificationId);
      
      setState(() {
        _notifications.removeWhere((notification) => notification['id'] == notificationId);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notificación eliminada')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar notificación: ${e.toString()}')),
      );
    }
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final DateTime fecha = DateTime.parse(notification['fecha']);
    final String fechaFormateada = DateFormat('dd/MM/yyyy HH:mm').format(fecha);
    
    IconData iconData;
    Color iconColor;
    
    switch (notification['tipo']) {
      case 'match':
        iconData = Icons.favorite;
        iconColor = Colors.red;
        break;
      case 'mensaje':
        iconData = Icons.chat;
        iconColor = Colors.blue;
        break;
      case 'sistema':
      default:
        iconData = Icons.notifications;
        iconColor = Colors.amber;
        break;
    }

    return Dismissible(
      key: Key(notification['id']),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _deleteNotification(notification['id']);
      },
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 3,
        child: ListTile(
          contentPadding: EdgeInsets.all(12),
          leading: CircleAvatar(
            backgroundColor: iconColor.withOpacity(0.2),
            child: Icon(iconData, color: iconColor),
          ),
          title: Text(
            _getNotificationTitle(notification),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 5),
              Text(
                notification['contenido'],
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 5),
              Text(
                fechaFormateada,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          isThreeLine: true,
          onTap: () {
            // Aquí podríamos navegar a la pantalla correspondiente según el tipo de notificación
            _handleNotificationTap(notification);
          },
        ),
      ),
    );
  }

  String _getNotificationTitle(Map<String, dynamic> notification) {
    switch (notification['tipo']) {
      case 'match':
        return '¡Nuevo Match!';
      case 'mensaje':
        return 'Nuevo mensaje';
      case 'sistema':
        return 'Notificación del sistema';
      default:
        return 'Notificación';
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    switch (notification['tipo']) {
      case 'match':
        if (notification['referencia_id'] != null) {
          // Navegar a la pantalla de match con el ID de referencia
          // Navigator.push(context, MaterialPageRoute(builder: (context) => MatchDetailScreen(matchId: notification['referencia_id'])));
        }
        break;
      case 'mensaje':
        if (notification['referencia_id'] != null) {
          // Navegar a la conversación específica
          // Navigator.push(context, MaterialPageRoute(builder: (context) => ConversationScreen(conversationId: notification['referencia_id'])));
        }
        break;
      case 'sistema':
      default:
        // Mostrar detalles en un diálogo para notificaciones del sistema
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(_getNotificationTitle(notification)),
              content: Text(notification['contenido']),
              actions: [
                TextButton(
                  child: Text('Cerrar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Notificaciones',
          style: TextStyle(
            fontSize: 20,
            color: Colors.brown[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.brown[700]),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.brown[700]),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyNotifications()
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationItem(_notifications[index]);
                    },
                  ),
                ),
      backgroundColor: Color(0xFFF9F6E8),
    );
  }

  Widget _buildEmptyNotifications() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 20),
          Text(
            'No tienes notificaciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Te notificaremos cuando haya actividad nueva',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}