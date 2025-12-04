import 'package:flutter/material.dart';
import 'package:flutter_config/flutter_config.dart';
import 'package:mapafit/pages/cadastrado/configuracoes.dart';
import 'package:mapafit/pages/cadastrado/conquista.dart';
import 'package:mapafit/pages/cadastrado/indicar_locais.dart';
import 'package:mapafit/pages/cadastrado/login_page.dart';
import 'package:mapafit/pages/cadastrado/perfil.dart';
import 'package:mapafit/pages/cadastro.dart';
import 'package:mapafit/pages/explorar_locais.dart';
import 'package:mapafit/pages/splash_screen.dart';
// import 'package:mapafit/pages/user_provider.dart';
import 'package:mapafit/providers/conquista_provider.dart';
import 'package:mapafit/repositories/locais_repository.dart';
import 'package:provider/provider.dart';
import 'package:mapafit/providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterConfig.loadEnvVariables();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<LocaisRepository>(create: (_) => LocaisRepository()),
        ChangeNotifierProvider<ConquistaProvider>(create: (_) => ConquistaProvider()),
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MapaFit',
      home: const SplashScreen(), // Define a SplashScreen como a tela inicial
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF003933),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF003933)).copyWith(
          primary: const Color(0xFF003933),
          secondary: const Color(0xFF528265),
          error: Colors.red,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
      ),
      routes: {
        '/indicar_local': (context) => const IndicarLocaisPage(),
        '/cadastro': (context) => const CadastroPage(),
        '/configuracoes': (context) => const ConfiguracaoPerfilPage(),
        '/conquista': (context) => const ConquistaPage(),
        '/explorar': (context) => const ExplorarLocaisPage(),
        '/login': (context) => const LoginPage(),
        '/perfil': (context) => const PerfilPage(),
      },
    );
  }
}
