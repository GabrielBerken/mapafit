import 'package:flutter/material.dart';
import 'package:mapafit/pages/cadastrado/conquista.dart';
import 'package:mapafit/pages/cadastrado/login_page.dart';
import 'package:mapafit/pages/cadastrado/perfil.dart';
import 'package:mapafit/pages/explorar_locais.dart';
import 'package:provider/provider.dart';
import 'package:mapafit/providers/user_provider.dart';

class TemplateBarraInferior extends StatelessWidget {
  const TemplateBarraInferior({super.key});

  @override
  Widget build(BuildContext context) {
    final userType = context.watch<UserProvider>().userType;

    switch (userType) {
      case UserType.loggedInUser:
        return SizedBox(
          height: 60.0, // Aumenta a altura para melhor toque
          child: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            color: const Color(0xFF528265),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _buildBottomBarItems(context, userType),
            ),
          ),
        );
      case UserType.loggedOutUser:
        return Container(
          height: 70.0,
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: Colors.white, // Fundo branco para condizer com a gaveta
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Center(
            child: ElevatedButton(
              onPressed: () {
                // Navega para a página de login
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const LoginPage()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, // Fundo branco para condizer
                foregroundColor: const Color(0xFF528265), // Texto verde
                elevation: 0, // A sombra já está no container
                side: const BorderSide(color: Color(0xFF528265), width: 1.5), // Borda verde
                minimumSize: const Size(double.infinity, 50), // Ocupa toda a largura
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Fazer Login ou Cadastrar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  List<Widget> _buildBottomBarItems(BuildContext context, UserType userType) {
    switch (userType) {
      case UserType.loggedInUser:
        return [
          IconButton(
            icon: const Icon(Icons.map, color: Colors.white),
            tooltip: 'Explorar',
            onPressed: () {
              // Usa pushReplacement para não empilhar telas de navegação principal
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const ExplorarLocaisPage()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events, color: Colors.white),
            tooltip: 'Conquistas',
            onPressed: () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const ConquistaPage()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            tooltip: 'Perfil',
            onPressed: () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const PerfilPage()));
            },
          ),
        ];
      default:
        return [];
    }
  }
}
