import 'package:flutter/material.dart';
import 'package:mapafit/pages/acesso_inicial.dart';
import 'package:mapafit/pages/explorar_locais.dart';
import 'package:mapafit/providers/user_provider.dart';
import 'package:mapafit/controllers/usuario_controller.dart';
import 'package:provider/provider.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});


  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _verificarStatusLogin();
  }

  Future<void> _verificarStatusLogin() async {
    await Future.delayed(const Duration(seconds: 2));

    int? userId = await checkLoginStatus();
    bool estaLogado = userId != null;

    if (mounted) {
      if (estaLogado) {
        context.read<UserProvider>().setUserType(UserType.loggedInUser);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ExplorarLocaisPage()),
        );
      } else {
        context.read<UserProvider>().setUserType(UserType.loggedOutUser);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const InicialPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'lib/assets/mapafit.png',
          height: 250,
        ),
      ),
    );
  }
}