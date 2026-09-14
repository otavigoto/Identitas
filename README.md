#Alunos no projeto
Otávio...
Nicolas...
Bruno...
Henrique...
Juliano...


# 🎓 Identitas | Sistema de Presença por NFC

![Flutter](https://img.shields.io/badge/Mobile-Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![NestJS](https://img.shields.io/badge/Backend-NestJS-E0234E?style=for-the-badge&logo=nestjs&logoColor=white)
![MongoDB](https://img.shields.io/badge/Database-MongoDB-4EA94B?style=for-the-badge&logo=mongodb&logoColor=white)
![NFC](https://img.shields.io/badge/Hardware-NFC_13.56MHz-black?style=for-the-badge&logo=nfc&logoColor=white)

> **Identitas** é uma solução tecnológica projetada para remover a subjetividade e a vulnerabilidade do controle de fluxo acadêmico, garantindo a integridade e a autenticidade dos registros de presença, assegurando um ambiente justo, igualitário e livre de discriminação.

---

## 📖 Índice

- [Sobre o Projeto](#-sobre-o-projeto)
- [O Círculo Dourado](#-o-círculo-dourado)
- [Principais Funcionalidades](#-principais-funcionalidades)
- [Tecnologias Utilizadas](#-tecnologias-utilizadas)
- [Arquitetura e Fluxo](#-arquitetura-e-fluxo)
- [Autor](#-autor)

---

## 🌍 Sobre o Projeto

A gestão de presença e a identificação em ambientes educacionais enfrentam grandes desafios práticos e éticos. 

1. **Vulnerabilidade em Sala de Aula:** Métodos tradicionais (chamada oral, QR Code) são frequentemente burlados, comprometendo a integridade acadêmica.
2. **Preconceito Estrutural no Campus:** A dependência de verificações visuais para acesso abre margem para abordagens discriminatórias, colocando estudantes em posições de constrangimento.

O **Identitas** resolve esses problemas através de **terminais NFC** físicos e um aplicativo mobile, exigindo a presença física inquestionável do aluno e removendo a "margem de dúvida" visual da segurança do campus.

---

## 🎯 O Círculo Dourado

### Por quê? (Why)
O ambiente universitário precisa ser um espaço de integridade e equidade. O Identitas existe para eliminar a subjetividade nas validações de acesso que abrem espaço para preconceitos estruturais baseados em julgamento humano, além de extinguir fraudes nos sistemas de chamada tradicionais.

### Como? (How)
Através de um desenvolvimento ágil (Scrum adaptado), com uma arquitetura dividida em camadas: 
* Aplicativo mobile focado na comunicação de hardware.
* Backend robusto e modular.
* Banco de dados otimizado para logs de acesso. 
O controle e versionamento seguem os padrões da indústria via GitFlow e Kanban.

### O quê? (What)
Um sistema integrado de validação de presença baseado em tecnologia NFC (13,56 MHz). Composto por um aplicativo móvel (para alunos e professores) e uma API de retaguarda, permitindo o registro de entradas, saídas curtas e histórico de frequências.

---

## ✨ Principais Funcionalidades

### 👨‍🎓 Para os Alunos
* **Autenticação Segura:** Login institucional direto no app.
* **Validação por NFC:** Registro de presença aproximando o celular (ou cartão físico vinculado) do terminal/leitor da sala.
* **Histórico de Frequência:** Acompanhamento em tempo real de presenças e faltas por disciplina.

### 👨‍🏫 Para os Professores
* **Gestão de Turmas:** Visualização da grade de aulas do dia.
* **Modo Leitor NFC:** O smartphone do professor se transforma em um terminal de validação para ler os cartões físicos dos alunos.
* **Monitoramento em Tempo Real:** Contador de alunos presentes e opção para encerramento manual ou temporizado da sessão de chamada.

### ⚙️ Sistema (Core)
* **Prevenção de Fraudes:** Bloqueio de leituras duplicadas e controle rigoroso de tempo para "saídas curtas" (ex: idas ao banheiro).
* **Auditoria:** Registro de cada tentativa de acesso com carimbo de data/hora (*timestamp*).

---

## 💻 Tecnologias Utilizadas

| Camada | Tecnologia | Descrição |
| :--- | :--- | :--- |
| **Mobile** | Flutter / Dart | Aplicativo multiplataforma com integração ao pacote `nfc_manager`. |
| **Backend** | NestJS / Node.js | API RESTful modular, responsável por regras de negócio e validações. |
| **Database** | MongoDB | Armazenamento de dados cadastrais, logs de acesso e trilhas de auditoria. |
| **Infra/Cloud** | OCI / VPS | Hospedagem na Oracle Cloud Infrastructure (Free Tier). |
| **Hardware** | NTAG / 13.56MHz | Cartões e tags NFC para leitura física. |

---

## 🔄 Arquitetura e Fluxo (Modo Professor)

1. O Professor inicia a **Sessão de Chamada** no aplicativo para a turma atual.
2. O aplicativo entra em modo de escuta contínua de hardware (NFC).
3. O aluno aproxima seu cartão/tag NFC (13.56MHz) do celular do professor.
4. O app lê o *UID* do cartão e envia via requisição HTTP para a API NestJS.
5. A API cruza os dados com o MongoDB, confirma a matrícula, salva o log e retorna o status.
6. O professor recebe um feedback visual/sonoro imediato de sucesso ou falha.
