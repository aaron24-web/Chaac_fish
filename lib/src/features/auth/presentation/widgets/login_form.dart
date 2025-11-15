import 'package:flutter/material.dart';
import 'package:pesca_game/src/features/auth/data/repositories/auth_repository.dart';
import 'package:pesca_game/src/features/main_menu/presentation/screens/main_menu_screen.dart';
import 'package:pesca_game/src/shared/widgets/custom_button.dart';

class LoginForm extends StatefulWidget {
  final VoidCallback onRegisterPressed;

  const LoginForm({super.key, required this.onRegisterPressed});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepository = AuthRepository();

  Future<void> _login() async {
    try {
      await _authRepository.signIn(
        username: _usernameController.text,
        password: _passwordController.text,
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainMenuScreen()),
      );
    } catch (e) {
      final message = e.toString().contains('User not found')
          ? 'Usuario no encontrado'
          : 'Ocurrió un error';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 400,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de usuario',
                  filled: true,
                  fillColor: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña (6 dígitos)',
                  filled: true,
                  fillColor: Colors.white70,
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: true,
              ),
              const SizedBox(height: 24),
              CustomButton(
                onPressed: _login,
                text: 'Iniciar Sesión',
              ),
              TextButton(
                onPressed: widget.onRegisterPressed,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
                child: const Text('¿No tienes cuenta? Regístrate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
