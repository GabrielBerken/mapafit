import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mapafit/controllers/checkin_controller.dart';
import 'package:mapafit/controllers/usuario_controller.dart';
import 'package:mapafit/models/checkin_model.dart';
import 'package:mapafit/models/usuario_model.dart';
import 'package:mapafit/pages/acesso_inicial.dart';
import 'package:mapafit/providers/user_provider.dart';
import 'package:provider/provider.dart';

import '../../components/bottom_template.dart';
import 'package:mapafit/utils/user_cache_helper.dart';
import '../../components/safe_network_avatar.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  Future<Usuario>? _fullUserFuture;
  Future<List<Checkin>>? _checkinsFuture;

  @override
  void initState() {
    super.initState();
    _loadUserDataFromCacheOnOpen();
    _loadCheckins();
  }

  Future<void> _loadCheckins() async {
    if (mounted) {
      final user = context.read<UserProvider>().currentUser;
      if (user != null) {
        setState(() {
          _checkinsFuture = buscaCheckins(userId: user.id);
        });
      }
    }
  }

  Future<void> _loadUserDataFromCacheOnOpen() async {
    final cached = await populateUserFromCacheIfAvailable(context);
    if (cached != null && mounted) {
      setState(() {
        _fullUserFuture = Future.value(cached);
      });
      return;
    }

    // Se não houver cache válido, carrega normalmente (pode fazer request)
    await _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (mounted) {
      setState(() {
        _fullUserFuture = null;
      });

      try {
        final user = context.read<UserProvider>().currentUser;
        if (user != null) {
          final userData = await fetchFullUserProfile(user.id);
          if (mounted) {
            setState(() {
              _fullUserFuture = Future.value(userData);
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _fullUserFuture = Future.error(e);
          });
        }
      }
    }
    _loadCheckins();
  }

  Future<void> _logout(BuildContext context) async {
    // Chama a função de logout para limpar o token local
    await logout();

    // Atualiza o estado do provedor para deslogado
    if (context.mounted) {
      context.read<UserProvider>().setUserType(UserType.loggedOutUser); // Isso também limpa o currentUser

      // Navega para a tela de acesso inicial e remove todas as telas anteriores
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const InicialPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lightUser = context.watch<UserProvider>().currentUser;
    final fotoUrl = lightUser?.fotoUrl;
    final temFoto = fotoUrl != null && fotoUrl.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _logout(context);
            },
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.pushNamed(context, '/configuracoes');
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.only(top: 20.0),
                child: SafeNetworkAvatar(
                    imageUrl: fotoUrl,
                    radius: 50.0,
                    placeholder: const Icon(Icons.person, size: 50, color: Colors.grey)),
              ),
              const SizedBox(height: 20.0),
              Align(
                  alignment: Alignment.center,
                  child: Text('Olá, ${lightUser?.nome ?? 'Usuário'}!',
                      style: Theme.of(context).textTheme.headlineSmall)),
              const SizedBox(height: 20.0),
              Column(
                children: [
                  FutureBuilder<Usuario>(
                      future: _fullUserFuture,
                      builder: (context, snapshot) {
                        if (_fullUserFuture == null) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Erro ao carregar o Perfil.'),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _loadUserData,
                                child: const Text('Tentar novamente'),
                              ),
                            ],
                          );
                        }

                        if (!snapshot.hasData) {
                          return const Center(child: Text('Nenhum dado encontrado.'));
                        }

                        final fullUser = snapshot.data!;
                        log('log do usuario carregado${snapshot.data!}');
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildSummaryCard(
                                  title: 'Conquista',
                                  icon: Icons.place,
                                  text: '${fullUser.avaliacoes.length} check-ins',
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),
                            const Text('Histórico de Check-ins',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            FutureBuilder<List<Checkin>>(
                              future: _checkinsFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                if (snapshot.hasError) {
                                  return Center(
                                      child: Text('Erro ao carregar histórico: ${snapshot.error}'));
                                }
                                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                  return const Center(child: Text('Nenhum check-in encontrado.'));
                                }
                                final checkins = snapshot.data!;
                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: checkins.length,
                                  itemBuilder: (context, index) {
                                    final checkin = checkins[index];
                                    return _buildCheckinHistoryTile(checkin);
                                  },
                                );
                              },
                            ),
                          ],
                        );
                      }),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const TemplateBarraInferior(),
    );
  }

  Widget _buildCheckinHistoryTile(Checkin checkin) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.place, color: Color(0xFF528265)),
        title: Text('Check-in em ${checkin.local?.nome}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Início: ${checkin.inicio.toLocal()} \n  Fim: ${checkin.fim?.toLocal()}'),
      ),
    );
  }

  Widget _buildSummaryCard(
      {required String title, required IconData icon, required String text}) {
    return Container(
      width: 120, // Largura fixa para cada card
      height: 220, // Altura fixa para cada card
      margin: const EdgeInsets.all(10.0),
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 3,
            blurRadius: 7,
            offset: const Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10.0),
          Icon(icon, size: 50.0),
          const SizedBox(height: 20.0),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
