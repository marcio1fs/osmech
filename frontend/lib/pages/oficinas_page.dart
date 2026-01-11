import 'package:flutter/material.dart';
import '../services/oficina_service.dart';
import 'oficina_form_page.dart';

class OficinasPage extends StatefulWidget {
  const OficinasPage({Key? key}) : super(key: key);

  @override
  State<OficinasPage> createState() => _OficinasPageState();
}

class _OficinasPageState extends State<OficinasPage> {
  late Future<List<Oficina>> _oficinasFuture;

  @override
  void initState() {
    super.initState();
    _oficinasFuture = OficinaService.getOficinas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Oficinas')),
      body: FutureBuilder<List<Oficina>>(
        future: _oficinasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma oficina cadastrada'));
          }
          final oficinas = snapshot.data!;
          return ListView.builder(
            itemCount: oficinas.length,
            itemBuilder: (context, index) {
              final oficina = oficinas[index];
              return Card(
                child: ListTile(
                  title: Text(oficina.nome),
                  subtitle: Text(oficina.endereco),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/oficina_form');
          if (result == true) {
            setState(() {
              _oficinasFuture = OficinaService.getOficinas();
            });
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Nova Oficina',
      ),
    );
  }
}
