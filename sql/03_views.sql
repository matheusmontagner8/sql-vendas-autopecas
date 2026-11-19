-- =============================================================
-- 03_views.sql
-- Views que concentram as junções e os cálculos de valor.
-- As consultas de análise (04_consultas.sql) partem delas, e
-- elas também servem de fonte para um painel no Power BI.
-- =============================================================

DROP VIEW IF EXISTS vw_itens_vendidos;
DROP VIEW IF EXISTS vw_pedidos_resumo;

-- Uma linha por item de pedido FATURADO, já com valores calculados.
-- Observação: o custo usado é o custo atual do produto (a base não
-- guarda histórico de custo).
CREATE VIEW vw_itens_vendidos AS
SELECT
    p.id_pedido,
    p.data_pedido,
    strftime('%Y-%m', p.data_pedido)                                     AS ano_mes,
    c.id_cliente,
    c.nome                                                               AS cliente,
    c.tipo                                                               AS tipo_cliente,
    v.id_vendedor,
    v.nome                                                               AS vendedor,
    pr.id_produto,
    pr.codigo,
    pr.descricao                                                         AS produto,
    cat.nome                                                             AS categoria,
    i.quantidade,
    i.preco_unitario,
    i.desconto_pct,
    ROUND(i.quantidade * i.preco_unitario, 2)                            AS valor_bruto,
    ROUND(i.quantidade * i.preco_unitario * (1 - i.desconto_pct / 100.0), 2) AS valor_liquido,
    ROUND(i.quantidade * pr.preco_custo, 2)                              AS custo_total
FROM itens_pedido AS i
JOIN pedidos      AS p   ON p.id_pedido     = i.id_pedido
JOIN clientes     AS c   ON c.id_cliente    = p.id_cliente
JOIN vendedores   AS v   ON v.id_vendedor   = p.id_vendedor
JOIN produtos     AS pr  ON pr.id_produto   = i.id_produto
JOIN categorias   AS cat ON cat.id_categoria = pr.id_categoria
WHERE p.status = 'FATURADO';

-- Uma linha por pedido (faturado ou cancelado) com o valor total.
-- Cada item é arredondado antes da soma, como em vw_itens_vendidos,
-- para que as duas views cheguem exatamente ao mesmo total.
CREATE VIEW vw_pedidos_resumo AS
SELECT
    p.id_pedido,
    p.data_pedido,
    p.id_cliente,
    p.id_vendedor,
    p.status,
    p.forma_pagamento,
    COUNT(*)                                                                              AS qtd_itens,
    ROUND(SUM(ROUND(i.quantidade * i.preco_unitario * (1 - i.desconto_pct / 100.0), 2)), 2) AS valor_total
FROM pedidos AS p
JOIN itens_pedido AS i ON i.id_pedido = p.id_pedido
GROUP BY p.id_pedido, p.data_pedido, p.id_cliente, p.id_vendedor, p.status, p.forma_pagamento;
