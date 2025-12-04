import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:mapafit/controllers/conquista_controller.dart';
import 'package:mapafit/controllers/avaliacao_controller.dart';
import 'package:mapafit/utils/user_cache_helper.dart';
import 'package:mapafit/models/avaliacao_model.dart';
import 'package:mapafit/models/local_model.dart';
import 'package:mapafit/pages/explorar_locais.dart';
import 'package:mapafit/providers/user_provider.dart';
import 'package:provider/provider.dart';

class AvaliacaoLocalPage extends StatefulWidget {
  final Local local;
  const AvaliacaoLocalPage({super.key, required this.local});

  @override
  State<AvaliacaoLocalPage> createState() => _AvaliacaoLocalPageState();
}

class _AvaliacaoLocalPageState extends State<AvaliacaoLocalPage> {
  double _rating = 3.0;
  final _comentarioController = TextEditingController();
  Avaliacao? _avaliacaoExistente;
  bool _isEditMode = true;
  bool _isCheckingEvaluation = true; // Estado para controlar o carregamento inicial
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _applyCacheOnOpen();
    _checkForExistingEvaluation(context);
  }

  Future<void> _applyCacheOnOpen() async {
    final cached = await populateUserFromCacheIfAvailable(context);
    if (cached != null && mounted) {
      context.read<UserProvider>().updateCurrentUser(cached);
    }
  }

  Future<void> _checkForExistingEvaluation(BuildContext context) async {
    final user = context.read<UserProvider>().currentUser;

    if (user == null) {
      setState(() => _isCheckingEvaluation = false);
      return;
    }

    try {
      final todasAsAvaliacoes = await fetchAvaliacoesPorUsuario(user.id);

      _avaliacaoExistente = todasAsAvaliacoes.firstWhere((av) => av.localId == widget.local.id);

      _isEditMode = true;
      _rating = _avaliacaoExistente!.nota ?? 3.0;
      _comentarioController.text = _avaliacaoExistente!.comentario ?? '';
    } catch (e) {
      debugPrint("Não foi encontrada avaliação existente ou houve erro: $e");
    } finally {
      if (mounted) setState(() => _isCheckingEvaluation = false);
    }
  }

  Future<void> _enviarAvaliacao() async {
    final user = context.read<UserProvider>().currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      if (_isEditMode) {
        await atualizarAvaliacao(
          avaliacaoId: _avaliacaoExistente!.id,
          nota: _rating,
          comentario: _comentarioController.text,
        );
      } else {
        await enviarAvaliacao(
          localId: widget.local.id,
          userId: user.id,
          nota: _rating,
          comentario: _comentarioController.text,
        );
        await registrarEvento(user.id, 'AVALIACAO_CONCLUIDA');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = false);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              _isEditMode ? '✅ Avaliação Atualizada' : '✅ Avaliação Enviada',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(
              _isEditMode 
                ? 'Sua avaliação foi atualizada com sucesso!' 
                : 'Sua avaliação foi enviada com sucesso!',
              style: const TextStyle(fontSize: 16),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Fecha o dialog
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const ExplorarLocaisPage()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF528265)),
                child: const Text('Voltar para o mapa', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingEvaluation) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Carregando...', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF528265),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? '✏️ Editar Avaliação' : '⭐ Avaliar ${widget.local.nome}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF528265),
      ),
      backgroundColor: const Color(0xFFFFFFFF),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Como foi sua experiência?', style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20.0),
            RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rating) {
                setState(() => _rating = rating);
              },
            ),
            const SizedBox(height: 30.0),
            TextField(
              controller: _comentarioController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Deixe um comentário (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30.0),
            ElevatedButton(
              onPressed: _isLoading ? null : _enviarAvaliacao,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF528265),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _isEditMode ? 'Atualizar Avaliação' : 'Enviar Avaliação',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
