-- =============================================================
-- 04_consultas.sql
-- Perguntas de negócio respondidas com SQL.
-- Valores em R$ já consideram o desconto de cada item.
-- "Hoje" na base = data do último pedido (31/10/2026).
-- =============================================================


-- -------------------------------------------------------------
-- 1. Como o faturamento evoluiu mês a mês?
--    Técnicas: GROUP BY, CTE, função de janela LAG
-- -------------------------------------------------------------
WITH mensal AS (
    SELECT
        ano_mes,
        COUNT(DISTINCT id_pedido)  AS pedidos,
        ROUND(SUM(valor_liquido), 2) AS faturamento
    FROM vw_itens_vendidos
    GROUP BY ano_mes
)
SELECT
    ano_mes,
    pedidos,
    faturamento,
    ROUND(faturamento / pedidos, 2) AS ticket_medio,
    ROUND(100.0 * (faturamento - LAG(faturamento) OVER (ORDER BY ano_mes))
          / LAG(faturamento) OVER (ORDER BY ano_mes), 1) AS variacao_pct
FROM mensal
ORDER BY ano_mes;


-- -------------------------------------------------------------
-- 2. De janeiro a outubro, 2026 vendeu mais que 2025?
--    Técnicas: agregação condicional com CASE
-- -------------------------------------------------------------
SELECT
    substr(ano_mes, 6, 2) AS mes,
    ROUND(SUM(CASE WHEN ano_mes LIKE '2025-%' THEN valor_liquido ELSE 0 END), 2) AS fat_2025,
    ROUND(SUM(CASE WHEN ano_mes LIKE '2026-%' THEN valor_liquido ELSE 0 END), 2) AS fat_2026,
    ROUND(100.0 * SUM(CASE WHEN ano_mes LIKE '2026-%' THEN valor_liquido ELSE 0 END)
          / SUM(CASE WHEN ano_mes LIKE '2025-%' THEN valor_liquido ELSE 0 END) - 100, 1) AS crescimento_pct
FROM vw_itens_vendidos
WHERE substr(ano_mes, 6, 2) <= '10'
GROUP BY substr(ano_mes, 6, 2)
ORDER BY mes;


-- -------------------------------------------------------------
-- 3. Quais são os 10 produtos que mais faturam e quanto representam do total?
--    Técnicas: SUM() OVER () para o total geral, LIMIT
-- -------------------------------------------------------------
SELECT
    codigo,
    produto,
    SUM(quantidade)                AS unidades,
    ROUND(SUM(valor_liquido), 2)   AS faturamento,
    ROUND(100.0 * SUM(valor_liquido) / SUM(SUM(valor_liquido)) OVER (), 1) AS participacao_pct
FROM vw_itens_vendidos
GROUP BY codigo, produto
ORDER BY faturamento DESC
LIMIT 10;


-- -------------------------------------------------------------
-- 4. Curva ABC: quais produtos formam 80% do faturamento (classe A)?
--    Técnicas: soma acumulada com SUM() OVER (ORDER BY ...), CASE
-- -------------------------------------------------------------
WITH por_produto AS (
    SELECT codigo, produto, SUM(valor_liquido) AS faturamento
    FROM vw_itens_vendidos
    GROUP BY codigo, produto
),
acumulado AS (
    SELECT
        codigo,
        produto,
        faturamento,
        100.0 * SUM(faturamento) OVER (ORDER BY faturamento DESC
                                       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
              / SUM(faturamento) OVER () AS pct_acumulado
    FROM por_produto
)
SELECT
    codigo,
    produto,
    ROUND(faturamento, 2)   AS faturamento,
    ROUND(pct_acumulado, 1) AS pct_acumulado,
    CASE
        WHEN pct_acumulado <= 80 THEN 'A'
        WHEN pct_acumulado <= 95 THEN 'B'
        ELSE 'C'
    END AS classe
FROM acumulado
ORDER BY faturamento DESC;


-- -------------------------------------------------------------
-- 5. Qual categoria dá mais margem de lucro?
--    Técnicas: agregação, cálculo de margem percentual
-- -------------------------------------------------------------
SELECT
    categoria,
    ROUND(SUM(valor_liquido), 2)                  AS faturamento,
    ROUND(SUM(valor_liquido - custo_total), 2)    AS margem,
    ROUND(100.0 * SUM(valor_liquido - custo_total) / SUM(valor_liquido), 1) AS margem_pct
FROM vw_itens_vendidos
GROUP BY categoria
ORDER BY margem DESC;


-- -------------------------------------------------------------
-- 6. Quem foi o melhor vendedor em cada trimestre?
--    (2026-T4 está incompleto: a base vai só até outubro)
--    Técnicas: RANK() OVER (PARTITION BY ...), filtro sobre a janela
-- -------------------------------------------------------------
WITH por_trimestre AS (
    SELECT
        strftime('%Y', data_pedido) || '-T' ||
            ((CAST(strftime('%m', data_pedido) AS INTEGER) + 2) / 3) AS trimestre,
        vendedor,
        ROUND(SUM(valor_liquido), 2) AS faturamento
    FROM vw_itens_vendidos
    GROUP BY trimestre, vendedor
),
ranking AS (
    SELECT
        trimestre,
        vendedor,
        faturamento,
        RANK() OVER (PARTITION BY trimestre ORDER BY faturamento DESC) AS posicao
    FROM por_trimestre
)
SELECT trimestre, vendedor, faturamento
FROM ranking
WHERE posicao = 1
ORDER BY trimestre;


-- -------------------------------------------------------------
-- 7. Quais clientes estão sem comprar há mais de 90 dias?
--    (lista para a equipe de vendas tentar recuperar)
--    Técnicas: CTE, subconsulta escalar, julianday()
-- -------------------------------------------------------------
WITH compras AS (
    SELECT
        c.nome,
        c.tipo,
        c.cidade,
        MAX(r.data_pedido) AS ultima_compra,
        CAST(julianday((SELECT MAX(data_pedido) FROM pedidos))
             - julianday(MAX(r.data_pedido)) AS INTEGER) AS dias_sem_comprar,
        COUNT(*)                     AS pedidos,
        ROUND(SUM(r.valor_total), 2) AS total_comprado
    FROM vw_pedidos_resumo AS r
    JOIN clientes AS c ON c.id_cliente = r.id_cliente
    WHERE r.status = 'FATURADO'
    GROUP BY c.id_cliente, c.nome, c.tipo, c.cidade
)
SELECT *
FROM compras
WHERE dias_sem_comprar > 90
ORDER BY total_comprado DESC;


-- -------------------------------------------------------------
-- 8. Clientes pessoa jurídica (oficinas) compram mais que pessoa física?
--    Técnicas: CTE, agregação em dois níveis
-- -------------------------------------------------------------
WITH por_cliente AS (
    SELECT c.tipo, r.id_cliente, COUNT(*) AS pedidos, SUM(r.valor_total) AS total
    FROM vw_pedidos_resumo AS r
    JOIN clientes AS c ON c.id_cliente = r.id_cliente
    WHERE r.status = 'FATURADO'
    GROUP BY c.tipo, r.id_cliente
)
SELECT
    tipo,
    COUNT(*)                            AS clientes,
    SUM(pedidos)                        AS pedidos,
    ROUND(SUM(total), 2)                AS faturamento,
    ROUND(SUM(total) / SUM(pedidos), 2) AS ticket_medio,
    ROUND(1.0 * SUM(pedidos) / COUNT(*), 1) AS pedidos_por_cliente
FROM por_cliente
GROUP BY tipo;


-- -------------------------------------------------------------
-- 9. Quais produtos precisam de reposição urgente?
--    (estoque abaixo do mínimo, ordenados pela venda dos últimos 90 dias)
--    Técnicas: LEFT JOIN com subconsulta, COALESCE
-- -------------------------------------------------------------
SELECT
    p.codigo,
    p.descricao,
    p.estoque_atual,
    p.estoque_minimo,
    COALESCE(v.unidades_90d, 0)                 AS vendidas_90_dias,
    p.estoque_minimo - p.estoque_atual          AS faltam_para_minimo
FROM produtos AS p
LEFT JOIN (
    SELECT id_produto, SUM(quantidade) AS unidades_90d
    FROM vw_itens_vendidos
    WHERE data_pedido > date((SELECT MAX(data_pedido) FROM pedidos), '-90 days')
    GROUP BY id_produto
) AS v ON v.id_produto = p.id_produto
WHERE p.ativo = 1
  AND p.estoque_atual < p.estoque_minimo
ORDER BY vendidas_90_dias DESC;


-- -------------------------------------------------------------
-- 10. Alguma forma de pagamento tem mais cancelamentos?
--     Técnicas: agregação condicional, taxa percentual
-- -------------------------------------------------------------
SELECT
    forma_pagamento,
    COUNT(*)                                             AS pedidos,
    SUM(CASE WHEN status = 'CANCELADO' THEN 1 ELSE 0 END) AS cancelados,
    ROUND(100.0 * SUM(CASE WHEN status = 'CANCELADO' THEN 1 ELSE 0 END) / COUNT(*), 1) AS taxa_cancelamento_pct,
    ROUND(SUM(CASE WHEN status = 'CANCELADO' THEN valor_total ELSE 0 END), 2) AS valor_cancelado
FROM vw_pedidos_resumo
GROUP BY forma_pagamento
ORDER BY taxa_cancelamento_pct DESC;


-- -------------------------------------------------------------
-- 11. Segmentação RFM: quem são os melhores clientes?
--     (Recência, Frequência e Valor, nota de 1 a 4 em cada)
--     Técnicas: NTILE() OVER, várias CTEs encadeadas
-- -------------------------------------------------------------
WITH base AS (
    SELECT
        id_cliente,
        julianday((SELECT MAX(data_pedido) FROM pedidos)) - julianday(MAX(data_pedido)) AS recencia_dias,
        COUNT(*)         AS frequencia,
        SUM(valor_total) AS valor
    FROM vw_pedidos_resumo
    WHERE status = 'FATURADO'
    GROUP BY id_cliente
),
notas AS (
    SELECT
        id_cliente,
        recencia_dias,
        frequencia,
        valor,
        NTILE(4) OVER (ORDER BY recencia_dias DESC) AS r,
        NTILE(4) OVER (ORDER BY frequencia)         AS f,
        NTILE(4) OVER (ORDER BY valor)              AS v
    FROM base
)
SELECT
    CASE
        WHEN r >= 3 AND f >= 3 AND v >= 3 THEN '1. Campeões'
        WHEN r >= 3 AND f <= 2            THEN '2. Novos ou ocasionais'
        WHEN r <= 2 AND f >= 3            THEN '3. Em risco (compravam muito)'
        ELSE                                   '4. Pouco engajados'
    END AS segmento,
    COUNT(*)                          AS clientes,
    ROUND(AVG(recencia_dias), 0)      AS recencia_media_dias,
    ROUND(AVG(frequencia), 1)         AS pedidos_medios,
    ROUND(SUM(valor), 2)              AS faturamento
FROM notas
GROUP BY segmento
ORDER BY segmento;
