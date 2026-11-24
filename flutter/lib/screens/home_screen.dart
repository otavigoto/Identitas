import 'package:flutter/material.dart';

import 'carteirinha_screen.dart';
import 'historico_screen.dart';
import 'nfc_instrucao_page.dart';
import 'screens_shared.dart';
import '../services/auth_service.dart';
import '../services/attendance_service.dart';
import 'revisao_chamada_screen.dart';

enum StatusAula { presente, proxima, agendado }

class Aula {
  const Aula(this.horario, this.nome, this.sala, this.status);

  final String horario;
  final String nome;
  final String sala;
  final StatusAula status;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.nome = 'Odete Roitmann',
    this.user,
    this.attendanceService,
  });

  final String nome;
  final AuthUser? user;
  final AttendanceService? attendanceService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AttendanceService _attendance =
      widget.attendanceService ?? AttendanceService();
  List<AulaIdentitas> _aulas = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final user = widget.user;
    if (user == null) {
      setState(() => _carregando = false);
      return;
    }
    try {
      final aulas = user.isProfessor
          ? await _attendance.listForTeacher(user.id)
          : await _attendance.listForStudent(user.id);
      if (!mounted) return;
      setState(() {
        _aulas = aulas;
        _carregando = false;
        _erro = null;
      });
    } on AttendanceException catch (error) {
      if (!mounted) return;
      setState(() {
        _erro = error.message;
        _carregando = false;
      });
    }
  }

  Future<void> _abrirNfc(BuildContext context) async {
    if (widget.user?.isProfessor == true) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RevisaoChamadaScreen(
            classId: _aulas.isEmpty ? null : _aulas.first.id,
            initialDate: DateTime.now(),
            teacherId: widget.user?.id,
          ),
        ),
      );
      return;
    }

    if (_aulas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhuma aula disponível para validar presença.'),
        ),
      );
      return;
    }

    final aula = _aulas.first;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NfcInstrucaoPage(
          nomeDisciplina: aula.name,
          onValidarPresenca: (nfcUid) async {
            await _attendance.markAttendanceByNfc(
              aula.id,
              [nfcUid],
              date: DateTime.now(),
            );
            return true;
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IdentitasColors.fundo,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 112),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'Olá,\n${widget.nome}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            height: 0.95,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      InkResponse(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CarteirinhaScreen(),
                          ),
                        ),
                        radius: 42,
                        child: Container(
                          width: 84,
                          height: 84,
                          decoration: const BoxDecoration(
                            color: IdentitasColors.amarelo,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            size: 46,
                            color: IdentitasColors.preto,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Identitas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Próxima Aula',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _CardProximaAula(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Resumo de Hoje',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const HistoricoScreen(),
                          ),
                        ),
                        child: const Text(
                          'ver todas',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_carregando)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: IdentitasColors.amarelo,
                        ),
                      ),
                    )
                  else if (_erro != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Text(
                        _erro!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    )
                  else if (_aulas.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Text(
                        'Nenhuma aula encontrada.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  else
                    for (final aula in _aulas)
                      _CardAula(
                        Aula(
                          '${aula.startTime} - ${aula.endTime}',
                          aula.name,
                          'Turma ${aula.week}',
                          StatusAula.agendado,
                        ),
                      ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _abrirNfc(context),
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: IdentitasColors.preto,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: IdentitasColors.amarelo,
                          width: 3,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x59000000),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child:                       Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                          widget.user?.isProfessor == true
                              ? Icons.fact_check_outlined
                              : Icons.contactless,
                            color: IdentitasColors.amarelo,
                            size: 34,
                          ),
                          Text(
                          widget.user?.isProfessor == true
                              ? 'CHAMADA'
                              : 'NFC',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardProximaAula extends StatelessWidget {
  const _CardProximaAula();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: BoxDecoration(
        color: IdentitasColors.amarelo,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: IdentitasColors.preto,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'HOJE • 10:00 - 11:40',
              style: TextStyle(
                color: IdentitasColors.amarelo,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Engenharia de\nSoftware',
            style: TextStyle(
              color: IdentitasColors.preto,
              fontSize: 32,
              height: 1,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          const _InfoLinha(Icons.person_outline, 'Prof. Dr. Ricardo Almeida'),
          const SizedBox(height: 8),
          const _InfoLinha(Icons.location_on_outlined, 'Sala 204 - H15'),
        ],
      ),
    );
  }
}

class _CardAula extends StatelessWidget {
  const _CardAula(this.aula);

  final Aula aula;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
      decoration: BoxDecoration(
        color: IdentitasColors.creme,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  aula.horario,
                  style: const TextStyle(
                    color: IdentitasColors.preto,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _Selo(aula.status),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            aula.nome,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: IdentitasColors.preto,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          _InfoLinha(Icons.location_on_outlined, aula.sala),
        ],
      ),
    );
  }
}

class _Selo extends StatelessWidget {
  const _Selo(this.status);

  final StatusAula status;

  @override
  Widget build(BuildContext context) {
    final (texto, fundo, ponto) = switch (status) {
      StatusAula.presente => ('PRESENTE', const Color(0xFFB6F7A1), const Color(0xFF22C70B)),
      StatusAula.proxima => ('PRÓXIMA', const Color(0xFFFFD3A3), const Color(0xFFFF7A00)),
      StatusAula.agendado => ('AGENDADO', const Color(0xFFC9C9B8), const Color(0xFF5E5E5E)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: ponto),
          const SizedBox(width: 4),
          Text(
            texto,
            style: const TextStyle(
              color: IdentitasColors.preto,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLinha extends StatelessWidget {
  const _InfoLinha(this.icone, this.texto);

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 16, color: IdentitasColors.preto),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            texto,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: IdentitasColors.preto),
          ),
        ),
      ],
    );
  }
}
