import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../aluno_api.dart';
import '../api_client.dart';
import '../models.dart';
import 'disciplinas_page.dart';
import 'nfc_instrucao_page.dart';
import 'profile_screen.dart';

/// Home do aluno: próxima aula e resumo do dia, vindos de
/// `GET /classes/me/today`.
class HomePage extends StatefulWidget {
  const HomePage({super.key, this.api});

  final AlunoApi? api;

  static const _ink = Color(0xFF1E1E1E);
  static const _accent = Color(0xFFF9FF2E);
  static const _cream = Color(0xFFFEFFD9);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final AlunoApi _api = widget.api ?? AlunoApi();
  AulasDoDia? _hoje;
  String? _erro;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final hoje = await _api.aulasDeHoje();
      if (mounted) setState(() => _hoje = hoje);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.message);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  List<Aula> get _aulas => _hoje?.aulas ?? const [];

  /// Primeira aula de hoje que ainda não terminou e sem presença registrada.
  Aula? get _proxima {
    final agora = TimeOfDay.now();
    final minutosAgora = agora.hour * 60 + agora.minute;
    for (final a in _aulas) {
      if (a.present || a.attendanceRecorded) continue;
      if ((a.fimEmMinutos ?? 0) >= minutosAgora) return a;
    }
    return null;
  }

  _ClassStatus _statusDe(Aula a) {
    if (a.present) return _ClassStatus.present;
    if (a.attendanceRecorded) return _ClassStatus.absent;
    return a.id == _proxima?.id ? _ClassStatus.next : _ClassStatus.scheduled;
  }

  void _openClasses() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const DisciplinasPage()));
  }

  void _openProfile() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }

  void _openNfc() {
    final aula = _proxima ?? (_aulas.isEmpty ? null : _aulas.first);
    if (aula == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Nenhuma aula hoje para validar.')),
        );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NfcInstrucaoPage(
          nomeDisciplina: aula.name,
          onValidarPresenca: (uid) async {
            await _api.registrarPresencaProfessor(aula.id, uid);
            _carregar();
            return true;
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final proxima = _proxima;
    final nome = _hoje?.usuario.name ?? ApiClient.instance.session.name ?? '';
    return Scaffold(
      backgroundColor: HomePage._ink,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = (constraints.maxWidth * 0.075).clamp(24.0, 30.0);
            final cardWidth = (constraints.maxWidth - horizontal * 2).clamp(
              272.0,
              339.0,
            );

            return Stack(
              children: [
                Positioned.fill(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      25,
                      horizontal,
                      112,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth - horizontal * 2,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Olá,\n$nome',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        height: 0.95,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 17),
                                    const Text(
                                      'Identitas',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        height: 1,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _Avatar(onTap: _openProfile),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Próxima Aula',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              height: 1.6,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: cardWidth,
                            height: 213,
                            child: _NextClassCard(aula: proxima),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: cardWidth,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Resumo de Hoje',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      height: 1.6,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  key: const Key('ver-todas-aulas'),
                                  onPressed: _openClasses,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'ver todas',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_carregando)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: CircularProgressIndicator(
                                  color: HomePage._accent,
                                ),
                              ),
                            )
                          else if (_erro != null)
                            _Aviso(mensagem: _erro!, onTentar: _carregar)
                          else if (_aulas.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'Nenhuma aula hoje.',
                                style: TextStyle(color: Colors.white70),
                              ),
                            )
                          else
                            Column(
                              children: [
                                for (final a in _aulas) ...[
                                  SizedBox(
                                    width: cardWidth,
                                    child: _SummaryCard(
                                      time: a.horario,
                                      name: a.name,
                                      room: a.week,
                                      status: _statusDe(a),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 12,
                  child: Center(child: _NfcButton(onTap: _openNfc)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Abrir perfil',
      child: Material(
        color: HomePage._accent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 84,
            height: 84,
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/figma-user.svg',
                width: 48,
                height: 48,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NextClassCard extends StatelessWidget {
  const _NextClassCard({required this.aula});

  /// Null quando não há mais aulas hoje.
  final Aula? aula;

  @override
  Widget build(BuildContext context) {
    final aula = this.aula;
    if (aula == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: HomePage._accent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Text(
          'Nenhuma aula pendente hoje.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(19, 15, 19, 16),
      decoration: BoxDecoration(
        color: HomePage._accent,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 165,
              height: 29,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                'HOJE • ${aula.horario}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: HomePage._accent,
                  fontSize: 14,
                  height: 1,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 43,
            child: Text(
              aula.name,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 26,
                height: 0.95,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
              ),
            ),
          ),
          Positioned(
            left: 4,
            bottom: 6,
            child: Text(
              aula.week,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mensagem de erro com botão para tentar de novo (fundo escuro).
class _Aviso extends StatelessWidget {
  const _Aviso({required this.mensagem, required this.onTentar});

  final String mensagem;
  final VoidCallback onTentar;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(mensagem, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        FilledButton(
          key: const Key('home-tentar-novamente'),
          onPressed: onTentar,
          style: FilledButton.styleFrom(
            backgroundColor: HomePage._accent,
            foregroundColor: Colors.black,
          ),
          child: const Text('Tentar novamente'),
        ),
      ],
    ),
  );
}

enum _ClassStatus { present, absent, next, scheduled }

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.time,
    required this.name,
    required this.room,
    required this.status,
  });

  final String time;
  final String name;
  final String room;
  final _ClassStatus status;

  ({String label, Color background, Color dot}) get _statusStyle {
    switch (status) {
      case _ClassStatus.present:
        return (
          label: 'PRESENTE',
          background: const Color(0x5500FF1E),
          dot: const Color(0xFF25C84C),
        );
      case _ClassStatus.absent:
        return (
          label: 'AUSENTE',
          background: const Color(0x55E53935),
          dot: const Color(0xFFE53935),
        );
      case _ClassStatus.next:
        return (
          label: 'PRÓXIMA',
          background: const Color(0x55FF6A00),
          dot: const Color(0xFFFF6A00),
        );
      case _ClassStatus.scheduled:
        return (
          label: 'AGENDADO',
          background: const Color(0x554A4A4A),
          dot: const Color(0xFF6C6C6C),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusStyle;
    return Container(
      height: 92,
      padding: const EdgeInsets.fromLTRB(24, 8, 12, 8),
      decoration: BoxDecoration(
        color: HomePage._cream,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 92),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.event, size: 14, color: Color(0xFF1E1E1E)),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        room,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 10,
            top: 25,
            child: Container(
              height: 21,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              decoration: BoxDecoration(
                color: statusStyle.background,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: statusStyle.dot,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    statusStyle.label,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      height: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NfcButton extends StatelessWidget {
  const _NfcButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Validar presença por NFC',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
            border: Border.all(color: HomePage._accent, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x59000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x66F9FF2E), width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/icons/nfc_phone.svg',
                  width: 30,
                  height: 30,
                  colorFilter: const ColorFilter.mode(
                    HomePage._accent,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'NFC',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
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
