import 'package:flutter/material.dart';
import 'package:mapafit/models/conquista_model.dart';
import 'package:mapafit/pages/cadastrado/compartilhar_conquista.dart';
import 'package:mapafit/providers/conquista_provider.dart';
import 'package:mapafit/providers/user_provider.dart';
import 'package:provider/provider.dart';

import '../../components/bottom_template.dart';
import '../../components/top_template.dart';
import 'package:mapafit/utils/user_cache_helper.dart';

class ConquistaPage extends StatefulWidget {
  const ConquistaPage({super.key});

  @override
  State<ConquistaPage> createState() => _ConquistaPageState();
}

class _ConquistaPageState extends State<ConquistaPage> {
  @override
  void initState() {
    super.initState();
    // Usamos addPostFrameCallback para garantir que o context está disponível.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserProvider>().currentUser;
      if (user != null) {
        context.read<ConquistaProvider>().carregarConquistas(user.id);
      }
    });

    // Tenta popular o provider com dados do cache para melhorar UX
    _applyCacheOnOpen();
  }

  Future<void> _applyCacheOnOpen() async {
    final cached = await populateUserFromCacheIfAvailable(context);
    if (cached != null && mounted) {
      context.read<UserProvider>().updateCurrentUser(cached);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TemplateAppBar(),
      body: Consumer<ConquistaProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(child: Text('Erro: ${provider.error}'));
          }
          if (provider.conquistas.isEmpty) {
            return const Center(child: Text('Você ainda não possui conquistas.'));
          }

          return ListView.builder(
            itemCount: provider.conquistas.length,
            itemBuilder: (context, index) {
              final conquista = provider.conquistas[index];
              return _buildAchievementCard(conquista);
            },
          );
        },
      ),
      bottomNavigationBar: const TemplateBarraInferior(),
    );
  }

  // Mapeia o nome do ícone vindo do backend para um IconData
  IconData _getIconFromString(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'checkin':
        return Icons.place;
      case 'cadastro':
        return Icons.fact_check_outlined;
      case 'vida':
        return Icons.favorite;
      default:
        return Icons.workspace_premium; // Ícone padrão
    }
  }

  Widget _buildAchievementCard(Conquista conquista) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 3,
      child: ListTile(
        leading: Icon(_getIconFromString(conquista.icone), size: 40.0, color: Theme.of(context).colorScheme.primary),
        title: Text(conquista.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(conquista.descricao),
        trailing: IconButton(
          icon: const Icon(Icons.share),
          tooltip: 'Compartilhar',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CompartilharPage(conquista: conquista),
              ),
            );
          },
        ),
      ),
    );
  }
}
