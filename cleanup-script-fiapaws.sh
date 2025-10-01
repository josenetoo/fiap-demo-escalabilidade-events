#!/bin/bash
# Script de Cleanup - OBRIGATÓRIO após a live
# Live FIAP: Escalabilidade com Eventos
# Professor: José Neto
# PERFIL AWS: fiapaws

set -e

echo "🧹 CLEANUP - Preservando Budget do Learner Lab"
echo "=============================================="
echo "⚠️  Usando perfil AWS: fiapaws"

# Carregar variáveis se disponíveis
if [ -f /tmp/fiap-cleanup-vars.sh ]; then
    source /tmp/fiap-cleanup-vars.sh
    echo "✅ Variáveis carregadas de /tmp/fiap-cleanup-vars.sh"
else
    echo "⚠️  Variáveis não encontradas. Tentando descobrir recursos..."
    export AWS_REGION=us-east-1
    export AWS_PROFILE=fiapaws
    # Tentar encontrar recursos pelo padrão de nome
    export PREFIX=$(aws sns list-topics --region $AWS_REGION --profile $AWS_PROFILE --query 'Topics[?contains(TopicArn, `fiap-`)].TopicArn' --output text | head -1 | awk -F: '{print $NF}' | sed 's/-pedidos//' 2>/dev/null || echo "")
    
    if [ -z "$PREFIX" ]; then
        echo "❌ Não foi possível encontrar recursos automaticamente."
        echo "   Execute manualmente ou forneça o PREFIX:"
        echo "   export PREFIX=fiap-XXXXXXXXXX"
        echo "   export AWS_PROFILE=fiapaws"
        echo "   ./cleanup-script-fiapaws.sh"
        exit 1
    fi
fi

echo "🎯 Limpando recursos com prefix: $PREFIX"
echo "🌍 Região: $AWS_REGION"
echo "👤 Perfil: $AWS_PROFILE"

# Função para executar comando com tratamento de erro
safe_execute() {
    local cmd="$1"
    local description="$2"
    
    echo "🔄 $description..."
    if eval "$cmd" 2>/dev/null; then
        echo "✅ $description - OK"
    else
        echo "⚠️  $description - Erro ou recurso não existe (continuando...)"
    fi
}

# ============================================================================
# 1. CLEANUP EVENTBRIDGE
# ============================================================================

echo ""
echo "📋 Limpando EventBridge..."

# Remover targets
safe_execute "aws events remove-targets --rule $PREFIX-pedidos-rule --ids logs-target --region $AWS_REGION --profile $AWS_PROFILE" \
    "Removendo targets da regra EventBridge"

# Deletar regra
safe_execute "aws events delete-rule --name $PREFIX-pedidos-rule --region $AWS_REGION --profile $AWS_PROFILE" \
    "Deletando regra EventBridge"

# ============================================================================
# 2. CLEANUP CLOUDWATCH LOGS
# ============================================================================

echo ""
echo "📊 Limpando CloudWatch Logs..."

# Remover resource policy
safe_execute "aws logs delete-resource-policy --policy-name EventBridgeToCWLogsPolicy-$PREFIX --region $AWS_REGION --profile $AWS_PROFILE" \
    "Removendo resource policy do CloudWatch Logs"

if [ -n "$LOG_GROUP" ]; then
    safe_execute "aws logs delete-log-group --log-group-name $LOG_GROUP --region $AWS_REGION --profile $AWS_PROFILE" \
        "Deletando log group $LOG_GROUP"
else
    # Tentar encontrar log group
    LOG_GROUP="/aws/events/$PREFIX"
    safe_execute "aws logs delete-log-group --log-group-name $LOG_GROUP --region $AWS_REGION --profile $AWS_PROFILE" \
        "Deletando log group $LOG_GROUP"
fi

# ============================================================================
# 3. CLEANUP SNS
# ============================================================================

echo ""
echo "📢 Limpando SNS..."

# Encontrar topic ARN se não definido
if [ -z "$TOPIC_ARN" ]; then
    TOPIC_ARN=$(aws sns list-topics --region $AWS_REGION --profile $AWS_PROFILE --query "Topics[?contains(TopicArn, \`${PREFIX}-pedidos\`)].TopicArn" --output text 2>/dev/null || echo "")
fi

if [ -n "$TOPIC_ARN" ] && [ "$TOPIC_ARN" != "None" ]; then
    # Deletar subscriptions
    echo "🔗 Removendo subscriptions..."
    SUBSCRIPTIONS=$(aws sns list-subscriptions-by-topic --topic-arn $TOPIC_ARN --region $AWS_REGION --profile $AWS_PROFILE --query 'Subscriptions[].SubscriptionArn' --output text 2>/dev/null || echo "")
    
    for SUB in $SUBSCRIPTIONS; do
        if [ "$SUB" != "None" ] && [ -n "$SUB" ]; then
            safe_execute "aws sns unsubscribe --subscription-arn $SUB --region $AWS_REGION --profile $AWS_PROFILE" \
                "Removendo subscription $SUB"
        fi
    done
    
    # Deletar topic
    safe_execute "aws sns delete-topic --topic-arn $TOPIC_ARN --region $AWS_REGION --profile $AWS_PROFILE" \
        "Deletando SNS topic"
else
    echo "⚠️  Topic SNS não encontrado (pode já ter sido deletado)"
fi

# ============================================================================
# 4. CLEANUP SQS
# ============================================================================

echo ""
echo "📦 Limpando SQS..."

# Lista de filas para limpar
QUEUE_NAMES=("$PREFIX-estoque" "$PREFIX-faturamento")

for QUEUE_NAME in "${QUEUE_NAMES[@]}"; do
    echo "🔄 Processando fila: $QUEUE_NAME"
    
    # Obter URL da fila
    QUEUE_URL=$(aws sqs get-queue-url --queue-name $QUEUE_NAME --region $AWS_REGION --profile $AWS_PROFILE --query QueueUrl --output text 2>/dev/null || echo "")
    
    if [ -n "$QUEUE_URL" ] && [ "$QUEUE_URL" != "None" ]; then
        # Esvaziar fila
        safe_execute "aws sqs purge-queue --queue-url $QUEUE_URL --region $AWS_REGION --profile $AWS_PROFILE" \
            "Esvaziando fila $QUEUE_NAME"
        
        # Aguardar um pouco antes de deletar
        sleep 2
        
        # Deletar fila
        safe_execute "aws sqs delete-queue --queue-url $QUEUE_URL --region $AWS_REGION --profile $AWS_PROFILE" \
            "Deletando fila $QUEUE_NAME"
    else
        echo "⚠️  Fila $QUEUE_NAME não encontrada"
    fi
done

# ============================================================================
# 5. VERIFICAÇÃO FINAL
# ============================================================================

echo ""
echo "🔍 VERIFICAÇÃO FINAL"
echo "==================="

echo "📋 Verificando recursos restantes..."

# Verificar SNS topics
echo "📢 Topics SNS restantes:"
aws sns list-topics --region $AWS_REGION --profile $AWS_PROFILE --query "Topics[?contains(TopicArn, \`fiap-\`)].TopicArn" --output text || echo "Nenhum"

# Verificar SQS queues
echo "📦 Filas SQS restantes:"
aws sqs list-queues --region $AWS_REGION --profile $AWS_PROFILE --queue-name-prefix fiap- --query 'QueueUrls' --output text 2>/dev/null || echo "Nenhuma"

# Verificar EventBridge rules
echo "📋 Regras EventBridge restantes:"
aws events list-rules --region $AWS_REGION --profile $AWS_PROFILE --name-prefix fiap- --query 'Rules[].Name' --output text || echo "Nenhuma"

# Verificar Log Groups
echo "📊 Log Groups restantes:"
aws logs describe-log-groups --region $AWS_REGION --profile $AWS_PROFILE --log-group-name-prefix /aws/events/fiap- --query 'logGroups[].logGroupName' --output text 2>/dev/null || echo "Nenhum"

# ============================================================================
# 6. LIMPEZA DE ARQUIVOS TEMPORÁRIOS
# ============================================================================

echo ""
echo "🗑️  Limpando arquivos temporários..."
rm -f /tmp/fiap-cleanup-vars.sh

# ============================================================================
# 7. RESUMO FINAL
# ============================================================================

echo ""
echo "🎉 CLEANUP CONCLUÍDO!"
echo "===================="
echo "✅ Recursos AWS removidos"
echo "✅ Budget preservado"
echo "✅ Arquivos temporários limpos"
echo "✅ Perfil AWS usado: $AWS_PROFILE"
echo ""
echo "💡 DICAS PARA PRÓXIMAS SESSÕES:"
echo "   • Sempre execute cleanup após demos"
echo "   • Monitore o budget no painel do Learner Lab"
echo "   • Use CloudShell para economizar recursos EC2"
echo "   • Mantenha o perfil fiapaws configurado"
echo ""
echo "📚 MATERIAIS PARA OS ALUNOS:"
echo "   • student-handout.md - Resumo dos conceitos"
echo "   • architecture-diagrams.md - Diagramas de referência"
echo ""
echo "🚀 Live concluída com sucesso!"
