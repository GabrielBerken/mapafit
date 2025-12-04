import 'package:flutter/material.dart';
import 'package:mapafit/components/top_template.dart';
import 'package:mapafit/models/conquista_model.dart';
import 'package:share_plus/share_plus.dart';

class CompartilharPage extends StatelessWidget {
  final Conquista conquista;
  const CompartilharPage({super.key, required this.conquista});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TemplateAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Text(
              'Compartilhe sua conquista!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            // Card preview
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(_getIconFromString(conquista.icone), size: 60, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      conquista.titulo,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      conquista.descricao,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.share, color: Colors.white),
              label: const Text('Compartilhar agora', style: TextStyle(color: Colors.white, fontSize: 16)),
              onPressed: () {
                final shareText = 'Conquistei "${conquista.titulo}" no MapaFit! 🎉\n${conquista.descricao}';
                Share.share(shareText);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF528265),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
