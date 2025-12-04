import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:mapafit/models/local_model.dart';
import 'package:mapafit/pages/cadastrado/checkout_page.dart';
import 'package:mapafit/controllers/checkin_controller.dart';
import 'package:mapafit/utils/user_cache_helper.dart';
import 'package:mapafit/providers/user_provider.dart';
import 'package:provider/provider.dart';

class CheckinPage extends StatefulWidget {
  final Local local;

  const CheckinPage({super.key, required this.local});

  @override
  State<CheckinPage> createState() => _CheckinPageState();
}

class _CheckinPageState extends State<CheckinPage> {
  bool _isLoading = false;
  int? _selectedActivityId;
  String? _mapStyle;

  final Map<int, String> _tiposDeAtividade = {
    1: 'Caminhada/Corrida',
    2: 'Musculação',
    3: 'Dança',
    4: 'Esportes Coletivos',
    5: 'Yoga/Pilates',
    6: 'Alongamento',
  };

  @override
  void initState() {
    super.initState();

    // Usa o valor do local somente se for uma opção válida do dropdown;
    // caso contrário deixa null para evitar múltiplos itens com o mesmo value
    final initial = widget.local.tipoAtividadeId;
    if (_tiposDeAtividade.containsKey(initial)) {
      _selectedActivityId = initial;
    } else {
      _selectedActivityId = null;
    }

    _loadMapStyle();

    // Tenta popular provider com dados do cache para melhor UX
    _applyCacheOnOpen();
  }

  Future<void> _applyCacheOnOpen() async {
    final cached = await populateUserFromCacheIfAvailable(context);
    if (cached != null && mounted) {
      context.read<UserProvider>().updateCurrentUser(cached);
    }
  }

  void _loadMapStyle() async {
    final style = await rootBundle.loadString('lib/assets/map_style.json');
    if (mounted) setState(() => _mapStyle = style);
  }

  Widget _buildMap() {
    final endereco = widget.local.endereco;
    if (endereco != null && endereco.latitude != null && endereco.longitude != null) {
      final position = LatLng(endereco.latitude!, endereco.longitude!);
      return ClipRRect(
        borderRadius: BorderRadius.circular(15.0),
        child: GoogleMap(
          style: _mapStyle,
          initialCameraPosition: CameraPosition(
            target: position,
            zoom: 16,
          ),
          markers: {
            Marker(
              markerId: MarkerId(widget.local.id.toString()),
              position: position,
            ),
          },
          zoomControlsEnabled: false,
          scrollGesturesEnabled: false,
          zoomGesturesEnabled: false,
          myLocationButtonEnabled: false,
        ),
      );
    } else {
      // Placeholder for when there's no location
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, color: Colors.grey, size: 48),
              SizedBox(height: 8),
              Text('Localização não disponível', textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
  }

  void _confirmCheckin() async {
    if (_selectedActivityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione a atividade que você vai realizar.'), backgroundColor: Colors.orange),
      );
      return;
    }

    final user = context.read<UserProvider>().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa estar logado para fazer check-in.'), backgroundColor: Colors.red),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Check-in'),
          content: Text('Deseja confirmar o check-in em "${widget.local.nome}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Não'),
            ),
            FilledButton(
            onPressed: () async {
                Navigator.of(context).pop(); // Fecha o diálogo de confirmação
                _performCheckin(user.id);
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

  Future<void> _performCheckin(int userId) async {
    setState(() => _isLoading = true);
    try {
      final checkin = await performCheckIn(
        userId: userId,
        localId: widget.local.id,
        tipoAtividadeId: _selectedActivityId!,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CheckoutPage(local: widget.local, checkinId: checkin.id),
          ),
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
        title: const Text('Realizar Check-in'),
        backgroundColor: const Color(0xFF528265),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: _buildMap(),
                ),
                const SizedBox(height: 24.0),
                Text(
                  widget.local.nome,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                if (widget.local.endereco != null)
                  Text(
                    '${widget.local.endereco!.rua ?? 'Rua não informada'}, ${widget.local.endereco!.numero ?? 'S/N'}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
                  ),
                const SizedBox(height: 24.0),
                DropdownButtonFormField<int>(
                  value: _selectedActivityId,
                  decoration: const InputDecoration(
                    labelText: 'Qual atividade você vai realizar?',
                    border: OutlineInputBorder(),
                  ),
                  items: _tiposDeAtividade.entries.map((entry) {
                    return DropdownMenuItem<int>(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedActivityId = value;
                    });
                  },
                  validator: (value) => value == null ? 'Por favor, selecione uma atividade.' : null,
                ),
                const SizedBox(height: 32.0),
                ElevatedButton.icon(
                  onPressed: _confirmCheckin,
                  icon: const Icon(Icons.location_on, color: Colors.white),
                  label: const Text(
                    'Fazer Check-in',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF528265),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}