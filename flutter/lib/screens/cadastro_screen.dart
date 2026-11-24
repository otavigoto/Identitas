import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens_shared.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _form = GlobalKey<FormState>();

  String? _obrigatorio(String? value) =>
      value == null || value.trim().isEmpty ? 'Campo obrigatório' : null;

  String? _email(String? value) {
    if (_obrigatorio(value) != null) return 'Campo obrigatório';
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!.trim())
        ? null
        : 'Email inválido';
  }

  String? _ra(String? value) {
    if (_obrigatorio(value) != null) return 'Campo obrigatório';
    return RegExp(r'^\d+$').hasMatch(value!.trim())
        ? null
        : 'Use apenas números';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IdentitasColors.branco,
      appBar: AppBar(
        backgroundColor: IdentitasColors.branco,
        surfaceTintColor: Colors.transparent,
        foregroundColor: IdentitasColors.preto,
        elevation: 0,
      ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          top: false,
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
              children: [
                Image.asset(
                  'assets/images/identitas-logo.png',
                  width: 84,
                  height: 84,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Que bom que\nvocê chegou.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: IdentitasColors.preto,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vamos fazer seu cadastro?',
                  textAlign: TextAlign.center,
                  style: identitasText(
                    size: 14,
                    weight: FontWeight.w400,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                  decoration: BoxDecoration(
                    color: IdentitasColors.amarelo,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      _Campo('Nome Completo', 'Seu nome completo', _obrigatorio),
                      _Campo('Instituição', 'Ex: PUC Campinas', _obrigatorio),
                      _Campo(
                        'Email Institucional',
                        'seu.email@instituicao.edu.br',
                        _email,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      _Campo(
                        'Registro do Aluno (RA)',
                        'Ex: 24012345',
                        _ra,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: IdentitasColors.preto,
                      foregroundColor: IdentitasColors.branco,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 36,
                        vertical: 14,
                      ),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () {
                      if (!_form.currentState!.validate()) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cadastro enviado')),
                      );
                    },
                    child: const Text(
                      'Registre-se',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
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
  const _Campo(
    this.label,
    this.hint,
    this.validator, {
    this.keyboardType,
  });

  final String label;
  final String hint;
  final FormFieldValidator<String> validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: IdentitasColors.preto,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            validator: validator,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: identitasText(
                size: 12,
                weight: FontWeight.w400,
                color: Colors.black38,
              ),
              filled: true,
              fillColor: IdentitasColors.branco,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              errorStyle: const TextStyle(
                fontSize: 11,
                color: Color(0xFFB00020),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
