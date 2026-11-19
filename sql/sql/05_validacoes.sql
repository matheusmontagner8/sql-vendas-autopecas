-- =============================================================
-- 05_validacoes.sql
-- Testes de qualidade dos dados. Cada linha retornada é um
-- problema encontrado. Resultado vazio = base consistente.
-- O GitHub Actions falha se esta consulta retornar alguma linha.
-- =============================================================

SELECT teste, ocorrencias
FROM (
    SELECT 'Pedido sem nenhum item' AS teste, COUNT(*) AS ocorrencias
    FROM pedidos AS p
    WHERE NOT EXISTS (SELECT 1 FROM itens_pedido AS i WHERE i.id_pedido = p.id_pedido)

    UNION ALL
    SELECT 'Pedido anterior ao cadastro do cliente', COUNT(*)
    FROM pedidos AS p
    JOIN clientes AS c ON c.id_cliente = p.id_cliente
    WHERE p.data_pedido < c.data_cadastro

    UNION ALL
    SELECT 'Pedido anterior à admissão do vendedor', COUNT(*)
    FROM pedidos AS p
    JOIN vendedores AS v ON v.id_vendedor = p.id_vendedor
    WHERE p.data_pedido < v.data_admissao

    UNION ALL
    SELECT 'Item de 2026 com preço diferente da tabela atual', COUNT(*)
    FROM itens_pedido AS i
    JOIN pedidos  AS p  ON p.id_pedido  = i.id_pedido
    JOIN produtos AS pr ON pr.id_produto = i.id_produto
    WHERE p.data_pedido >= '2026-01-01'
      AND i.preco_unitario <> pr.preco_venda

    UNION ALL
    SELECT 'Item vendido abaixo do custo', COUNT(*)
    FROM vw_itens_vendidos
    WHERE valor_liquido < custo_total

    UNION ALL
    SELECT 'Totais diferentes entre as duas views', COUNT(*)
    FROM (SELECT ROUND(SUM(valor_liquido), 2) AS total FROM vw_itens_vendidos) AS a,
         (SELECT ROUND(SUM(valor_total), 2) AS total
          FROM vw_pedidos_resumo WHERE status = 'FATURADO') AS b
    WHERE a.total <> b.total
) AS resultados
WHERE ocorrencias > 0;
