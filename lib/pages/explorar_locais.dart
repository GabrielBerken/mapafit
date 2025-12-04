import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mapafit/components/bottom_template.dart';
import 'package:mapafit/components/top_template.dart';
import 'package:mapafit/models/local_model.dart';
import 'package:mapafit/pages/cadastrado/indicar_locais.dart';
import 'package:mapafit/repositories/locais_repository.dart';
import 'package:mapafit/utils/locais_cache_helper.dart';
import 'package:mapafit/services/location_service.dart';
import 'package:mapafit/providers/user_provider.dart';
import 'package:mapafit/widgets/local_detalhes.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mapafit/widgets/local_card.dart';

class ExplorarLocaisPage extends StatefulWidget {
  const ExplorarLocaisPage({super.key});

  @override
  State<ExplorarLocaisPage> createState() => _ExplorarLocaisPageState();
}

class _ExplorarLocaisPageState extends State<ExplorarLocaisPage> {
  final GlobalKey _scaffoldKey = GlobalKey();

  LatLng? _currentPosition;
  String? _mapStyle;
  String? _error;
  Set<Marker> _markers = {};
  BitmapDescriptor? _localIcon;


  final ValueNotifier<Local?> _selectedLocalNotifier = ValueNotifier(null);
  final DraggableScrollableController _draggableController = DraggableScrollableController();
  List<Local> _locais = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePage();
    _setupMarkerListener();
  }

  @override
  void dispose() {
    _selectedLocalNotifier.dispose();
    _draggableController.dispose();
    super.dispose();
  }

  Future<void> _initializePage() async {
    await _loadMapStyle();
    await _getCurrentPosition();
    // Primeiro tenta popular com cache (rápido, sem requests)
    try {
      final cached = await populateLocaisFromCacheIfAvailable(context);
      if (cached != null && mounted) {
        // Reuse o mesmo código que constrói marcadores a partir da lista
        final Set<Marker> newMarkers = {};
        for (var local in cached) {
          final endereco = local.endereco;
          if (endereco != null && endereco.latitude != null && endereco.longitude != null && _localIcon != null) {
            newMarkers.add(
              Marker(
                markerId: MarkerId(local.id.toString()),
                position: LatLng(endereco.latitude!, endereco.longitude!),
                icon: _localIcon!,
                onTap: () => _selectedLocalNotifier.value = local,
              ),
            );
          }
        }
        if (mounted) setState(() {
          _locais = cached;
          _markers = newMarkers;
        });
      }
    } catch (_) {
      // ignora erros do cache
    }

    // Em seguida busca dados reais (pode atualizar cache e UI)
    await _fetchAndBuildMarkers();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMapStyle() async {
    _mapStyle = await rootBundle.loadString('lib/assets/map_style.json'); // Carrega o estilo do mapa
    // Pré-carrega o ícone para performance (uso recomendado: BitmapDescriptor.asset)
    _localIcon = BitmapDescriptor.defaultMarker; // fallback
    try {
      _localIcon = await BitmapDescriptor.fromAssetImage(const ImageConfiguration(size: Size(48, 48)), 'lib/assets/heart_min.png');
    } catch (_) {
      // fallback para default marker se asset não puder ser carregado
      _localIcon = BitmapDescriptor.defaultMarker;
    }
  }

  Future<void> _getCurrentPosition() async {
    try {
      final position = await LocationService.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _fetchAndBuildMarkers() async {
    try {
      final repository = context.read<LocaisRepository>();
      
      // Se tivermos a posição atual, busca locais próximos
      final locais = _currentPosition != null
          ? await repository.fetchLocais(
              latitude: _currentPosition!.latitude,
              longitude: _currentPosition!.longitude,
            )
          : await repository.fetchLocais();
          
      final Set<Marker> newMarkers = {};

      for (var local in locais) {
        final endereco = local.endereco;
        if (endereco != null &&
            endereco.latitude != null &&
            endereco.longitude != null &&
            _localIcon != null) {
          newMarkers.add(
            Marker(
              markerId: MarkerId(local.id.toString()),
              position: LatLng(endereco.latitude!, endereco.longitude!),
              icon: _localIcon!,
              onTap: () {
                // Notifica os ouvintes que um marcador foi selecionado.
                _selectedLocalNotifier.value = local;
              },
            ),
          );
        }
      }
      if (mounted) setState(() {
        _locais = locais;
        _markers = newMarkers;
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Erro ao carregar locais: $e');
    }
  }

  void _setupMarkerListener() {
    _selectedLocalNotifier.addListener(() {
      final selectedLocal = _selectedLocalNotifier.value;
      // Verifica se o controlador está anexado antes de usá-lo
      if (!_draggableController.isAttached) return;
      
      if (selectedLocal != null) {
        // Anima a gaveta para uma altura intermediária, ideal para ver o card.
        _draggableController.animateTo(0.45, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
      } else {
        // Ao voltar para a lista, minimiza a gaveta.
        _draggableController.animateTo(0.1, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
      }
    });
  }

  void _onMapTapped(LatLng position) async {
    final userType = context.read<UserProvider>().userType;

    // Apenas usuários logados podem sugerir um local.
    if (userType == UserType.loggedInUser) {
      final bool? querIndicar = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Indicar Local'),
            content: const Text('Gostaria de indicar este local para o MapaFit?'),
            actions: <Widget>[
              TextButton(
                child: const Text('Não'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              FilledButton(
                child: const Text('Sim'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        },
      );

      if (querIndicar == true && mounted) {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
          Placemark place = placemarks[0];

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IndicarLocaisPage(
                latitude: position.latitude,
                longitude: position.longitude,
                rua: place.street,
                cidade: place.locality,
                estado: place.administrativeArea,
                cep: place.postalCode,
              ),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível obter o endereço para este local.'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: const TemplateAppBar(),
      body: Builder(builder: (context) {
        if (_error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 60, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao obter localização',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar Novamente'),
                    onPressed: _initializePage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF528265),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        if (_isLoading || _currentPosition == null) return const Center(child: CircularProgressIndicator());

        return Stack(
          children: [
            _buildMap(),
            _buildDraggableSheet(),
          ],
        );
      }),
      bottomNavigationBar: const TemplateBarraInferior(),
    );
  }

  Widget _buildMap() {
    return GoogleMap(
      style: _mapStyle,
      initialCameraPosition: CameraPosition(target: _currentPosition!, zoom: 14),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      onMapCreated: (gmc) {
        // _mapsController = gmc; // controller currently unused
      },
      markers: _markers,
      onTap: _onMapTapped,
    );
  }

  Widget _buildDraggableSheet() {
    return DraggableScrollableSheet(
      controller: _draggableController,
      initialChildSize: 0.1, // Começa minimizado, mostrando apenas o "handle"
      minChildSize: 0.1,   // Tamanho mínimo
      maxChildSize: 0.98,   // Tamanho máximo (tela quase cheia)
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)],
          ),
          child: ValueListenableBuilder<Local?>(
            valueListenable: _selectedLocalNotifier,
            builder: (context, selectedLocal, _) {
              // Usa um AnimatedSwitcher para uma transição suave entre a lista e os detalhes
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: selectedLocal == null
                    ? _buildLocalsList(scrollController)
                    : _buildDetailView(selectedLocal),
              );
            },
          ),
        );
      },
    );
  }

  /// Constrói a lista de locais dentro da gaveta.
  Widget _buildLocalsList(ScrollController scrollController) {
    return Column(
      key: const ValueKey('locals_list'), // Chave para o AnimatedSwitcher
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
        ),
        Expanded(
          child: _locais.isEmpty
              ? const Center(child: Text('Nenhum local encontrado.'))
              : ListView.builder(
                  controller: scrollController, // Conecta o controller para o drag funcionar
                  itemCount: _locais.length,
                  itemBuilder: (context, index) {
                    return LocalCard(
                      local: _locais[index],
                      onTap: () => _selectedLocalNotifier.value = _locais[index],
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Constrói a visão de detalhes para um local selecionado dentro da gaveta.
  Widget _buildDetailView(Local local) {
    return Column(
      key: ValueKey(local.id), // Chave para o AnimatedSwitcher
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => _selectedLocalNotifier.value = null, // Volta para a lista
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: LocalDetalhes(local: local),
          ),
        ),
      ],
    );
  }
}
