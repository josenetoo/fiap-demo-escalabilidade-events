# Material do Aluno: Escalabilidade com Eventos

## 📚 Resumo da Live
**Curso:** POSTECH - DevOps e Arquitetura Cloud  
**Professor:** José Neto  
**Tópico:** Escalabilidade com Eventos (SQS, SNS, EventBridge)  
**Data:** 01/10/2025

---

## 🎯 Conceitos Fundamentais

### SQS (Simple Queue Service)
- **Tipo:** Fila de mensagens durável
- **Padrão:** Point-to-Point (1:1)
- **Quando usar:** Desacoplamento, backpressure, processamento assíncrono
- **Características:** FIFO ou Standard, DLQ, Visibility Timeout

### SNS (Simple Notification Service)  
- **Tipo:** Serviço de notificação pub/sub
- **Padrão:** Publish/Subscribe (1:N)
- **Quando usar:** Fanout, broadcast, notificações
- **Características:** Topics, Subscriptions, Filter Policies

### EventBridge
- **Tipo:** Barramento de eventos serverless
- **Padrão:** Event Router com filtros
- **Quando usar:** Roteamento por conteúdo, integração de sistemas
- **Características:** Rules, Targets, Event Patterns, Schema Registry

---

## 🏗️ Padrões Arquiteturais

### 1. Fanout Pattern
```
Produtor → SNS Topic → [SQS A, SQS B, SQS C, ...]
```
**Benefícios:**
- Desacoplamento entre produtor e consumidores
- Processamento paralelo
- Adição de novos consumidores sem impacto

### 2. Event Filtering
```
Eventos → EventBridge → Rules → Targets (filtrados)
```
**Benefícios:**
- Roteamento inteligente sem código
- Redução de ruído nos consumidores
- Governança centralizada

### 3. Dead Letter Queue (DLQ)
```
SQS → (falha após N tentativas) → DLQ
```
**Benefícios:**
- Recuperação de mensagens com falha
- Análise de problemas
- Garantia de não perda de dados

---

## 💻 Comandos Essenciais

### Setup Básico
```bash
# Configurar região
export AWS_REGION=us-east-1
export PREFIX=seu-projeto-$(date +%s)
```

### SNS Operations
```bash
# Criar topic
aws sns create-topic --name $PREFIX-topic --region $AWS_REGION

# Publicar mensagem
aws sns publish --topic-arn $TOPIC_ARN --message "Sua mensagem" --region $AWS_REGION

# Listar subscriptions
aws sns list-subscriptions-by-topic --topic-arn $TOPIC_ARN --region $AWS_REGION
```

### SQS Operations
```bash
# Criar fila
aws sqs create-queue --queue-name $PREFIX-queue --region $AWS_REGION

# Receber mensagens
aws sqs receive-message --queue-url $QUEUE_URL --max-number-of-messages 10 --region $AWS_REGION

# Deletar mensagem
aws sqs delete-message --queue-url $QUEUE_URL --receipt-handle $RECEIPT_HANDLE --region $AWS_REGION
```

### EventBridge Operations
```bash
# Criar regra
aws events put-rule --name $PREFIX-rule --event-pattern '{"source":["app.orders"]}' --region $AWS_REGION

# Adicionar target
aws events put-targets --rule $PREFIX-rule --targets '[{"Id":"1","Arn":"target-arn"}]' --region $AWS_REGION

# Enviar evento
aws events put-events --entries '[{"Source":"app.orders","DetailType":"Order Created","Detail":"{}"}]' --region $AWS_REGION
```

---

## 🎯 Casos de Uso Reais

### E-commerce: Processamento de Pedidos
**Problema:** Checkout lento durante picos de tráfego  
**Solução:** SNS fanout para múltiplos serviços
```
Pedido → SNS → [Estoque, Pagamento, Email, Analytics]
```

### Microsserviços: Comunicação Assíncrona
**Problema:** Acoplamento entre serviços via APIs síncronas  
**Solução:** EventBridge como barramento central
```
Serviços → EventBridge → Roteamento por regras → Consumidores
```

### Monitoramento: Alertas Inteligentes
**Problema:** Muitos alertas irrelevantes  
**Solução:** EventBridge com filtros
```
Métricas → EventBridge → Filtros → [Slack, PagerDuty, Email]
```

---

## 🛡️ Boas Práticas

### Segurança
- ✅ Use IAM roles com permissões mínimas
- ✅ Ative encryption at rest e in transit
- ✅ Implemente resource-based policies
- ❌ Não exponha credenciais em código

### Performance
- ✅ Configure visibility timeout adequadamente
- ✅ Use batch operations quando possível
- ✅ Implemente retry com backoff exponencial
- ❌ Não use FIFO queues desnecessariamente

### Observabilidade
- ✅ Monitore métricas do CloudWatch
- ✅ Configure alertas para DLQ
- ✅ Use distributed tracing (X-Ray)
- ✅ Implemente structured logging

### Custos
- ✅ Monitore mensagens não processadas
- ✅ Configure lifecycle policies
- ✅ Use reserved capacity para workloads previsíveis
- ❌ Não deixe recursos órfãos

---

## 📊 Métricas Importantes

### SQS
- `ApproximateNumberOfMessages`: Mensagens na fila
- `ApproximateNumberOfMessagesNotVisible`: Mensagens sendo processadas
- `NumberOfMessagesSent`: Taxa de produção
- `NumberOfMessagesReceived`: Taxa de consumo

### SNS
- `NumberOfMessagesPublished`: Mensagens publicadas
- `NumberOfNotificationsFailed`: Falhas de entrega
- `NumberOfNotificationsDelivered`: Entregas bem-sucedidas

### EventBridge
- `MatchedEvents`: Eventos que matcharam regras
- `InvocationsCount`: Invocações de targets
- `FailedInvocations`: Falhas na invocação

---

## 🔧 Troubleshooting Comum

### Mensagens não chegam ao destino
1. Verificar permissões IAM
2. Verificar resource policies
3. Verificar filtros/regras
4. Verificar DLQ

### Performance baixa
1. Ajustar visibility timeout
2. Aumentar concorrência de consumidores
3. Usar batch processing
4. Verificar throttling

### Custos altos
1. Verificar mensagens não processadas
2. Otimizar polling frequency
3. Implementar lifecycle policies
4. Revisar retention periods

---

## 📚 Recursos para Estudo

### Documentação Oficial
- [SQS Developer Guide](https://docs.aws.amazon.com/sqs/)
- [SNS Developer Guide](https://docs.aws.amazon.com/sns/)
- [EventBridge User Guide](https://docs.aws.amazon.com/eventbridge/)

### Patterns e Best Practices
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Architecture Center](https://aws.amazon.com/architecture/)
- [Event-driven Architecture Patterns](https://aws.amazon.com/event-driven-architecture/)

### Hands-on Labs
- [AWS Workshops](https://workshops.aws/)
- [AWS Samples GitHub](https://github.com/aws-samples)
- [Serverless Patterns](https://serverlessland.com/patterns)

---

## 📞 Contato

**Professor:** José Neto  
**LinkedIn:** https://www.linkedin.com/in/josenetoo/  
**GitHub:** https://github.com/josenetoo

---

*Material atualizado em: 01/10/2025*  
*Versão: 1.0*