import 'package:flutter/material.dart';

/// Circle avatar seguro que tenta carregar a imagem da rede e cai para um ícone local em caso de erro.
class SafeNetworkAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Widget? placeholder;

  const SafeNetworkAvatar({super.key, required this.imageUrl, this.radius = 24, this.placeholder});

  @override
  Widget build(BuildContext context) {
    final hasUrl = imageUrl != null && imageUrl!.isNotEmpty;
    if (!hasUrl) {
      return CircleAvatar(
        radius: radius,
        child: placeholder ?? const Icon(Icons.person, size: 24, color: Colors.grey),
      );
    }

    // Use Image.network with errorBuilder inside a ClipOval to emulate CircleAvatar backgroundImage
    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.white,
              alignment: Alignment.center,
              child: placeholder ?? const Icon(Icons.person, size: 24, color: Colors.grey),
            );
          },
          // Optional: show a simple placeholder while loading
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.white,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(strokeWidth: 2),
            );
          },
        ),
      ),
    );
  }
}
