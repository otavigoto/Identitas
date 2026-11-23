import 'package:flutter/material.dart';

class DisciplinasPage extends StatefulWidget {
  const DisciplinasPage({super.key});

  static const _ink = Color(0xFF1E1E1E);
  static const _accent = Color(0xFFF9FF2E);
  static const _surface = Color(0xFFFEFFD9);

  @override
  State<DisciplinasPage> createState() => _DisciplinasPageState();
}

class _DaySelector extends StatelessWidget {
  const _DaySelector({
    required this.weekday,
    required this.onPrevious,
    required this.onNext,
  });

  final String weekday;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
          color: Colors.white,
          tooltip: 'Dia anterior',
        ),
        Expanded(
          child: Text(
            weekday,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
          color: Colors.white,
          tooltip: 'Próximo dia',
        ),
      ],
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_available_outlined, size: 44, color: Color(0xFF1E1E1E)),
          SizedBox(height: 12),
          Text(
            'Nenhuma disciplina',
            style: TextStyle(
              color: Color(0xFF1E1E1E),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _DisciplinasPageState extends State<DisciplinasPage> {
  static const _ink = Color(0xFF1E1E1E);
  static const _accent = Color(0xFFF9FF2E);
  late final PageController _pageController;
  late int _selectedDay;

  static const _weekdays = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];

  final _disciplinesByDay = const [
    [
      ('08:00 - 09:40', 'Cálculo Diferencial', 'Lab 03 - H15', '75%'),
      ('10:00 - 11:40', 'Engenharia de Software', 'Sala 204 - H15', '80%'),
      ('11:40 - 12:30', 'Projeto Integrador', 'Sala A06 - H15', '67%'),
    ],
    [
      ('08:00 - 09:40', 'Estrutura de Dados', 'Lab 02 - H15', '82%'),
      ('10:00 - 11:40', 'Banco de Dados', 'Sala 105 - H15', '88%'),
    ],
    [
      ('08:00 - 09:40', 'Cálculo Diferencial', 'Lab 03 - H15', '75%'),
      ('10:00 - 11:40', 'Engenharia de Software', 'Sala 204 - H15', '80%'),
      ('11:40 - 12:30', 'Projeto Integrador', 'Sala A06 - H15', '67%'),
    ],
    [
      ('08:00 - 09:40', 'Arquitetura de Computadores', 'Lab 01 - H15', '79%'),
      ('10:00 - 11:40', 'Interação Humano-Computador', 'Sala 302 - H15', '91%'),
    ],
    [
      ('08:00 - 09:40', 'Redes de Computadores', 'Lab 04 - H15', '84%'),
      ('10:00 - 11:40', 'Projeto Integrador', 'Sala A06 - H15', '67%'),
    ],
    <(String, String, String, String)>[],
    <(String, String, String, String)>[],
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now().weekday - 1;
    _pageController = PageController(initialPage: _selectedDay);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ink,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = (constraints.maxWidth * 0.075).clamp(20.0, 30.0);
            final cardWidth = (constraints.maxWidth - horizontal * 2).clamp(
              280.0,
              362.0,
            );

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(horizontal, 25, horizontal, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Voltar',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                  const Text(
                    'Disciplinas Matriculadas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      height: 32 / 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    '6º semestre',
                    style: TextStyle(
                      color: Color(0xFFB8B8AE),
                      fontSize: 16,
                      height: 22 / 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: cardWidth,
                    child: const _GeneralFrequencyCard(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: cardWidth,
                    child: const Text(
                      'Frequência por disciplina',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        height: 32 / 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 4),
                  _DaySelector(
                    weekday: _weekdays[_selectedDay],
                    onPrevious: _selectedDay == 0
                        ? null
                        : () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOutCubic,
                          ),
                    onNext: _selectedDay == 6
                        ? null
                        : () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOutCubic,
                          ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: cardWidth,
                    height: 345,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) =>
                          setState(() => _selectedDay = index),
                      itemCount: _weekdays.length,
                      itemBuilder: (context, dayIndex) {
                        final disciplines = _disciplinesByDay[dayIndex];
                        return Container(
                          padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                          decoration: BoxDecoration(
                            color: _accent,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: disciplines.isEmpty
                              ? const _EmptyDay()
                              : ListView.separated(
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: disciplines.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final item = disciplines[index];
                                    return _DisciplineFrequencyCard(
                                      time: item.$1,
                                      name: item.$2,
                                      room: item.$3,
                                      frequency: item.$4,
                                    );
                                  },
                                ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GeneralFrequencyCard extends StatelessWidget {
  const _GeneralFrequencyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DisciplinasPage._accent,
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frequência geral',
            style: TextStyle(
              color: DisciplinasPage._ink,
              fontSize: 16,
              height: 22 / 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '85%',
            style: TextStyle(
              color: DisciplinasPage._ink,
              fontSize: 65,
              height: 70 / 65,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Acumulada no semestre',
            style: TextStyle(
              color: DisciplinasPage._ink,
              fontSize: 13,
              height: 18 / 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          LinearProgressIndicator(
            value: 0.85,
            minHeight: 6,
            borderRadius: BorderRadius.all(Radius.circular(3)),
            color: DisciplinasPage._ink,
            backgroundColor: Color(0x33A3A708),
          ),
        ],
      ),
    );
  }
}

class _DisciplineFrequencyCard extends StatelessWidget {
  const _DisciplineFrequencyCard({
    required this.time,
    required this.name,
    required this.room,
    required this.frequency,
  });

  final String time;
  final String name;
  final String room;
  final String frequency;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 91),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: DisciplinasPage._surface,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    height: 16 / 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    height: 20 / 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: DisciplinasPage._ink,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      room,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        height: 14 / 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            frequency,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 30,
              height: 1,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
