import 'turma.dart';

// TODO backend: remover os mocks quando a API estiver integrada.
const professorMockId = 'prof-001';

const alunosMock = [
  Aluno(ra: '24012345', nome: 'Ana Souza'),
  Aluno(ra: '24012346', nome: 'Bruno Lima'),
  Aluno(ra: '24012347', nome: 'Carla Mendes'),
  Aluno(ra: '24012348', nome: 'Diego Alves'),
  Aluno(ra: '24012349', nome: 'Elisa Rocha'),
  Aluno(ra: '24012350', nome: 'Felipe Costa'),
];

List<Turma> criarTurmasMock() => const [
  Turma(
    id: '1',
    nome: 'Turma A - Noite',
    disciplina: 'Projeto Integrador VI',
    semestre: '2026.2',
    idProfessor: professorMockId,
    listaAlunos: ['24012345', '24012346', '24012347'],
  ),
  Turma(
    id: '2',
    nome: 'Turma B - Manhã',
    disciplina: 'Banco de Dados',
    semestre: '2026.2',
    idProfessor: professorMockId,
    listaAlunos: ['24012348', '24012349'],
  ),
  Turma(
    id: '3',
    nome: 'Turma C - Noite',
    disciplina: 'Engenharia de Software',
    semestre: '2026.2',
    idProfessor: professorMockId,
    listaAlunos: [],
  ),
  Turma(
    id: '4',
    nome: 'Turma A - Manhã',
    disciplina: 'Redes de Computadores',
    semestre: '2026.1',
    idProfessor: professorMockId,
    listaAlunos: ['24012345', '24012350'],
  ),
];
