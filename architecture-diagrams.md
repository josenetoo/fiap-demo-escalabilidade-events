# Diagramas de Arquitetura: Escalabilidade com Eventos

## 🏗️ Padrões Fundamentais

### 1. Fanout Pattern - SNS para SQS

```mermaid
flowchart TD
    A[E-commerce App] -->|Pedido Criado| B[SNS Topic<br/>orders-topic]
    
    B --> C[SQS Queue<br/>estoque-queue]
    B --> D[SQS Queue<br/>faturamento-queue]
    B --> E[SQS Queue<br/>email-queue]
    
    C --> F[Serviço Estoque]
    D --> G[Serviço Faturamento]
    E --> H[Serviço Email]
    
```

**Características:**
- **1:N Distribution**: Um evento distribui para múltiplos consumidores
- **Desacoplamento**: Produtor não conhece consumidores
- **Paralelismo**: Processamento simultâneo
- **Durabilidade**: SQS garante entrega

---

### 2. Event Filtering - EventBridge com Regras

```mermaid
flowchart TD
    A[Orders Service] -->|Pedido Criado<br/>valor: R$ 2500| EB[EventBridge<br/>Custom Bus]
    B[Inventory Service] -->|Estoque Baixo<br/>produto: Notebook| EB
    C[Payment Service] -->|Pagamento Aprovado<br/>valor: R$ 150| EB
    
    EB -->|Rule 1<br/>valor >= R$ 1000| D[SQS VIP Queue]
    EB -->|Rule 2<br/>source = orders| E[CloudWatch Logs]
    EB -->|Rule 3<br/>estoque < 10| F[SNS Alerts]
    
    D --> G[VIP Processing]
    E --> H[Monitoring Dashboard]
    F --> I[Operations Team]
    
```

**Características:**
- **Content-based Routing**: Filtros por conteúdo do evento
- **Multiple Sources**: Vários produtores, um barramento
- **Flexible Targets**: Diferentes tipos de destino
- **No Code Filtering**: Regras declarativas

---

### 3. Dead Letter Queue Pattern

```mermaid
flowchart TD
    A[SNS Topic] --> B[SQS Main Queue]
    B -->|Processamento<br/>Bem-sucedido| C[Consumer Service]
    B -->|Falha após<br/>3 tentativas| D[DLQ<br/>Dead Letter Queue]
    
    D --> E[Manual Analysis]
    D --> F[Retry Logic]
    D --> G[Alert System]
    
    C -->|Success| H[Business Logic]
    C -->|Temporary Failure| B
    
```

**Características:**
- **Fault Tolerance**: Recuperação de mensagens com falha
- **Observability**: Análise de problemas
- **Data Protection**: Zero perda de mensagens
- **Operational Insight**: Métricas de saúde

---

## 🎯 Arquiteturas Reais

### E-commerce: Processamento de Pedidos

```mermaid
flowchart TD
    subgraph "Frontend"
        UI[Web/Mobile App]
    end
    
    subgraph "API Gateway"
        API[REST API]
    end
    
    subgraph "Core Services"
        ORDER[Order Service]
    end
    
    subgraph "Event Layer"
        SNS[SNS Topic<br/>order-events]
    end
    
    subgraph "Processing Services"
        STOCK[Stock Service<br/>+ SQS]
        PAYMENT[Payment Service<br/>+ SQS]
        EMAIL[Email Service<br/>+ SQS]
        ANALYTICS[Analytics Service<br/>+ SQS]
    end
    
    subgraph "Data Layer"
        DB1[(Orders DB)]
        DB2[(Stock DB)]
        DB3[(Analytics DB)]
    end
    
    UI --> API
    API --> ORDER
    ORDER --> DB1
    ORDER -->|Publish Event| SNS
    
    SNS --> STOCK
    SNS --> PAYMENT
    SNS --> EMAIL
    SNS --> ANALYTICS
    
    STOCK --> DB2
    ANALYTICS --> DB3
    
```

**Benefícios:**
- **Checkout Rápido**: API retorna imediatamente
- **Processamento Paralelo**: Serviços independentes
- **Escalabilidade**: Cada serviço escala independentemente
- **Resiliência**: Falha em um serviço não afeta outros

---

### Microsserviços: Event-Driven Communication

```mermaid
flowchart TD
    subgraph "Domain Services"
        ORDERS[Orders Service]
        INVENTORY[Inventory Service]
        SHIPPING[Shipping Service]
        BILLING[Billing Service]
    end
    
    subgraph "Event Infrastructure"
        EB[EventBridge<br/>Central Bus]
    end
    
    subgraph "Integration Layer"
        SQS1[SQS Queue 1]
        SQS2[SQS Queue 2]
        SQS3[SQS Queue 3]
        LAMBDA[Lambda Function]
        CW[CloudWatch Logs]
    end
    
    subgraph "External Systems"
        ERP[ERP System]
        CRM[CRM System]
        EMAIL[Email Provider]
    end
    
    ORDERS -->|order.created<br/>order.cancelled| EB
    INVENTORY -->|stock.updated<br/>stock.low| EB
    SHIPPING -->|shipment.created<br/>shipment.delivered| EB
    BILLING -->|invoice.generated<br/>payment.received| EB
    
    EB -->|order.created<br/>valor >= 1000| SQS1
    EB -->|stock.low| SQS2
    EB -->|payment.received| SQS3
    EB -->|shipment.delivered| LAMBDA
    EB -->|all events| CW
    
    SQS1 --> BILLING
    SQS2 --> ORDERS
    SQS3 --> ERP
    LAMBDA --> EMAIL
    
```

**Benefícios:**
- **Loose Coupling**: Serviços não se conhecem diretamente
- **Independent Deployment**: Deploy sem coordenação
- **Event Governance**: Controle centralizado
- **Easy Integration**: Novos consumidores sem impacto

---

### Monitoramento: Alertas Inteligentes

```mermaid
flowchart TD
    subgraph "Sources"
        APP1[Application 1]
        APP2[Application 2]
        APP3[Application 3]
        INFRA[Infrastructure]
    end
    
    subgraph "Event Processing"
        EB[EventBridge<br/>monitoring-bus]
    end
    
    subgraph "Filtering Rules"
        R1[Rule: CRITICAL<br/>severity = critical]
        R2[Rule: WARNING<br/>severity = warning]
        R3[Rule: INFO<br/>severity = info]
    end
    
    subgraph "Alert Channels"
        PAGER[PagerDuty<br/>CRITICAL only]
        SLACK[Slack Channel<br/>WARNING + CRITICAL]
        EMAIL[Email<br/>Daily Digest]
        DASH[Dashboard<br/>All Events]
    end
    
    APP1 -->|error.occurred<br/>severity: critical| EB
    APP2 -->|performance.degraded<br/>severity: warning| EB
    APP3 -->|user.action<br/>severity: info| EB
    INFRA -->|resource.threshold<br/>severity: warning| EB
    
    EB --> R1
    EB --> R2
    EB --> R3
    
    R1 --> PAGER
    R1 --> SLACK
    R2 --> SLACK
    R2 --> EMAIL
    R3 --> EMAIL
    R3 --> DASH
    
```

**Benefícios:**
- **Noise Reduction**: Apenas alertas relevantes
- **Contextual Routing**: Canal certo para cada severidade
- **Operational Efficiency**: Menos fadiga de alertas
- **Centralized Management**: Uma fonte de verdade

---

## 📚 Referências dos Diagramas

### Ferramentas Utilizadas
- **Mermaid**: Para diagramas de fluxo

---

*Diagramas atualizados em: 01/10/2025*  
*Versão: 1.0*