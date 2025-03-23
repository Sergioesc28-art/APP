import 'package:go_router/go_router.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/mascotas.dart';
import 'screens/chat.dart';
import 'screens/match.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => RegistroScreen()),
    GoRoute(path: '/home', builder: (context, state) => HomeScreen()),
    GoRoute(path: '/mascotas', builder: (context, state) => MascotasScreen()),
    GoRoute(path: '/chat', builder: (context, state) => ChatScreen()),
    GoRoute(path: '/match', builder: (context, state) => MatchScreen()),
  ],
  redirect: (context, state) {
    // Aquí puedes implementar redirecciones basadas en la autenticación
    // Por ejemplo, redirigir a login si no está autenticado
    return null;
  },
);