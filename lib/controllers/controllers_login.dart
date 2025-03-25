import 'package:dogzline/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart'; // Para Provider

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  final emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      _showLoadingDialog();
      try {
        // Iniciar sesión con Supabase
        final response = await _supabase.auth.signInWithPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        // Verificar si la sesión se ha iniciado correctamente
        if (response.session != null) {
          // Obtener el ID del usuario
          final userId = response.user!.id;
          
          // Obtener datos del usuario desde la tabla usuarios
          final userData = await _supabase
              .from('usuarios')
              .select()
              .eq('id', userId)
              .single();

          // Guardar información en SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', userId);
          await prefs.setString('token', response.session!.accessToken);
          await prefs.setString('NombreCompleto', userData['nombre_completo'] ?? '');
          await prefs.setString('email', response.user!.email ?? '');

          // Cerrar el diálogo de carga y navegar a la pantalla de perfil
          if (mounted) {
            Navigator.of(context).pop();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          }
        } else {
          throw Exception('No se pudo iniciar sesión');
        }
      } on AuthException catch (e) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error de autenticación: ${e.message}')),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Correo electrónico o contraseña incorrectos')),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutterquickstart://login-callback/',
      );
      
      // Nota: La redirección y el manejo de la sesión después del inicio de sesión con Google
      // se manejan mediante el Deep Link configurado en la aplicación
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar sesión con Google: ${e.toString()}')),
      );
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Stack(
          children: [
            Opacity(
              opacity: 0.3,
              child: ModalBarrier(dismissible: false, color: Colors.black),
            ),
            Center(
              child: Image.asset(
                'assets/Dise-o-sin-t-tulo-unscreen.gif',
                width: 300,
                height: 300,
                fit: BoxFit.contain,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F2DE), // Fondo beige
      body: Center(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo y título
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage('assets/Logo_dogzline.png'),
                        backgroundColor: Colors.transparent,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Dogzline',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown[700],
                        ),
                      ),
                      Text(
                        'Encuentra. Conoce. Conecta.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.brown[400],
                        ),
                      ),
                    ],
                  ),
                ),
                // Tarjeta de Login
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
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
                        'Iniciar cuenta',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown[700],
                        ),
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _emailController,
                        maxLength: 25,
                        decoration: InputDecoration(
                          labelText: 'E-mail',
                          border: UnderlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, ingresa tu correo electrónico';
                          }
                          if (!RegExp(emailPattern).hasMatch(value)) {
                            return 'Por favor, ingresa un correo electrónico válido';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        maxLength: 20,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          border: UnderlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, ingresa tu contraseña';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: _isLoading ? Colors.grey[400] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            minimumSize: Size(double.infinity, 50),
                          ),
                          child: _isLoading
                              ? CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                )
                              : Text(
                                  'Iniciar sesión',
                                  style: TextStyle(fontSize: 16, color: Colors.black),
                                ),
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _signInWithGoogle,
                        child: Text('Iniciar sesión con Google'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          minimumSize: Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Opción para registrarse
                // Padding(
                //   padding: const EdgeInsets.only(top: 20),
                //   child: TextButton(
                //     onPressed: () {
                //       Navigator.push(
                //         context,
                //         MaterialPageRoute(builder: (context) => RegisterScreen()),
                //       );
                //     },
                //     child: RichText(
                //       text: TextSpan(
                //         text: '¿No tienes una cuenta? ',
                //         style: TextStyle(color: Colors.black),
                //         children: [
                //           TextSpan(
                //             text: 'Registrarse',
                //             style: TextStyle(
                //               color: Colors.brown[700],
                //               fontWeight: FontWeight.bold,
                //             ),
                //           ),
                //         ],
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}