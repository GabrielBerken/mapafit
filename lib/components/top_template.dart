import 'package:flutter/material.dart';
import 'package:mapafit/pages/acesso_inicial.dart';
import 'package:mapafit/providers/user_provider.dart';
import 'package:provider/provider.dart';

class TemplateAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TemplateAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF528265),
      elevation: 0,
      leading: IconButton(
        onPressed: () {
          context.read<UserProvider>().setUserType(UserType.loggedOutUser);
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const InicialPage(),
              ));},
        icon: const Icon(Icons.logout, color: Colors.white),
      ),
      centerTitle: true,
      // 1. Simplificamos o title para conter apenas a imagem.
      title: Image.asset(
        'lib/assets/mapafit_branco.png', // Caminho da logo
        height: 40, // Ajuste da altura
      ),
      // 2. Garantimos que sempre haverá um widget em 'actions' para balancear.
      actions: const [
        // Espaçador invisível com a mesma largura do botão 'leading'.
        SizedBox(width: 56.0),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
