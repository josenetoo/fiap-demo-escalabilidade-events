# Live FIAP: Escalabilidade com Eventos (SQS, SNS, EventBridge)

## 📋 Visão Geral
Live sobre escalabilidade orientada a eventos usando AWS Learner Lab.

**Professor:** José Neto  
**Curso:** POSTECH - DevOps e Arquitetura Cloud  
**Ambiente:** AWS Learner Lab (us-east-1)

## 🎯 Objetivos de Aprendizagem
- Entender quando usar SQS, SNS e EventBridge
- Aplicar padrões de escalabilidade (fanout, event routing)
- Operar via AWS CLI com boas práticas
- Desenhar arquiteturas event-driven

## 📁 Estrutura dos Arquivos

```
├── README.md                      # Este arquivo
├── slides-outline.md              # Estrutura dos slides
├── guia-exercicios.md             # Guia completo dos 9 exercícios (perfil fiapaws)
├── cleanup-script-fiapaws.sh      # Script de limpeza (perfil fiapaws)
├── student-handout.md             # Material para os alunos
└── architecture-diagrams.md       # Diagramas de referência
```

## ⚠️ Importante - Learner Lab
- **Região obrigatória:** us-east-1
- **Role obrigatória:** LabRole (não criar IAM roles)
- **Budget:** Monitorar constantemente
- **Cleanup:** Executar SEMPRE ao final

## 🚀 Como Usar

### Preparação (15 min antes da live)
1. Abrir CloudShell no AWS Console
2. Configurar perfil AWS: `export AWS_PROFILE=fiapaws`
3. Configurar variáveis: `export AWS_REGION=us-east-1` e `export PREFIX=fiap-$(date +%s)`
4. Ter `guia-exercicios.md` aberto para copy-paste dos comandos
5. Preparar slides baseados em `slides-outline.md`

### Durante a Live
1. Seguir agenda em `slides-outline.md`
2. Executar comandos do `guia-exercicios.md` (9 exercícios)
3. Mostrar diagramas de `architecture-diagrams.md`
4. **IMPORTANTE**: Todos os comandos usam `--profile fiapaws`

### Após a Live
1. Executar `cleanup-script-fiapaws.sh` OBRIGATÓRIO
2. Compartilhar `student-handout.md` com alunos

---
**Última atualização:** 01/10/2025
