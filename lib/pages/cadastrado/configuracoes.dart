// ignore_for_file: dead_code
import 'package:flutter/material.dart';
import 'package:mapafit/controllers/usuario_controller.dart' as usuario_controller;
import 'package:mapafit/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mapafit/utils/user_cache_helper.dart';
import '../../components/safe_network_avatar.dart';

class ConfiguracaoPerfilPage extends StatefulWidget {
  const ConfiguracaoPerfilPage({super.key});

  @override
  State<ConfiguracaoPerfilPage> createState() => _ConfiguracaoPerfilPageState();
}

class _ConfiguracaoPerfilPageState extends State<ConfiguracaoPerfilPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Preenche inicialmente com os dados do provider (rápido)
    _carregarDadosUsuario();
    // Tenta popular o provider com dados do cache ao abrir a página (poderá atualizar os campos)
    _applyCacheOnOpen();
  }

  Future<void> _applyCacheOnOpen() async {
    final cached = await populateUserFromCacheIfAvailable(context);
    if (cached != null && mounted) {
      _nomeController.text = cached.nome;
      _emailController.text = cached.email;
      _telefoneController.text = cached.telefone ?? '';
    }
  }

  void _carregarDadosUsuario() {
    final user = context.read<UserProvider>().currentUser;
    if (user != null) {
      _nomeController.text = user.nome;
      _emailController.text = user.email;
      _telefoneController.text = user.telefone ?? '';
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  Future<void> _salvarAlteracoes() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.currentUser;

    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro: Usuário não encontrado.'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
      return;
    }

    final usuarioAtualizado = currentUser.copyWith(
      nome: _nomeController.text,
      email: _emailController.text,
      telefone: _telefoneController.text.isNotEmpty ? _telefoneController.text : null,
    );

    try {
      // Atualiza o perfil no servidor e no cache
      final usuarioAtualizadoServidor = await usuario_controller.updateUserProfile(usuarioAtualizado);

      if (mounted) {
        // Atualiza o usuário no provider para refletir as mudanças em outras telas
        userProvider.updateCurrentUser(usuarioAtualizadoServidor);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(); // Volta para a tela de perfil
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final userProvider = context.read<UserProvider>();
    final user = userProvider.currentUser;
    if (user == null) return;

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null && mounted) {
      setState(() => _isLoading = true);
      try {
        final updatedUser = await usuario_controller.uploadProfilePicture(user.id, image.path);
        if (mounted) {
          userProvider.updateCurrentUser(updatedUser);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto atualizada com sucesso!'), backgroundColor: Colors.green),
          );
          // Atualiza os controladores com os dados atualizados
          _nomeController.text = updatedUser.nome;
          _emailController.text = updatedUser.email;
          _telefoneController.text = updatedUser.telefone ?? '';
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao enviar foto: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: const Color(0xFF528265),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Consumer<UserProvider>(
                builder: (context, provider, child) {
                  final user = provider.currentUser;
                  final fotoUrl = user?.fotoUrl;
                  final temFoto = fotoUrl != null && fotoUrl.isNotEmpty;
                  return Center(
                    child: Stack(
                      children: [
                        SafeNetworkAvatar(imageUrl: fotoUrl, radius: 50.0, placeholder: const Icon(Icons.person, size: 50, color: Colors.grey)),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                              onPressed: _pickAndUploadImage,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
              _buildTextField(
                controller: _nomeController,
                label: 'Nome',
                icon: Icons.person_outline,
                validator: (value) => (value?.isEmpty ?? true) ? 'O nome não pode ser vazio' : null,
              ),
              const SizedBox(height: 20.0),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) => (value?.isEmpty ?? true || !value!.contains('@')) ? 'Insira um e-mail válido' : null,
              ),
              const SizedBox(height: 20.0),
              _buildTextField(
                controller: _telefoneController,
                label: 'Telefone',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 40.0),
              ElevatedButton(
                onPressed: _isLoading ? null : _salvarAlteracoes,
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
                    : const Text('Salvar Alterações', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}
