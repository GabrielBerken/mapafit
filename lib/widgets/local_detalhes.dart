import 'package:flutter/material.dart';
import 'package:mapafit/models/local_model.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:mapafit/pages/cadastrado/checkin_page.dart';
import 'package:provider/provider.dart';
import 'package:mapafit/providers/user_provider.dart';

class LocalDetalhes extends StatelessWidget {
  final Local local;

  const LocalDetalhes({Key? key, required this.local}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userType = context.watch<UserProvider>().userType;
    final endereco = local.endereco;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            local.nome,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            local.horariosFuncionamento ?? 'Horário não informado',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Outras Informações:",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          if (endereco != null)
            Text(
              'Endereço: ${endereco.rua ?? 'Rua não informada'}, ${endereco.numero ?? 'S/N'}\n${endereco.cidade ?? ''} - ${endereco.estado ?? ''}, CEP: ${endereco.cep ?? 'Não informado'}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            )
          else
            const Text(
              'Endereço não cadastrado.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          Text(
            "Descrição: ${local.informacoesAdicionais ?? 'Nenhuma.'}",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 24),
          if (userType != UserType.loggedOutUser && local.distancia != null && local.distancia! <= 0.2)
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CheckinPage(local: local),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  backgroundColor: const Color(0xFF72B98F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  "Check-in",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (endereco != null && endereco.latitude != null && endereco.longitude != null)
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  final availableMaps = await MapLauncher.installedMaps;
                  await availableMaps.first.showMarker(
                    coords: Coords(endereco.latitude!, endereco.longitude!),
                    title: local.nome,
                    description: local.informacoesAdicionais ?? '',
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                  backgroundColor: const Color(0xFF528265),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  "Buscar rotas",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
