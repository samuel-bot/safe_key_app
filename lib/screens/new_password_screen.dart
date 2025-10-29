import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key, required String apiBase});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final String apiBase = "https://safekey-api-a1bd9aa97953.herokuapp.com";
  String? generatedPassword;
  bool isLoading = false;

  int passwordLength = 12;
  bool includeLowercase = true;
  bool includeUppercase = true;
  bool includeNumbers = true;
  bool includeSymbols = true;

  // Usuário logado
  User? get _currentUser => FirebaseAuth.instance.currentUser;

  Future<void> _generatePassword() async {
    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$apiBase/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "length": passwordLength,
          "includeNumbers": includeNumbers,
          "includeSymbols": includeSymbols,
          "includeUppercase": includeUppercase,
          "includeLowercase": includeLowercase,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          generatedPassword = data['password'];
        });
        _showSnackBar('Senha gerada com sucesso!');
      } else {
        _showSnackBar('Erro ao gerar senha.');
      }
    } catch (e) {
      _showSnackBar('Erro de conexão com o servidor.');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _showSaveDialog() async {
    final TextEditingController titleController = TextEditingController();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Salvar senha'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Tipo da senha'),
              const SizedBox(height: 8),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  hintText: 'ex: Email, WiFi, Banco',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Digite um tipo de senha!')),
                  );
                  return;
                }
                Navigator.pop(context);
                _savePassword(title);
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _savePassword(String title) async {
    if (generatedPassword == null) return;
    if (_currentUser == null) {
      _showSnackBar('Usuário não logado!');
      return;
    }

    final senhaData = <String, dynamic>{
      'title': title,
      'password': generatedPassword,
      'length': passwordLength,
      'createdAt': FieldValue.serverTimestamp(),
      'types': {
        'lowercase': includeLowercase,
        'uppercase': includeUppercase,
        'numbers': includeNumbers,
        'symbols': includeSymbols,
      },
    };

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('passwords')
          .add(senhaData);

      _showSnackBar('Senha salva com sucesso!');
      setState(() {
        generatedPassword = null;
      });
      Navigator.pop(context); // Volta pra Home
    } catch (e) {
      _showSnackBar('Erro ao salvar: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 243, 33, 68),
        title: const Text(
          'Gerador de Senhas',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Tooltip(
            message:
                'App para gerar senhas seguras e armazená-las com segurança no Firebase, protegidas por usuário logado.',
            preferBelow: false,
            child: IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  // ignore: deprecated_member_use
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, color: Color.fromARGB(255, 243, 33, 51)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      generatedPassword ?? 'Senha não informada',
                      style: TextStyle(
                        fontSize: 16,
                        color: generatedPassword != null
                            ? Colors.black87
                            : Colors.grey[600],
                        fontWeight: generatedPassword != null
                            ? FontWeight.w500
                            : null,
                      ),
                    ),
                  ),
                  if (generatedPassword != null)
                    IconButton(
                      icon: const Icon(Icons.copy, color: Color.fromARGB(255, 243, 33, 33)),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: generatedPassword!),
                        );
                        _showSnackBar('Senha copiada!');
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // SLIDER
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tamanho da senha: $passwordLength',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                Slider(
                  value: passwordLength.toDouble(),
                  min: 4,
                  max: 32,
                  divisions: 28,
                  activeColor: const Color.fromARGB(255, 243, 33, 51),
                  inactiveColor: Colors.grey[300],
                  onChanged: (value) =>
                      setState(() => passwordLength = value.round()),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // SWITCHES
            _buildSwitch(
              'Incluir letras minúsculas',
              includeLowercase,
              (v) => setState(() => includeLowercase = v),
            ),
            _buildSwitch(
              'Incluir letras maiúsculas',
              includeUppercase,
              (v) => setState(() => includeUppercase = v),
            ),
            _buildSwitch(
              'Incluir números',
              includeNumbers,
              (v) => setState(() => includeNumbers = v),
            ),
            _buildSwitch(
              'Incluir símbolos',
              includeSymbols,
              (v) => setState(() => includeSymbols = v),
            ),
            const Spacer(),

            // BOTÃO GERAR
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : _generatePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 243, 33, 51),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Gerar Senha',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: generatedPassword != null
          ? FloatingActionButton(
              backgroundColor: const Color.fromARGB(255, 196, 4, 4),
              onPressed: _showSaveDialog, // ABRE DIALOG
              child: const Icon(Icons.save, color: Colors.white),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildSwitch(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 15)),
      value: value,
      activeThumbColor: const Color.fromARGB(255, 243, 33, 68),
      onChanged: onChanged,
    );
  }
}
