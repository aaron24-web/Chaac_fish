import 'package:flutter/material.dart';
import 'package:pesca_game/src/features/auth/data/repositories/auth_repository.dart';
import 'package:pesca_game/src/features/main_menu/presentation/screens/main_menu_screen.dart';
import 'package:pesca_game/src/shared/widgets/custom_button.dart';

class RegisterForm extends StatefulWidget {
  final VoidCallback onLoginPressed;

  const RegisterForm({super.key, required this.onLoginPressed});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepository = AuthRepository();

  Future<void> _register() async {
    try {
      await _authRepository.signUp(
        username: _usernameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainMenuScreen()),
      );
    } catch (e) {
      final message = e.toString().contains('User already exists')
          ? 'El usuario ya existe'
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
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  filled: true,
                  fillColor: Colors.white70,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  filled: true,
                  fillColor: Colors.white70,
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              CustomButton(
                onPressed: _register,
                text: 'Registrarse',
              ),
              TextButton(
                onPressed: widget.onLoginPressed,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
                child: const Text('¿Ya tienes cuenta? Inicia Sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
