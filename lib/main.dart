import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const back4AppBaseUrl = 'https://parseapi.back4app.com/classes/ceps';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _cepController = TextEditingController();
  String _errorMessage = "";
  String _cepResponse = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Consulta de CEP'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _cepController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'CEP (Formato: 00000000)'),
            ),
            ElevatedButton(
              onPressed: () async {
                final cep = _cepController.text;

                if (isValidCep(cep)) {
                  final viaCepUrl = 'https://viacep.com.br/ws/$cep/json/';
                  final response = await http.get(Uri.parse(viaCepUrl));

                  if (response.statusCode == 200) {
                    final data = json.decode(response.body);
                    _cepResponse =
                        "Cidade: ${data['localidade']}, UF: ${data['uf']}";
                    sendCepToBack4App(cep, data);
                  } else {
                    _cepResponse = "CEP não encontrado";
                  }
                } else {
                  _cepResponse = "CEP inválido";
                }

                setState(() {});
              },
              child: Text('Consultar e cadastrar CEP'),
            ),
            Text(_errorMessage, style: TextStyle(color: Colors.red)),
            Text(_cepResponse),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ListCepsScreen()),
                );
              },
              child: Text('Listar CEPs'),
            ),
          ],
        ),
      ),
    );
  }

  bool isValidCep(String cep) {
    final cepRegExp = RegExp(r'^\d{8}$');
    return cepRegExp.hasMatch(cep);
  }

  Future<void> sendCepToBack4App(
      String cep, Map<String, dynamic> viaCepData) async {
    final url = Uri.parse(back4AppBaseUrl);
    final response = await http.post(
      url,
      headers: {
        'X-Parse-Application-Id': '', //virá do .env
        'X-Parse-REST-API-Key': '', //virá do .env
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'cep': cep,
        'city': viaCepData['localidade'],
        'state': viaCepData['uf'],
      }),
    );

    if (response.statusCode == 201) {
    } else {
      print('Erro ao enviar CEP para o Back4App: ${response.body}');
    }
  }
}

class ListCepsScreen extends StatefulWidget {
  @override
  _ListCepsScreenState createState() => _ListCepsScreenState();
}

class _ListCepsScreenState extends State<ListCepsScreen> {
  List<Map<String, dynamic>> ceps = [];

  @override
  void initState() {
    super.initState();
    fetchCepsFromBack4App();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de CEPs'),
      ),
      body: ListView.builder(
        itemCount: ceps.length,
        itemBuilder: (context, index) {
          final cep = ceps[index];
          return ListTile(
            title: Text('CEP: ${cep['cep']}'),
            subtitle: Text('Cidade: ${cep['city']}, UF: ${cep['state']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditCepScreen(cep),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    deleteCepFromBack4App(cep['objectId']);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> fetchCepsFromBack4App() async {
    final url = Uri.parse(back4AppBaseUrl);
    final response = await http.get(
      url,
      headers: {
        'X-Parse-Application-Id': '', //virá do .env
        'X-Parse-REST-API-Key': '', //virá do .env
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ceps = List<Map<String, dynamic>>.from(data['results']);
      setState(() {});
    } else {
      print('Erro ao buscar CEPs do Back4App: ${response.body}');
    }
  }

  Future<void> deleteCepFromBack4App(String objectId) async {
    final url = Uri.parse('$back4AppBaseUrl/$objectId');
    final response = await http.delete(
      url,
      headers: {
        'X-Parse-Application-Id': '', //virá do .env
        'X-Parse-REST-API-Key': '', //virá do .env
      },
    );

    if (response.statusCode == 200) {
      fetchCepsFromBack4App();
    } else {
      print('Erro ao excluir CEP do Back4App: ${response.body}');
    }
  }
}

class EditCepScreen extends StatefulWidget {
  final Map<String, dynamic> cep;

  EditCepScreen(this.cep);

  @override
  _EditCepScreenState createState() => _EditCepScreenState();
}

class _EditCepScreenState extends State<EditCepScreen> {
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cepController.text = widget.cep['cep'];
    _cityController.text = widget.cep['city'];
    _stateController.text = widget.cep['state'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar CEP'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _cepController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'CEP (Formato: 00000000)'),
            ),
            TextField(
              controller: _cityController,
              decoration: InputDecoration(labelText: 'Cidade'),
            ),
            TextField(
              controller: _stateController,
              decoration: InputDecoration(labelText: 'Estado'),
            ),
            ElevatedButton(
              onPressed: () async {
                final cep = _cepController.text;
                final city = _cityController.text;
                final state = _stateController.text;

                if (isValidCep(cep)) {
                  updateCepInBack4App(widget.cep['objectId'], cep, city, state);
                } else {}
              },
              child: Text('Salvar Alterações'),
            ),
          ],
        ),
      ),
    );
  }

  bool isValidCep(String cep) {
    final cepRegExp = RegExp(r'^\d{8}$');
    return cepRegExp.hasMatch(cep);
  }

  Future<void> updateCepInBack4App(
      String objectId, String cep, String city, String state) async {
    final url = Uri.parse('$back4AppBaseUrl/$objectId');
    final response = await http.put(
      url,
      headers: {
        'X-Parse-Application-Id': '', //virá do .env
        'X-Parse-REST-API-Key': '', //virá do .env
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'cep': cep,
        'city': city,
        'state': state,
      }),
    );

    if (response.statusCode == 200) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ListCepsScreen()),
      );
    } else {
      print('Erro ao atualizar CEP no Back4App: ${response.body}');
    }
  }
}
