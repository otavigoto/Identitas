import 'package:flutter/material.dart';

import 'gestao_disciplina_screen.dart';
import 'screens_shared.dart';
import '../services/attendance_service.dart';

class RevisaoChamadaScreen extends StatefulWidget {
  const RevisaoChamadaScreen({
    super.key,
    this.classId,
    this.initialDate,
    this.teacherId,
  });

  final String? classId;
  final DateTime? initialDate;
  final String? teacherId;

  @override
  State<RevisaoChamadaScreen> createState() => _RevisaoChamadaScreenState();
}

class _RevisaoChamadaScreenState extends State<RevisaoChamadaScreen> {
  final _attendance = AttendanceService();
  final Map<String, bool> _presenca = {};
  final List<AlunoFrequencia> _alunos = [];
  late DateTime _selectedDate;
  AulaIdentitas? _turma;
  bool _carregando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _carregar();
  }

  Future<void> _carregar() async {
    final classId = widget.classId;
    if (classId == null) {
      setState(() => _erro = 'Selecione uma turma para revisar a chamada.');
      return;
    }
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final students = await _attendance.listStudents();
      final classes = widget.teacherId == null
          ? <AulaIdentitas>[]
          : await _attendance.listForTeacher(widget.teacherId!);
      final turma = classes.cast<AulaIdentitas?>().firstWhere(
            (item) => item?.id == classId,
            orElse: () => null,
          );
      if (turma == null) throw const AttendanceException('Turma não encontrada.');

      final enrolledIds = turma.enrolledStudents.toSet();
      final enrolledStudents =
          students.where((student) => enrolledIds.contains(student.id)).toList();
      final attendance = turma.attendanceList.firstWhere(
        (item) =>
            item.date.year == _selectedDate.year &&
            item.date.month == _selectedDate.month &&
            item.date.day == _selectedDate.day,
        orElse: () => AttendanceItem(
          date: DateTime(2000),
          students: const [],
        ),
      );
      final presentIds = {
        for (final record in attendance.students)
          if (record.present) record.studentId,
      };

      _alunos
        ..clear()
        ..addAll([
          for (final student in enrolledStudents)
            AlunoFrequencia(student.name, student.ra, presentIds.contains(student.id) ? 100 : 0),
        ]);
      _presenca
        ..clear()
        ..addEntries([
          for (final student in enrolledStudents)
            MapEntry(student.ra, presentIds.contains(student.id)),
        ]);
      if (!mounted) return;
      setState(() {
        _turma = turma;
        _carregando = false;
      });
    } on AttendanceException catch (error) {
      if (!mounted) return;
      setState(() {
        _erro = error.message;
        _carregando = false;
      });
    }
  }

  Future<void> _selecionarDia() async {
    final novoDia = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (novoDia != null) {
      setState(() => _selectedDate = novoDia);
      await _carregar();
    }
  }

  Future<void> _reabrirChamada() async {
    if (widget.classId == null) return;
    try {
      await _attendance.openAttendance(
        widget.classId!,
        date: _selectedDate,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chamada reaberta para ajuste.')),
      );
    } on AttendanceException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _confirmarChamada() async {
    if (widget.classId == null) return;
    final presentes = _presenca.entries
        .where((entry) => entry.value)
        .map((entry) {
          final aluno = _alunos.firstWhere((item) => item.ra == entry.key);
          final student = _alunos.indexOf(aluno);
          return student >= 0 ? aluno.ra : '';
        })
        .where((id) => id.isNotEmpty)
        .toList();
    // Os IDs necessários são os IDs reais do usuário, não os RAs.
    try {
      final students = await _attendance.listStudents();
      final raToId = {for (final student in students) student.ra: student.id};
      final presentIds = presentes.map((ra) => raToId[ra]).whereType<String>().toList();
      await _attendance.markAttendance(
        widget.classId!,
        presentIds,
        date: _selectedDate,
      );
      await _attendance.closeAttendance(widget.classId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chamada confirmada')),
      );
    } on AttendanceException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _ajustar(AlunoFrequencia aluno) async {
    final novo = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: IdentitasColors.creme,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AjustarPresenca(
        aluno: aluno,
        presente: _presenca[aluno.ra]!,
      ),
    );
    if (novo != null) setState(() => _presenca[aluno.ra] = novo);
  }

  @override
  Widget build(BuildContext context) {
    final ausentes = _alunos.where((a) => !(_presenca[a.ra] ?? false)).toList();
    final presentes = _alunos.where((a) => _presenca[a.ra] == true).toList();

    return Scaffold(
      backgroundColor: IdentitasColors.fundo,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                children: [
                  Text(
                    'Revisão de Chamada',
                    style: identitasText(
                      size: 26,
                      weight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _turma?.name ?? 'Turma',
                          style: identitasText(
                            size: 14,
                            weight: FontWeight.w400,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _selecionarDia,
                        child: Text(
                          '${_selectedDate.day.toString().padLeft(2, '0')}/'
                          '${_selectedDate.month.toString().padLeft(2, '0')}/'
                          '${_selectedDate.year}',
                          style: identitasText(
                            size: 12,
                            weight: FontWeight.w600,
                            color: IdentitasColors.amarelo,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _reabrirChamada,
                    icon: const Icon(Icons.restore),
                    label: const Text('Reabrir chamada deste dia'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                    ),
                  ),
                  if (_carregando)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: IdentitasColors.amarelo,
                        ),
                      ),
                    )
                  else if (_erro != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        _erro!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  const SizedBox(height: 24),
                  _CardResumo(
                    total: _alunos.length,
                    presentes: presentes.length,
                    ausentes: ausentes.length,
                  ),
                  const SizedBox(height: 20),
                  _Secao('Ausentes (${ausentes.length})'),
                  for (final aluno in ausentes)
                    _CardRegistro(
                      aluno,
                      presente: false,
                      onAjustar: () => _ajustar(aluno),
                    ),
                  const SizedBox(height: 8),
                  _Secao('Presentes (${presentes.length})'),
                  for (final aluno in presentes)
                    _CardRegistro(
                      aluno,
                      presente: true,
                      onAjustar: () => _ajustar(aluno),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: _BotaoAmarelo(
                'Confirmar chamada',
                onPressed: _confirmarChamada,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardResumo extends StatelessWidget {
  const _CardResumo({
    required this.total,
    required this.presentes,
    required this.ausentes,
  });

  final int total;
  final int presentes;
  final int ausentes;

  Widget _numero(int valor, String rotulo) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$valor',
            style: identitasText(size: 24, weight: FontWeight.bold),
          ),
          Text(rotulo, style: identitasText(size: 11)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IdentitasColors.amarelo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Leitura NFC encerrada',
            style: identitasText(size: 18, weight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Confira os registros antes de confirmar',
            style: identitasText(size: 11),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _numero(total, 'Alunos'),
              _numero(presentes, 'Presentes'),
              _numero(ausentes, 'Ausentes'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao(this.titulo);

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        titulo,
        style: identitasText(
          size: 16,
          weight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _CardRegistro extends StatelessWidget {
  const _CardRegistro(
    this.aluno, {
    required this.presente,
    required this.onAjustar,
  });

  final AlunoFrequencia aluno;
  final bool presente;
  final VoidCallback onAjustar;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: IdentitasColors.creme,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            aluno.nome,
            style: identitasText(size: 14, weight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'RA ${aluno.ra}',
            style: identitasText(
              size: 10,
              weight: FontWeight.w400,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: presente ? IdentitasColors.amarelo : null,
                  border: presente
                      ? null
                      : Border.all(color: IdentitasColors.preto),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  presente ? 'Presente' : 'Ausente',
                  style: identitasText(size: 11),
                ),
              ),
              TextButton(
                onPressed: onAjustar,
                style: TextButton.styleFrom(
                  foregroundColor: IdentitasColors.preto,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Ajustar',
                  style: identitasText(size: 11).copyWith(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AjustarPresenca extends StatefulWidget {
  const _AjustarPresenca({
    required this.aluno,
    required this.presente,
  });

  final AlunoFrequencia aluno;
  final bool presente;

  @override
  State<_AjustarPresenca> createState() => _AjustarPresencaState();
}

class _AjustarPresencaState extends State<_AjustarPresenca> {
  late bool _presente = widget.presente;

  @override
  Widget build(BuildContext context) {
    Widget opcao(String texto, bool valor) {
      final selecionado = _presente == valor;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: selecionado
              ? IdentitasColors.amarelo
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            side: const BorderSide(),
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _presente = valor),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    selecionado
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 18,
                    color: IdentitasColors.preto,
                  ),
                  const SizedBox(width: 10),
                  Text(texto, style: identitasText(size: 14)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ajustar presença',
              style: identitasText(size: 20, weight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              widget.aluno.nome,
              style: identitasText(size: 16, weight: FontWeight.w600),
            ),
            Text(
              'RA ${widget.aluno.ra}',
              style: identitasText(
                size: 10,
                weight: FontWeight.w400,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Selecione o registro correto',
              style: identitasText(size: 13),
            ),
            const SizedBox(height: 8),
            opcao('Presente', true),
            opcao('Ausente', false),
            const SizedBox(height: 6),
            _BotaoAmarelo(
              'Salvar alteração',
              onPressed: () => Navigator.pop(context, _presente),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: IdentitasColors.preto),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancelar',
                  style: identitasText(size: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotaoAmarelo extends StatelessWidget {
  const _BotaoAmarelo(this.texto, {required this.onPressed});

  final String texto;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: IdentitasColors.amarelo,
          foregroundColor: IdentitasColors.preto,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Text(texto, style: identitasText(size: 15)),
      ),
    );
  }
}
