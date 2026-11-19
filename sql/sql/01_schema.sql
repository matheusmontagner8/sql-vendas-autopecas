-- =============================================================
-- 01_schema.sql
-- Criação das tabelas da distribuidora de autopeças (fictícia).
-- Banco: SQLite 3
-- =============================================================

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS itens_pedido;
DROP TABLE IF EXISTS pedidos;
DROP TABLE IF EXISTS produtos;
DROP TABLE IF EXISTS clientes;
DROP TABLE IF EXISTS vendedores;
DROP TABLE IF EXISTS fornecedores;
DROP TABLE IF EXISTS categorias;

CREATE TABLE categorias (
    id_categoria  INTEGER PRIMARY KEY,
    nome          TEXT    NOT NULL UNIQUE
);

CREATE TABLE fornecedores (
    id_fornecedor INTEGER PRIMARY KEY,
    razao_social  TEXT    NOT NULL,
    cidade        TEXT    NOT NULL,
    uf            TEXT    NOT NULL CHECK (length(uf) = 2)
);

CREATE TABLE produtos (
    id_produto     INTEGER PRIMARY KEY,
    codigo         TEXT    NOT NULL UNIQUE,
    descricao      TEXT    NOT NULL,
    id_categoria   INTEGER NOT NULL REFERENCES categorias (id_categoria),
    id_fornecedor  INTEGER NOT NULL REFERENCES fornecedores (id_fornecedor),
    preco_custo    NUMERIC(10, 2) NOT NULL CHECK (preco_custo > 0),
    preco_venda    NUMERIC(10, 2) NOT NULL,
    estoque_atual  INTEGER NOT NULL DEFAULT 0 CHECK (estoque_atual >= 0),
    estoque_minimo INTEGER NOT NULL DEFAULT 0 CHECK (estoque_minimo >= 0),
    ativo          INTEGER NOT NULL DEFAULT 1 CHECK (ativo IN (0, 1)),
    CHECK (preco_venda >= preco_custo)
);

CREATE TABLE clientes (
    id_cliente    INTEGER PRIMARY KEY,
    nome          TEXT    NOT NULL,
    tipo          TEXT    NOT NULL CHECK (tipo IN ('PF', 'PJ')),
    cidade        TEXT    NOT NULL,
    uf            TEXT    NOT NULL CHECK (length(uf) = 2),
    data_cadastro DATE    NOT NULL
);

CREATE TABLE vendedores (
    id_vendedor   INTEGER PRIMARY KEY,
    nome          TEXT    NOT NULL,
    data_admissao DATE    NOT NULL
);

CREATE TABLE pedidos (
    id_pedido       INTEGER PRIMARY KEY,
    id_cliente      INTEGER NOT NULL REFERENCES clientes (id_cliente),
    id_vendedor     INTEGER NOT NULL REFERENCES vendedores (id_vendedor),
    data_pedido     DATE    NOT NULL,
    status          TEXT    NOT NULL CHECK (status IN ('FATURADO', 'CANCELADO')),
    forma_pagamento TEXT    NOT NULL CHECK (forma_pagamento IN ('PIX', 'CARTAO', 'BOLETO', 'DINHEIRO'))
);

CREATE TABLE itens_pedido (
    id_pedido      INTEGER NOT NULL REFERENCES pedidos (id_pedido),
    id_produto     INTEGER NOT NULL REFERENCES produtos (id_produto),
    quantidade     INTEGER NOT NULL CHECK (quantidade > 0),
    preco_unitario NUMERIC(10, 2) NOT NULL CHECK (preco_unitario > 0),
    desconto_pct   NUMERIC(5, 2)  NOT NULL DEFAULT 0 CHECK (desconto_pct BETWEEN 0 AND 30),
    PRIMARY KEY (id_pedido, id_produto)
);

-- Índices para as consultas mais usadas (filtro por data e junções).
CREATE INDEX idx_pedidos_data     ON pedidos (data_pedido);
CREATE INDEX idx_pedidos_cliente  ON pedidos (id_cliente);
CREATE INDEX idx_pedidos_vendedor ON pedidos (id_vendedor);
CREATE INDEX idx_itens_produto    ON itens_pedido (id_produto);
CREATE INDEX idx_produtos_categ   ON produtos (id_categoria);
