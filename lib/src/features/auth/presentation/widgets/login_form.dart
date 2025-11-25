import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:pesca_game/src/features/auth/data/repositories/auth_repository.dart';
import 'package:pesca_game/src/features/game_menu/presentation/screens/game_menu_screen.dart';

class LoginForm extends StatefulWidget {
  final VoidCallback onRegisterPressed;
  final AudioPlayer audioPlayer;

  const LoginForm({
    super.key,
    required this.onRegisterPressed,
    required this.audioPlayer,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _login() async {
    try {
      await AuthRepository.signIn(
        username: _usernameController.text,
        password: _passwordController.text,
      );
      widget.audioPlayer.stop();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const GameMenuScreen()),
      );
    } catch (e) {
      final message = e.toString().contains('User not found')
          ? 'Usuario no encontrado'
          : 'Ocurrió un error';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      await AuthRepository.signInWithGoogle();
      widget.audioPlayer.stop();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const GameMenuScreen()),
      );
    } catch (e) {
      debugPrint('Error en Google Sign In: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ocurrió un error al iniciar sesión con Google: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 360, // ⬅️ ANCHO del formulario completo
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment
                .start, // ⬅️ Cambié de center a start para pegar arriba
            children: [
              // Contenedor con imagen completa de MaderaLogin para ambos campos
              Container(
                width: 354, // ⬅️ ANCHO original de la imagen
                height:
                    266, // ⬅️ ALTURA original de la imagen (respeta proporciones)
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage('assets/images/madera/MaderaLogin.png'),
                    fit:
                        BoxFit.contain, // ⬅️ contain para respetar proporciones
                  ),
                  borderRadius: BorderRadius.circular(
                    12,
                  ), // ⬅️ REDONDEO de esquinas
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 50, // ⬅️ MARGEN superior para bajar los campos
                    bottom: 10, // ⬅️ MARGEN inferior
                    left: 15,
                    right: 15,
                  ),
                  child: Column(
                    children: [
                      // Campo de nombre de usuario
                      Container(
                        alignment: Alignment.center, // ⬅️ Centrar contenido
                        child: TextFormField(
                          controller: _usernameController,
                          textAlign: TextAlign.center, // ⬅️ Centrar el texto
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16, // ⬅️ TAMAÑO del texto escrito
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Nombre de usuario',
                            labelStyle: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 14, // ⬅️ TAMAÑO del label
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal:
                                  20, // ⬅️ ESPACIO horizontal interno del campo
                              vertical:
                                  8, // ⬅️ ESPACIO vertical interno del campo - reducido
                            ),
                            prefixIcon: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 28, // ⬅️ TAMAÑO del icono
                            ),
                          ),
                        ),
                      ),
                      // Espacio para la cuerda central
                      const SizedBox(
                        height: 12,
                      ), // ⬅️ ESPACIO entre los dos campos - reducido
                      // Campo de contraseña
                      Container(
                        alignment: Alignment.center, // ⬅️ Centrar contenido
                        child: TextFormField(
                          controller: _passwordController,
                          textAlign: TextAlign.center, // ⬅️ Centrar el texto
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16, // ⬅️ TAMAÑO del texto escrito
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Contraseña (6 dígitos)',
                            labelStyle: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 14, // ⬅️ TAMAÑO del label
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.only(
                              top:
                                  55.00, // ⬅️ MARGEN superior para bajar los campos
                              bottom: 10, // ⬅️ MARGEN inferior
                              left: 15,
                              right: 15,
                            ),
                            prefixIcon: Icon(
                              Icons.lock,
                              color: Colors.white,
                              size: 28, // ⬅️ TAMAÑO del icono
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          obscureText: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 8,
              ), // ⬅️ ESPACIO entre los campos de texto y los botones
              // Botones de inicio de sesión con fondo de madera
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Botón de inicio de sesión normal
                  Expanded(
                    child: GestureDetector(
                      onTap: _login,
                      child: Container(
                        height: 120,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          image: const DecorationImage(
                            image: AssetImage(
                              'assets/images/madera/MaderaCuadro.png',
                            ),
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black38,
                              offset: Offset(0, 4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.login_rounded,
                              color: Colors.white,
                              size: 45,
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Iniciar\nSesión',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Botón de inicio de sesión con Google
                  Expanded(
                    child: GestureDetector(
                      onTap: _signInWithGoogle,
                      child: Container(
                        height: 120,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          image: const DecorationImage(
                            image: AssetImage(
                              'assets/images/madera/MaderaCuadro.png',
                            ),
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black38,
                              offset: Offset(0, 4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/ui/google_icon.png',
                              width: 45,
                              height: 45,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.g_mobiledata_rounded,
                                    color: Colors.white,
                                    size: 45,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Iniciar con\nGoogle',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 4,
              ), // ⬅️ ESPACIO entre botones y el texto de registrarse
              TextButton(
                onPressed: widget.onRegisterPressed,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('¿No tienes cuenta? Regístrate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
