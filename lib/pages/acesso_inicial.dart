import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:mapafit/pages/cadastrado/login_page.dart';
import 'package:mapafit/pages/cadastro.dart';
import 'package:mapafit/pages/explorar_locais.dart';
import 'package:provider/provider.dart';
import 'package:mapafit/providers/user_provider.dart';

class InicialPage extends StatelessWidget {
  const InicialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                Image.asset(
                  'lib/assets/mapafit.png',
                  height: 250.0,
                ),
                const SizedBox(height: 40.0),
                ElevatedButton(
                  onPressed: () {
                    context.read<UserProvider>().setUserType(UserType.loggedOutUser);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ExplorarLocaisPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF528265),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: const Text(
                    'Explorar MapaFit',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black54, fontSize: 15),
                    children: [
                      const TextSpan(text: 'Já tem uma conta? '),
                      TextSpan(
                        text: 'Faça login',
                        style: const TextStyle(
                          color: Color(0xFF528265),
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginPage()),
                            );
                          },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black54, fontSize: 15),
                    children: [
                      const TextSpan(text: 'Não tem uma conta? '),
                      TextSpan(
                        text: 'Cadastre-se',
                        style: const TextStyle(
                          color: Color(0xFF528265),
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CadastroPage()),
                            );
                          },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
