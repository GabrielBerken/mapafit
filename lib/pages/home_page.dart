import 'package:flutter/material.dart';
import 'package:mapafit/components/bottom_template.dart';
import 'package:mapafit/components/top_template.dart';
import 'package:mapafit/pages/explorar_locais.dart';
import 'package:mapafit/providers/user_provider.dart';
import 'package:provider/provider.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barra de Navegação',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(), // Defina o tipo de usuário aqui
    );
  }
}

class MyHomePage extends StatelessWidget {

  const MyHomePage({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: const TemplateAppBar(),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _getBodyContent(context),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const TemplateBarraInferior()
    );
  }

  Widget _getBodyContent(BuildContext context) {
    switch (context.read<UserProvider>().userType) {
            case UserType.loggedOutUser:
        return const ExplorarLocaisPage();

      case UserType.loggedInUser:
        return const ExplorarLocaisPage();

      default:
        return const Center(child: Text('Tipo de usuário não reconhecido.'));
    }
  }

}
