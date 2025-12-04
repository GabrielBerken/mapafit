import 'package:flutter/material.dart';
import 'package:mapafit/models/cidade_model.dart';
import 'package:mapafit/models/endereco_model.dart';
import 'package:mapafit/models/estado_model.dart';
import 'package:mapafit/models/local_model.dart';
import 'package:mapafit/repositories/locais_repository.dart';
import 'package:mapafit/services/ibge_service.dart';
import 'package:provider/provider.dart';

class IndicarLocaisPage extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final String? rua;
  final String? cidade;
  final String? estado;
  final String? cep;

  const IndicarLocaisPage({
    Key? key,
    this.latitude,
    this.longitude,
    this.rua,
    this.cidade,
    this.estado,
    this.cep,
  }) : super(key: key);

  @override
  State<IndicarLocaisPage> createState() => _IndicarLocaisPageState();
}

class _IndicarLocaisPageState extends State<IndicarLocaisPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for TextFormFields
  final _nomeController = TextEditingController();
  final _cepController = TextEditingController();
  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _horariosController = TextEditingController();
  final _infoController = TextEditingController();

  // State for Dropdowns
  int? _tipoLocalId;
  int? _tipoAtividadeId;
  int? _tipoAcessoId;

  // New state for dependent dropdowns
  final IbgeService _ibgeService = IbgeService();
  List<Estado> _estados = [];
  List<Cidade> _cidades = [];
  Estado? _estadoSelecionado;
  Cidade? _cidadeSelecionada;
  bool _estadosCarregando = true;
  bool _cidadesCarregando = false;

  bool _isLoading = false;

  // Mock data for dropdowns - ideally this would come from a service/enum
  final Map<int, String> _tiposDeLocal = {
    1: 'Parque',
    2: 'Área verde',
    3: 'Academia',
    4: 'Estúdio de Dança',
    5: 'Quadra Esportiva',
  };

  final Map<int, String> _tiposDeAtividade = {
    1: 'Caminhada/Corrida',
    2: 'Musculação',
    3: 'Dança',
    4: 'Esportes Coletivos',
    5: 'Yoga/Pilates',
    6: 'Alongamento',
  };

  final Map<int, String> _tiposDeAcesso = {
    1: 'Gratuito',
    2: 'Pago',
  };

  @override
  void initState() {
    super.initState();
    // Preenche os controllers com os dados de endereço recebidos
    _ruaController.text = widget.rua ?? '';    
    _cepController.text = (widget.cep ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    _carregarEstados();
  }

  Future<void> _carregarEstados() async {
    try {
      final estados = await _ibgeService.getEstados();
      if (!mounted) return;

      Estado? estadoInicial;
      if (widget.estado != null) {
        try {
          // O geocoding pode retornar o nome completo ou a sigla
          estadoInicial = estados.firstWhere(
            (e) => e.sigla.toLowerCase() == widget.estado!.toLowerCase() || e.nome.toLowerCase() == widget.estado!.toLowerCase(),
          );
        } catch (e) {
          // Estado não encontrado na lista, ignora
        }
      }

      setState(() {
        _estados = estados;
        _estadosCarregando = false;
        if (estadoInicial != null) {
          _estadoSelecionado = estadoInicial;
          _carregarCidades(estadoInicial.id);
        }
      });
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar estados: $e'), backgroundColor: Colors.red));
        setState(() => _estadosCarregando = false);
      }
    }
  }

  Future<void> _carregarCidades(int estadoId) async {
    setState(() {
      _cidadesCarregando = true;
      // Limpa a seleção de cidade anterior ao carregar uma nova lista
      _cidadeSelecionada = null;
    });
    try {
      final cidades = await _ibgeService.getCidadesPorEstado(estadoId);
      if (!mounted) return;

      Cidade? cidadeInicial;
      if (widget.cidade != null) {
        try {
          cidadeInicial = cidades.firstWhere(
            (c) => c.nome.toLowerCase() == widget.cidade!.toLowerCase(),
          );
        } catch (e) {
          // Cidade não encontrada na lista, ignora
        }
      }

      setState(() {
        _cidades = cidades;
        _cidadesCarregando = false;
        _cidadeSelecionada = cidadeInicial;
      });
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar cidades: $e'), backgroundColor: Colors.red));
        setState(() => _cidadesCarregando = false);
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cepController.dispose();
    _ruaController.dispose();
    _numeroController.dispose();
    _horariosController.dispose();
    _infoController.dispose();
    super.dispose();
  }

  Future<void> _enviarFormulario() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      // Only create an Endereco object if address fields are filled
      Endereco? novoEndereco;
      if (_ruaController.text.isNotEmpty || _cidadeSelecionada != null) {
        final cepLimpo = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');

        novoEndereco = Endereco(
          id: 0, // Backend will generate the ID
          rua: _ruaController.text,
          numero: int.tryParse(_numeroController.text),
          cidade: _cidadeSelecionada?.nome,
          estado: _estadoSelecionado?.sigla,
          cep: cepLimpo,
          latitude: widget.latitude,
          longitude: widget.longitude,
        );
      }

      final novoLocal = Local(
        id: 0, // Backend will generate
        nome: _nomeController.text,
        aprovado: false, // New locations should require approval
        endereco: novoEndereco,
        tipoAtividadeId: _tipoAtividadeId!,
        tipoAcessoId: _tipoAcessoId!,
        tipoLocalId: _tipoLocalId,
        horariosFuncionamento: _horariosController.text,
        informacoesAdicionais: _infoController.text,
      );

      try {
        await context.read<LocaisRepository>().cadastrarLocal(novoLocal);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Local indicado com sucesso! Aguardando aprovação.'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao cadastrar local: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Indicar Novo Local'),
          backgroundColor: const Color(0xFF528265),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(labelText: 'Nome do Local'),
                    validator: (value) => (value?.isEmpty ?? true) ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 16.0),
                  DropdownButtonFormField<int>(
                    value: _tipoLocalId,
                    decoration: const InputDecoration(labelText: 'Tipo de Local'),
                    items: _tiposDeLocal.entries.map((entry) {
                      return DropdownMenuItem<int>(value: entry.key, child: Text(entry.value));
                    }).toList(),
                    onChanged: (value) => setState(() => _tipoLocalId = value),
                    validator: (value) => value == null ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 16.0),
                  DropdownButtonFormField<int>(
                    value: _tipoAtividadeId,
                    decoration: const InputDecoration(labelText: 'Principal Atividade Física'),
                    items: _tiposDeAtividade.entries.map((entry) {
                      return DropdownMenuItem<int>(value: entry.key, child: Text(entry.value));
                    }).toList(),
                    onChanged: (value) => setState(() => _tipoAtividadeId = value),
                    validator: (value) => value == null ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 16.0),
                  DropdownButtonFormField<int>(
                    value: _tipoAcessoId,
                    decoration: const InputDecoration(labelText: 'Tipo de Acesso'),
                    items: _tiposDeAcesso.entries.map((entry) {
                      return DropdownMenuItem<int>(value: entry.key, child: Text(entry.value));
                    }).toList(),
                    onChanged: (value) => setState(() => _tipoAcessoId = value),
                    validator: (value) => value == null ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _horariosController,
                    decoration: const InputDecoration(labelText: 'Horários de funcionamento (Ex: 08:00 - 18:00)'),
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _infoController,
                    decoration: const InputDecoration(labelText: 'Informações adicionais'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24.0),
                  const Text("Endereço (Opcional)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  TextFormField(controller: _ruaController, decoration: const InputDecoration(labelText: 'Rua')),
                  TextFormField(controller: _numeroController, decoration: const InputDecoration(labelText: 'Número'), keyboardType: TextInputType.number),
                  const SizedBox(height: 16.0),
                  DropdownButtonFormField<Estado>(
                    value: _estadoSelecionado,
                    hint: Text(_estadosCarregando ? 'Carregando...' : 'Selecione o Estado'),
                    isExpanded: true,
                    items: _estados.map((Estado estado) {
                      return DropdownMenuItem<Estado>(
                        value: estado,
                        child: Text(estado.nome),
                      );
                    }).toList(),
                    onChanged: _estadosCarregando ? null : (Estado? novoEstado) {
                      if (novoEstado != null) {
                        setState(() {
                          _estadoSelecionado = novoEstado;
                          _cidadeSelecionada = null;
                          _cidades = [];
                        });
                        _carregarCidades(novoEstado.id);
                      }
                    },
                  ),
                  const SizedBox(height: 16.0),
                  DropdownButtonFormField<Cidade>(
                    value: _cidadeSelecionada,
                    hint: Text(_cidadesCarregando ? 'Carregando...' : 'Selecione a Cidade'),
                    isExpanded: true,
                    items: _cidades.map((Cidade cidade) {
                      return DropdownMenuItem<Cidade>(
                        value: cidade,
                        child: Text(cidade.nome),
                      );
                    }).toList(),
                    onChanged: (_estadoSelecionado == null || _cidadesCarregando) ? null : (Cidade? novaCidade) {
                      setState(() {
                        _cidadeSelecionada = novaCidade;
                      });
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(controller: _cepController, decoration: const InputDecoration(labelText: 'CEP'), keyboardType: TextInputType.number),
                  const SizedBox(height: 24.0),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _enviarFormulario,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF528265),
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                        : const Text('Enviar Indicação', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}
