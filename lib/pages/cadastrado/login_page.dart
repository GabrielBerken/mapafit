import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:mapafit/pages/cadastro.dart';
import 'package:mapafit/pages/explorar_locais.dart';
import 'package:mapafit/controllers/usuario_controller.dart';
import 'package:mapafit/utils/user_cache_helper.dart';
import 'package:mapafit/providers/user_provider.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      // Primeiro faz o login para autenticar e obter o token
      final usuario = await login(_emailController.text, _passwordController.text);
      
      if (mounted) {
        // Tenta popular rapidamente com dados do cache (se houver) para melhorar a percepção de velocidade
        try {
          final cached = await populateUserFromCacheIfAvailable(context, userId: usuario.id);
          if (cached != null) {
            context.read<UserProvider>().setCurrentUser(cached);
          }
        } catch (_) {
          // ignora erros ao ler cache
        }

        // Busca o perfil completo, forçando a atualização para garantir dados recentes
        final perfilCompleto = await fetchFullUserProfile(usuario.id, forceRefresh: true);

        // Atualiza o provider com os dados completos do usuário
        context.read<UserProvider>().setCurrentUser(perfilCompleto);


        // Navega para a tela principal
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ExplorarLocaisPage()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          // Exibe a mensagem de erro específica vinda do controller.
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acessar Conta'),
        backgroundColor: const Color(0xFF528265),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Image.asset(
                'lib/assets/mapafit.png',
                height: 180,
              ),
              const SizedBox(height: 40),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty || !value.contains('@')) {
                    return 'Por favor, digite um e-mail válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, digite sua senha';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF528265),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      )
                    : const Text('Entrar', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
              const SizedBox(height: 24),
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
            ],
          ),
        ),
      ),
    );
  }
}
