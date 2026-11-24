import 'package:flutter/material.dart';

import 'turma.dart';
import 'turmas_api.dart';

/// Cria ou edita uma turma no backend e devolve o resultado via `pop`.
class TurmaFormPage extends StatefulWidget {
  const TurmaFormPage({super.key, required this.api, this.turma});

  final TurmasApi api;

  /// Null = criar nova turma.
  final Turma? turma;

  @override
  State<TurmaFormPage> createState() => _TurmaFormPageState();
}

class _TurmaFormPageState extends State<TurmaFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.turma?.name);
  late final _dia = TextEditingController(text: widget.turma?.week);
  late final _inicio = TextEditingController(text: widget.turma?.startTime);
  late final _fim = TextEditingController(text: widget.turma?.endTime);

  static final _horaValida = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');

  bool _salvando = false;

  bool get _editando => widget.turma != null;

  @override
  void dispose() {
    _nome.dispose();
    _dia.dispose();
    _inicio.dispose();
    _fim.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_salvando || !_formKey.currentState!.validate()) return;
    final atual = widget.turma;
    final nome = _nome.text.trim();
    final dia = _dia.text.trim();
    final inicio = _inicio.text.trim();
    final fim = _fim.text.trim();
    setState(() => _salvando = true);
    try {
      final resultado = atual == null
          ? await widget.api.criar(
              name: nome,
              week: dia,
              startTime: inicio,
              endTime: fim,
            )
          : await widget.api.atualizar(
              atual.id,
              name: nome,
              week: dia,
              startTime: inicio,
              endTime: fim,
            );
      if (mounted) Navigator.of(context).pop(resultado);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  String? _obrigatorio(String? v, String campo) =>
      v == null || v.trim().isEmpty ? 'Informe $campo.' : null;

  String? _hora(String? v, String campo) {
    final vazio = _obrigatorio(v, campo);
    if (vazio != null) return vazio;
    return _horaValida.hasMatch(v!.trim())
        ? null
        : 'Use o formato HH:mm (ex: 08:30).';
  }

  Widget _campo({
    required Key key,
    required String label,
    required String hint,
    required TextEditingController controller,
    required String erro,
    bool hora = false,
    TextInputAction action = TextInputAction.next,
    VoidCallback? onSubmit,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -1.4,
            color: Color(0xFF1E1E1E),
          ),
        ),
      ),
      TextFormField(
        key: key,
        controller: controller,
        textInputAction: action,
        onFieldSubmitted: onSubmit == null ? null : (_) => onSubmit(),
        validator: (v) => hora ? _hora(v, erro) : _obrigatorio(v, erro),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w200,
            fontStyle: FontStyle.italic,
            color: Color(0x80000000),
          ),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xFF1E1E1E)),
          ),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      title: Text(
        _editando ? 'Editar aula' : 'Nova aula',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: -1,
          color: Color(0xFF1E1E1E),
        ),
      ),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(21, 16, 21, 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FF2E),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _campo(
                      key: const Key('turma-nome'),
                      label: 'Disciplina',
                      hint: 'ex: Banco de Dados',
                      controller: _nome,
                      erro: 'a disciplina',
                    ),
                    const SizedBox(height: 8),
                    _campo(
                      key: const Key('turma-dia'),
                      label: 'Dia da semana',
                      hint: 'ex: Segunda-feira',
                      controller: _dia,
                      erro: 'o dia da semana',
                    ),
                    const SizedBox(height: 8),
                    _campo(
                      key: const Key('turma-inicio'),
                      label: 'Início',
                      hint: 'ex: 08:00',
                      controller: _inicio,
                      erro: 'o horário de início',
                      hora: true,
                    ),
                    const SizedBox(height: 8),
                    _campo(
                      key: const Key('turma-fim'),
                      label: 'Fim',
                      hint: 'ex: 09:40',
                      controller: _fim,
                      erro: 'o horário de fim',
                      hora: true,
                      action: TextInputAction.done,
                      onSubmit: _salvar,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: 165,
                  height: 51,
                  child: FilledButton(
                    key: const Key('turma-salvar'),
                    onPressed: _salvando ? null : _salvar,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1E1E1E),
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1.4,
                      ),
                    ),
                    child: _salvando
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Salvar'),
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
