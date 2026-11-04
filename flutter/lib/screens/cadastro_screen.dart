import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _form = GlobalKey<FormState>();

  String? _obrigatorio(String? v) => (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null;

  String? _email(String? v) {
    if (_obrigatorio(v) != null) return 'Campo obrigatório';
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v!.trim()) ? null : 'Email inválido';
  }

  String? _ra(String? v) {
    if (_obrigatorio(v) != null) return 'Campo obrigatório';
    return RegExp(r'^\d+$').hasMatch(v!.trim()) ? null : 'Use apenas números';
  }

  void _registrar() {
    if (!_form.currentState!.validate()) return;
    // ponytail: só feedback visual até existir o endpoint de cadastro no backend.
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cadastro enviado')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.branco,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        // Fundo branco: ícones da barra de status escuros.
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(28, 40, 28, 24),
            children: [
              // ponytail: ícone no lugar do logo do Figma; trocar pelo asset quando exportarem o logo.
              const Icon(Icons.wifi_tethering, size: 64, color: AppColors.preto),
              const SizedBox(height: 12),
              const Text('Que bom que\nvocê chegou.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.preto, fontSize: 32, fontWeight: FontWeight.bold, height: 1)),
              const SizedBox(height: 6),
              Text('Vamos fazer seu cadastro?',
                  textAlign: TextAlign.center, style: urbanist(size: 14, weight: FontWeight.w400, color: Colors.black54)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                decoration: BoxDecoration(color: AppColors.amarelo, borderRadius: BorderRadius.circular(24)),
                child: Column(
                  children: [
                    _Campo('Nome Completo', 'Seu nome completo', validator: _obrigatorio),
                    _Campo('Instituição', 'Ex: PUC Campinas', validator: _obrigatorio),
                    _Campo('Email Institucional', 'seu.email@instituicao.edu.br',
                        validator: _email, teclado: TextInputType.emailAddress),
                    _Campo('Registro do Aluno (RA)', 'Ex: 24012345', validator: _ra, teclado: TextInputType.number),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.preto,
                    foregroundColor: AppColors.branco,
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: _registrar,
                  child: const Text('Registre-se', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  const _Campo(this.rotulo, this.dica, {required this.validator, this.teclado});

  final String rotulo, dica;
  final FormFieldValidator<String> validator;
  final TextInputType? teclado;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rotulo, style: const TextStyle(color: AppColors.preto, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          TextFormField(
            validator: validator,
            keyboardType: teclado,
            style: urbanist(size: 13),
            decoration: InputDecoration(
              isDense: true,
              hintText: dica,
              hintStyle: urbanist(size: 12, weight: FontWeight.w400, color: Colors.black38),
              filled: true,
              fillColor: AppColors.branco,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              errorStyle: urbanist(size: 11, color: const Color(0xFFB00020)),
            ),
          ),
        ],
      ),
    );
  }
}
