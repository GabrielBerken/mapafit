import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mapafit/models/local_model.dart';
import 'package:mapafit/pages/cadastrado/avaliar_local.dart';
import 'package:mapafit/controllers/checkin_controller.dart';

class CheckoutPage extends StatefulWidget {
  final Local local;
  final int checkinId;

  const CheckoutPage({Key? key, required this.local, required this.checkinId}) : super(key: key);
  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late Timer _timer;
  Timer? _pollingTimer;
  Duration _elapsedTime = Duration.zero;
  bool _canCheckout = false;
  bool _isLoading = false;
  static const int _checkoutMinutes = 1; // Define o tempo mínimo para checkout
  final DateTime _startTime = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    _startVisualTimer(); // Inicia o timer para a UI
    _startStatusPolling(); // Inicia o polling para a lógica de negócio
  }

  @override
  void dispose() {
    _timer.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startVisualTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() { 
        _elapsedTime = DateTime.now().difference(_startTime);

      });
    });
  }

  void _startStatusPolling() {
    // Verifica o status imediatamente e depois a cada 30 segundos.
    _checkStatus();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_canCheckout || !mounted) {
        timer.cancel();
        return;
      }
      _checkStatus();
    });
  }

  Future<void> _checkStatus() async {
    try {
      final status = await getCheckInStatus(checkinId: widget.checkinId);
      debugPrint(' dasdasdas $status' );
      if (mounted && (status == 'Enable checkout' || status == 'Checked out already')) {
        setState(() => _canCheckout = true);
        _pollingTimer?.cancel();
      }
    } catch (e) {
      print("Erro ao verificar status do check-in: $e");
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    // Adiciona horas se o tempo for longo
    if (d.inHours > 0) {
      return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  void _confirmCheckout() {
    if (!_canCheckout || _isLoading) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Check-out'),
          content: Text('Deseja confirmar o check-out de "${widget.local.nome}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Não'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Fecha o diálogo de confirmação
                await _performBackendCheckout();
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF528265),
              ),
              child: const Text('Sim'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performBackendCheckout() async {
    setState(() => _isLoading = true);
    try {
      await performCheckOut(checkinId: widget.checkinId);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AvaliacaoLocalPage(local: widget.local)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-out em Andamento'),
        backgroundColor: const Color(0xFF528265),
        automaticallyImplyLeading: false, // Impede o usuário de voltar
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Tempo em',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
              ),
              Text(
                widget.local.nome,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32.0),
              // Timer Circular
              SizedBox(
                height: 200,
                width: 200,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      // O valor vai de 0.0 a 1.0, representando o progresso
                      value: _canCheckout ? 1.0 : _elapsedTime.inSeconds / (_checkoutMinutes * 60),
                      strokeWidth: 12,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _canCheckout ? Colors.green : const Color(0xFF528265),
                      ),
                    ),
                    Center(
                      child: Text(
                        _formatDuration(_elapsedTime),
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: _canCheckout ? Colors.green : const Color(0xFF528265),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32.0),
              Text(
                _canCheckout
                    ? 'Você já pode fazer o check-out!'
                    : 'Você só poderá fazer o checkout após $_checkoutMinutes minutos.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: _canCheckout ? Colors.green : Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24.0),
              ElevatedButton.icon(
                onPressed: _canCheckout && !_isLoading ? _confirmCheckout : null,
                icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                label: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text(
                        'Fazer Check-out',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF528265),
                  disabledBackgroundColor: Colors.grey[400],
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
