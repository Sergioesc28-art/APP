import 'package:dogzline/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';
// Import other screen files
import 'screens/mascotas.dart';
import 'screens/chat.dart';
import 'screens/match.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa Supabase
  await Supabase.initialize(
    url: 'https://wtxjocqptmghpkuddpwp.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind0eGpvY3FwdG1naHBrdWRkcHdwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIzMzY2NjAsImV4cCI6MjA1NzkxMjY2MH0.gWEpbK7OkhfDDRjxkVfNI6ZYwjmGyCq34oapbqotB_8',
  );
  
   // Inicializa Stripe
  Stripe.publishableKey = 'tu_clave_publica_de_stripe';
  await Stripe.instance.applySettings();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData.light(), // Tema claro por defecto
            darkTheme: ThemeData.dark(), // Tema oscuro
            themeMode: themeProvider.themeMode, // Usa el tema del proveedor
            // Use routes for navigation
            initialRoute: '/',
            routes: {
              '/': (context) => AuthStateHandler(),
              '/login': (context) => LoginScreen(),
              '/mascotas': (context) => MascotasScreen(),
              '/chat': (context) => ChatScreen(),
              '/match': (context) => MatchScreen(),
            },
            // Handle unknown routes
            onUnknownRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => Scaffold(
                  body: Center(
                    child: Text('Ruta no encontrada: ${settings.name}'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AuthStateHandler extends StatefulWidget {
  const AuthStateHandler({super.key});

  @override
  _AuthStateHandlerState createState() => _AuthStateHandlerState();
}

class _AuthStateHandlerState extends State<AuthStateHandler> {
  final _supabase = Supabase.instance.client;
  User? _currentUser;
  
  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
    
    // Escuchar cambios en el estado de autenticación
    _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      setState(() {
        _currentUser = session?.user;
      });
    });
  }
  
  Future<void> _checkCurrentUser() async {
    final session = _supabase.auth.currentSession;
    setState(() {
      _currentUser = session?.user;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // Instead of directly returning screens, use Navigator
    if (_currentUser == null) {
      // Redirect to login if not authenticated
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return Container(); // Return empty container while redirecting
    } else {
      return HomeScreen();
    }
  }
}