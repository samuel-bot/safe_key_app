import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'new_password_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;
  final Map<String, bool> _passwordVisibility = {};

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    // Garante que o usuário está logado
    if (_currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      });
    }
  }

  void _logout() async {
    await _auth.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _deletePassword(String passwordId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('passwords')
          .doc(passwordId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Senha deletada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao deletar senha: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Senha copiada para a área de transferência!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _togglePasswordVisibility(String passwordId) {
    setState(() {
      _passwordVisibility[passwordId] =
          !(_passwordVisibility[passwordId] ?? false);
    });
  }

  Widget _buildPremiumBanner() {
    return Center(
      child: Container(
        width: 700,
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(1)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Lottie.asset(
                'assets/lottie/premium_banner.json',
                fit: BoxFit.contain,
                width: constraints.maxWidth,
                height: 150,
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Se o usuário não estiver logado
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Carregando usuário...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text(
            'Gerador de Senhas',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Sair',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16, right: 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _currentUser?.email ?? 'Não identificado',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
          _buildPremiumBanner(),
          const SizedBox(height: 8),

          // LISTA DE SENHAS
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(_currentUser!.uid)
                  .collection('passwords')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Erro ao carregar senhas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Carregando senhas...'),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: Lottie.asset(
                            'assets/lottie/empty_list.json',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Nenhum registro encontrado',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Adicione uma senha para começar!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    String passwordId = doc.id;
                    bool isVisible = _passwordVisibility[passwordId] ?? false;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: ListTile(
                        title: Text(
                          data['title'] ?? 'Sem título',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          isVisible ? data['password'] ?? '' : '•' * 10,
                          style: const TextStyle(
                            fontFamily: 'Monospace',
                            fontSize: 16,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                isVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.blue,
                              ),
                              onPressed: () =>
                                  _togglePasswordVisibility(passwordId),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deletePassword(passwordId),
                            ),
                          ],
                        ),
                        onTap: () => _copyToClipboard(data['password'] ?? ''),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NewPasswordScreen(
                apiBase: 'https://safekey-api-a1bd9aa97953.herokuapp.com',
              ),
            ),
          );
        },
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}