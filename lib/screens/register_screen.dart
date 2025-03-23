import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'terms_conditions.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  _RegistroScreenState createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final TextEditingController _nombreCompletoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _supabase = Supabase.instance.client;
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isPasswordValid = false;
  bool _isPasswordMatching = false;
  bool _isLoading = false;
  bool _isTermsAccepted = false;

  final FocusNode _passwordFocusNode = FocusNode();

  final emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  final passwordPattern = r'^(?=.*[0-9])(?=.*[!@#\$&*~]).{6,}$'; // Al menos 6 caracteres, un número y un carácter especial

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(() {
      if (_passwordFocusNode.hasFocus) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('La contraseña debe tener al menos 6 caracteres, un número y un carácter especial'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _validatePassword(String password) {
    setState(() {
      _isPasswordValid = RegExp(passwordPattern).hasMatch(password);
      _isPasswordMatching = password == _confirmPasswordController.text;
    });
  }

  void _validateConfirmPassword(String confirmPassword) {
    setState(() {
      _isPasswordMatching = confirmPassword == _passwordController.text;
    });
  }

  Future<void> _register() async {
    if (_nombreCompletoController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, completa todos los campos')),
      );
      return;
    }

    if (!RegExp(emailPattern).hasMatch(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, ingresa un correo electrónico válido')),
      );
      return;
    }

    if (!_isPasswordValid || !_isPasswordMatching) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres, un número y un carácter especial')),
      );
      return;
    }

    if (!_isTermsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Debes aceptar los términos y condiciones')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _showLoadingDialog();

    try {
      // Registrar usuario en Supabase Auth
      final response = await _supabase.auth.signUp(
        email: _emailController.text,
        password: _passwordController.text,
      );
      
      if (response.user != null) {
        // Insertar datos en la tabla usuarios de Supabase
        await _supabase.from('usuarios').insert({
          'id': response.user!.id,
          'nombre_completo': _nombreCompletoController.text,
          'email': _emailController.text,
          'contraseña': _passwordController.text, // Nota: Supabase Auth ya almacena de forma segura la contraseña
          'role': 'usuario', // Rol predeterminado
        });

        // Cerrar sesión después del registro para que el usuario inicie sesión manualmente
        await _supabase.auth.signOut();

        Navigator.of(context).pop(); // Cerrar el cuadro de diálogo de carga

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registro exitoso. Por favor inicia sesión.')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } else {
        throw Exception('No se pudo registrar el usuario');
      }
    } on AuthException catch (e) {
      Navigator.of(context).pop(); // Cerrar el cuadro de diálogo de carga
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de registro: ${e.message}')),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Cerrar el cuadro de diálogo de carga
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de registro: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
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
              // Registro Card
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Crear cuenta',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[700],
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _nombreCompletoController,
                      maxLength: 30,
                      decoration: InputDecoration(
                        labelText: 'Nombre Completo',
                        border: UnderlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _emailController,
                      maxLength: 50,
                      decoration: InputDecoration(
                        labelText: 'E-mail',
                        border: UnderlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      obscureText: !_isPasswordVisible,
                      maxLength: 20,
                      onChanged: _validatePassword,
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
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: !_isConfirmPasswordVisible,
                      onChanged: _validateConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirmar Contraseña',
                        border: UnderlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Checkbox(
                          value: _isTermsAccepted,
                          activeColor: Colors.brown[300],
                          onChanged: (bool? value) {
                            setState(() {
                              _isTermsAccepted = value ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => TermsConditionsScreen()),
                              );
                            },
                            child: Text(
                              'Acepto los términos y condiciones',
                              style: TextStyle(
                                color: Colors.brown[700],
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isTermsAccepted ? _register : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown[300],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: Text(
                        'Registrarse',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              // Login Option
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      text: '¿Ya tienes una cuenta? ',
                      style: TextStyle(color: Colors.black),
                      children: [
                        TextSpan(
                          text: 'Inicia sesión',
                          style: TextStyle(
                            color: Colors.brown[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}