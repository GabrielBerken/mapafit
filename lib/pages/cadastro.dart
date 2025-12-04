import 'package:flutter/material.dart';
import 'package:mapafit/controllers/usuario_controller.dart' show cadastrarUsuario;
import 'package:mapafit/models/cidade_model.dart';
import 'package:mapafit/models/endereco_model.dart';
import 'package:mapafit/models/estado_model.dart';
import 'package:mapafit/models/usuario_model.dart';
import 'package:mapafit/services/ibge_service.dart';

import 'cadastrado/login_page.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  _CadastroPageState createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _cepController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _isLoading = false;

  // State for IBGE dropdowns
  final IbgeService _ibgeService = IbgeService();
  List<Estado> _estados = [];
  List<Cidade> _cidades = [];
  Estado? _estadoSelecionado;
  Cidade? _cidadeSelecionada;
  bool _estadosCarregando = true;
  bool _cidadesCarregando = false;

  @override
  void initState() {
    super.initState();
    _carregarEstados();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _ruaController.dispose();
    _numeroController.dispose();
    _cepController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      // Cria o objeto de endereço apenas se o usuário preencheu os campos
      Endereco? novoEndereco;
      if (_ruaController.text.isNotEmpty || _cidadeSelecionada != null) {
        novoEndereco = Endereco(
          id: 0,
          rua: _ruaController.text,
          numero: int.tryParse(_numeroController.text),
          cidade: _cidadeSelecionada?.nome,
          estado: _estadoSelecionado?.sigla,
          cep: _cepController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        );
      }

      final novoUsuario = Usuario(
        id: 0,
        // O backend irá gerar o ID
        nome: _nomeController.text,
        email: _emailController.text,
        telefone: _telefoneController.text.isNotEmpty
            ? _telefoneController.text
            : null,
        senha: _senhaController.text,
        tipoUsuario: TipoUsuario.CADASTRADO,
        endereco: novoEndereco, // Pode ser nulo
      );

      try {
        await cadastrarUsuario(novoUsuario);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cadastro realizado com sucesso! Faça o login.'),
              backgroundColor: Colors.green,
            ),
          );
          // Navega para a tela de login, limpando as telas anteriores.
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
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
  }

  Future<void> _carregarEstados() async {
    try {
      final estados = await _ibgeService.getEstados();
      if (mounted) {
        setState(() {
          _estados = estados;
          _estadosCarregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao carregar estados: $e')));
        setState(() => _estadosCarregando = false);
      }
    }
  }

  Future<void> _carregarCidades(int estadoId) async {
    setState(() {
      _cidadesCarregando = true;
      _cidadeSelecionada = null;
    });
    try {
      final cidades = await _ibgeService.getCidadesPorEstado(estadoId);
      if (mounted) setState(() => _cidades = cidades);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar cidades: $e')));
    } finally {
      if (mounted) setState(() => _cidadesCarregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Criar Conta'),
          backgroundColor: const Color(0xFF528265),
        ),
        backgroundColor: Colors.white, // Cor de fundo da tela
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20.0),
                  Center(
                    // Centraliza a logo
                    child: Image.asset(
                      'lib/assets/mapafit.png', // caminho da imagem
                      height: 150.0,
                    ),
                  ),
                  const SizedBox(height: 40.0),
                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome Completo',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                    (value?.isEmpty ?? true)
                        ? 'Por favor, insira seu nome'
                        : null,
                  ),
                  const SizedBox(height: 20.0),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty ||
                          !value.contains('@')) {
                        return 'Por favor, insira um email válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20.0),
                  TextFormField(
                    controller: _telefoneController,
                    decoration: const InputDecoration(
                      labelText: 'Telefone (Opcional)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16.0),
                  // Envolve os campos de endereço em um ExpansionTile para ocultá-los por padrão.
                  ExpansionTile(
                    title: const Text("Adicionar Endereço (Opcional)"),
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(top: 16.0),
                    children: [
                      TextFormField(
                        controller: _ruaController,
                        decoration: const InputDecoration(
                            labelText: 'Rua', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 20.0),
                      TextFormField(
                        controller: _numeroController,
                        decoration: const InputDecoration(
                            labelText: 'Número', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 20.0),
                      DropdownButtonFormField<Estado>(
                        value: _estadoSelecionado,
                        hint: Text(_estadosCarregando
                            ? 'Carregando...'
                            : 'Selecione o Estado'),
                        isExpanded: true,
                        items: _estados.map((Estado estado) {
                          return DropdownMenuItem<Estado>(
                              value: estado, child: Text(estado.nome));
                        }).toList(),
                        onChanged: _estadosCarregando ? null : (
                            Estado? novoEstado) {
                          if (novoEstado != null) {
                            setState(() => _estadoSelecionado = novoEstado);
                            _carregarCidades(novoEstado.id);
                          }
                        },
                        decoration: const InputDecoration(
                            border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 20.0),
                      DropdownButtonFormField<Cidade>(
                        value: _cidadeSelecionada,
                        hint: Text(_cidadesCarregando
                            ? 'Carregando...'
                            : 'Selecione a Cidade'),
                        isExpanded: true,
                        items: _cidades.map((Cidade cidade) {
                          return DropdownMenuItem<Cidade>(
                              value: cidade, child: Text(cidade.nome));
                        }).toList(),
                        onChanged: (_estadoSelecionado == null ||
                            _cidadesCarregando) ? null : (Cidade? novaCidade) {
                          setState(() => _cidadeSelecionada = novaCidade);
                        },
                        decoration: const InputDecoration(
                            border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 20.0),
                      TextFormField(
                        controller: _cepController,
                        decoration: const InputDecoration(
                            labelText: 'CEP', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20.0),
                  TextFormField(
                    controller: _senhaController,
                    decoration: const InputDecoration(
                      labelText: 'Senha',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'A senha deve ter pelo menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30.0),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF528265),
                      // Cor de fundo do botão
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 3),
                    )
                        : const Text('Cadastrar',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                  const SizedBox(height: 20.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Já tem uma conta? '),
                      GestureDetector(
                        onTap: () {
                          // Usa pushReplacement para substituir a tela de cadastro pela de login,
                          // melhorando o fluxo de navegação.
                          Navigator.pushReplacement(context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginPage()));
                        },
                        child: const Text(
                          'Faça login',
                          style: TextStyle(
                            color: Color(0xFF528265), // Cor do link
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )));
  }
}
