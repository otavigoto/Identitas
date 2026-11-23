import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'disciplinas_page.dart';
import 'nfc_instrucao_page.dart';
import 'profile_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _ink = Color(0xFF1E1E1E);
  static const _accent = Color(0xFFF9FF2E);
  static const _cream = Color(0xFFFEFFD9);

  void _openClasses(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const DisciplinasPage()));
  }

  void _openProfile(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }

  void _openNfc(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NfcInstrucaoPage(
          nomeDisciplina: 'Engenharia de Software',
          onValidarPresenca: (_) async => false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ink,
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
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Olá,\nOdete Roitmann',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  height: 0.95,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              SizedBox(height: 17),
                              Text(
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
                        _Avatar(onTap: () => _openProfile(context)),
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
                      child: const _NextClassCard(),
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
                            onPressed: () => _openClasses(context),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                    Column(
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: const _SummaryCard(
                            time: '08:00 - 09:40',
                            name: 'Cálculo Diferencial',
                            room: 'Lab 03 - H15',
                            status: _ClassStatus.present,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: cardWidth,
                          child: const _SummaryCard(
                            time: '10:00 - 11:40',
                            name: 'Engenharia de Software',
                            room: 'Sala 204 - H15',
                            status: _ClassStatus.next,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: cardWidth,
                          child: const _SummaryCard(
                            time: '11:40 - 12:30',
                            name: 'Projeto Integrador',
                            room: 'Sala A06 - H15',
                            status: _ClassStatus.scheduled,
                          ),
                        ),
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
                  child: Center(
                    child: _NfcButton(onTap: () => _openNfc(context)),
                  ),
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
  const _NextClassCard();

  @override
  Widget build(BuildContext context) {
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
              child: const Text(
                'HOJE • 10:00 - 11:40',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: HomePage._accent,
                  fontSize: 14,
                  height: 1,
                ),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            top: 43,
            child: Text(
              'Engenharia de\nSoftware',
              style: TextStyle(
                color: Colors.black,
                fontSize: 26,
                height: 0.95,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
              ),
            ),
          ),
          const Positioned(
            left: 6,
            bottom: 30,
            child: Text(
              'Prof. Dr. Ricardo Almeida',
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                height: 1,
              ),
            ),
          ),
          const Positioned(
            left: 4,
            bottom: 6,
            child: Text(
              'Sala 204 - H15',
              style: TextStyle(
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

enum _ClassStatus { present, next, scheduled }

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
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: Color(0xFF1E1E1E),
                    ),
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
              border: Border.all(
                color: const Color(0x66F9FF2E),
                width: 1,
              ),
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
