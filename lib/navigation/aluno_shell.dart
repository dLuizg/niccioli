import 'package:flutter/material.dart';
import '../screens/home_aluno/home_aluno.dart';
import '../screens/contrato_aluno/contrato_aluno.dart';
import '../widgets/app_bottom_nav.dart';
import '../theme/app_colors.dart';

// Shell de navegação do aluno — gerencia o AppBottomNav compartilhado
// e o IndexedStack que preserva o estado de cada tela ao trocar de aba.
class AlunoShell extends StatefulWidget {
  const AlunoShell({super.key});

  @override
  State<AlunoShell> createState() => _AlunoShellState();
}

class _AlunoShellState extends State<AlunoShell> {
  // Índice da aba ativa — 0 = Home, 1 = Contrato, 2 = Mapa, 3 = Financeiro, 4 = Perfil
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // IndexedStack preserva o estado de cada tela ao navegar entre abas
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeAluno(),
          const ContratoAluno(),
          _buildPlaceholder('Mapa'),
          _buildPlaceholder('Financeiro'),
          _buildPlaceholder('Perfil'),
        ],
      ),
      // Único AppBottomNav da aplicação — compartilhado entre todas as telas
      bottomNavigationBar: AppBottomNav(
        selectedIndex: _currentIndex,
        onItemTapped: (i) => setState(() => _currentIndex = i),
      ),
    );
  }

  // Placeholder para abas ainda não implementadas
  Widget _buildPlaceholder(String label) {
    return Center(
      child: Text(
        label,
        style: const TextStyle(color: AppColors.white, fontSize: 20),
      ),
    );
  }
}
