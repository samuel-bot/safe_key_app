import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  bool _dontShowAgain = false;

  final List<Map<String, String>> _pages = [
    {
      'lottie': 'assets/lottie/shield.json',
      'title': 'Bem-vindo ao App',
      'subtitle': 'Aprenda a usar o app passo a passo.',
    },
    {
      'lottie': 'assets/lottie/security_lock_finger.json',
      'title': 'Funcionalidades',
      'subtitle': 'Explore as diversas funcionalidades.',
    },
    {
      'lottie': 'assets/lottie/password_security.json',
      'title': 'Vamos começar?',
      'subtitle': 'Pronto para usar o seu app com segurança.',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfShouldSkipIntro();
    });
  }

  Future<void> _checkIfShouldSkipIntro() async {
    final prefs = await SharedPreferences.getInstance();
    final bool? showIntro = prefs.getBool('show_intro');

    if (showIntro == false) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _goNext() async {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      if (_dontShowAgain) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('show_intro', false);
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _goBack() {
    if (_currentPage > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildCard(Map<String, String> page, int index) {
    final bool isLast = index == _pages.length - 1;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Conteúdo centralizado
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Lottie animação
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: Lottie.asset(
                        page['lottie']!,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      page['title']!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      page['subtitle']!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (isLast)
              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _dontShowAgain,
                        onChanged: (v) =>
                            setState(() => _dontShowAgain = v ?? false),
                      ),
                      const Expanded(
                        child: Text(
                          'Não mostrar essa introdução novamente.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Botão Voltar
            Positioned(
              left: 16,
              bottom: 16,
              child: _currentPage > 0
                  ? TextButton(
                      onPressed: _goBack,
                      child: const Text(
                        'Voltar',
                        style: TextStyle(
                          color: Color(0xFF2EA6F6),
                          fontSize: 13,
                        ),
                      ),
                    )
                  : const SizedBox(width: 70),
            ),

            // Botão Avançar/Concluir
            Positioned(
              right: 16,
              bottom: 16,
              child: TextButton(
                onPressed: _goNext,
                child: Text(
                  _currentPage == _pages.length - 1 ? 'Concluir' : 'Avançar',
                  style: const TextStyle(
                    color: Color(0xFF2EA6F6),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Indicadores de página
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  final bool active = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 18 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFF2EA6F6)
                          : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      itemCount: _pages.length,
      onPageChanged: (i) => setState(() => _currentPage = i),
      itemBuilder: (context, index) {
        return _buildCard(_pages[index], index);
      },
    );
  }
}