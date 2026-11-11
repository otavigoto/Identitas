import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'turmas_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    // TODO backend: autenticar antes de navegar.
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const TurmasPage()));
  }

  InputDecoration _decoration(String hint, {Widget? suffix}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      fontSize: 13,
      height: 1,
      fontWeight: FontWeight.w200,
      fontStyle: FontStyle.italic,
      color: Color(0x80000000),
      letterSpacing: -0.5,
    ),
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: const BorderSide(color: Color(0xFF1E1E1E)),
    ),
    errorStyle: const TextStyle(fontSize: 12),
    errorMaxLines: 2,
    suffixIcon: suffix,
    suffixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 24),
  );

  Widget _form() {
    const labelStyle = TextStyle(
      fontSize: 20,
      height: 1.1,
      fontWeight: FontWeight.bold,
      letterSpacing: -1.4,
      color: Color(0xFF1E1E1E),
    );
    const inputStyle = TextStyle(
      fontSize: 13,
      height: 1.2,
      color: Colors.black,
    );
    return Container(
      width: 328,
      padding: const EdgeInsets.fromLTRB(29, 12, 29, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FF2E),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Text('Email / RA', style: labelStyle),
              ),
              TextFormField(
                key: const Key('login-identifier'),
                controller: _identifier,
                style: inputStyle,
                decoration: _decoration('ex: seuemail@instituicao.edu.br'),
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.username],
                autocorrect: false,
                onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe seu email ou RA.'
                    : null,
              ),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Text('Senha', style: labelStyle),
              ),
              TextFormField(
                key: const Key('login-password'),
                controller: _password,
                focusNode: _passwordFocus,
                style: inputStyle,
                obscureText: _obscurePassword,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (value) => value == null || value.isEmpty
                    ? 'Informe sua senha.'
                    : null,
                decoration: _decoration(
                  'ex: suasenha',
                  suffix: IconButton(
                    tooltip: _obscurePassword
                        ? 'Mostrar senha'
                        : 'Ocultar senha',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 24,
                    ),
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    iconSize: 17,
                    color: const Color(0xFF1E1E1E),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.white,
    ),
    child: Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final topSpace = (constraints.maxHeight * 127 / 778).clamp(
              24.0,
              127.0,
            );
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  minWidth: constraints.maxWidth,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      SizedBox(height: topSpace),
                      Image.asset(
                        'assets/images/identitas-logo.png',
                        width: 107,
                        height: 107,
                        fit: BoxFit.contain,
                        semanticLabel: 'Identitas',
                      ),
                      // O PNG inclui margem transparente; aproxima o título como no Figma.
                      Transform.translate(
                        offset: const Offset(0, -14),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 40,
                            height: 1,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -12),
                        child: const Text(
                          'Bem-vindo de volta',
                          style: TextStyle(
                            fontSize: 20,
                            height: 1.4,
                            fontWeight: FontWeight.w200,
                            color: Color(0xB3000000),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _form(),
                      ),
                      const SizedBox(height: 32),
                      const Spacer(),
                      SizedBox(
                        width: 165,
                        height: 51,
                        child: FilledButton(
                          onPressed: _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1E1E1E),
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            textStyle: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -1.4,
                                ),
                          ),
                          child: const Text('Entrar'),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}
