"""Gera sql/02_dados.sql com dados FICTÍCIOS da distribuidora de autopeças.

A semente é fixa, então o arquivo gerado é sempre o mesmo.
Uso: python scripts/gerar_dados.py
"""

import random
from datetime import date, timedelta
from pathlib import Path

random.seed(42)

INICIO = date(2025, 1, 2)
FIM = date(2026, 10, 31)
REAJUSTE_2026 = 1.06  # tabela de preços reajustada em 6% em janeiro de 2026

CATEGORIAS = ["Freios", "Filtros", "Motor", "Suspensão", "Elétrica",
              "Lubrificantes", "Arrefecimento", "Acessórios"]

FORNECEDORES = [
    ("Freiotec Distribuidora Ltda", "São Paulo", "SP"),
    ("Filtra Mais Indústria Ltda", "Campinas", "SP"),
    ("Motorpeças Atacado Ltda", "Guarulhos", "SP"),
    ("Suspensul Componentes Ltda", "Curitiba", "PR"),
    ("Eletroauto Comercial Ltda", "Belo Horizonte", "MG"),
    ("Lubrimax Distribuidora Ltda", "Santo André", "SP"),
]

# (descrição, categoria, fornecedor, custo, margem, popularidade)
PRODUTOS = [
    ("Pastilha de freio dianteira", 1, 1, 58.00, 1.70, 9),
    ("Pastilha de freio traseira", 1, 1, 52.00, 1.70, 6),
    ("Disco de freio ventilado (par)", 1, 1, 189.00, 1.55, 4),
    ("Fluido de freio DOT 4 500 ml", 1, 6, 17.50, 1.90, 5),
    ("Lona de freio traseira", 1, 1, 44.00, 1.65, 3),
    ("Filtro de óleo", 2, 2, 16.00, 1.95, 10),
    ("Filtro de ar do motor", 2, 2, 27.00, 1.85, 8),
    ("Filtro de combustível", 2, 2, 22.00, 1.85, 6),
    ("Filtro de cabine", 2, 2, 24.00, 1.90, 6),
    ("Vela de ignição (jogo com 4)", 3, 3, 72.00, 1.60, 7),
    ("Correia dentada", 3, 3, 64.00, 1.60, 5),
    ("Kit correia dentada com tensor", 3, 3, 215.00, 1.45, 3),
    ("Junta do cabeçote", 3, 3, 88.00, 1.55, 2),
    ("Bobina de ignição", 3, 3, 149.00, 1.50, 3),
    ("Kit embreagem", 3, 3, 520.00, 1.35, 2),
    ("Amortecedor dianteiro", 4, 4, 185.00, 1.50, 4),
    ("Amortecedor traseiro", 4, 4, 160.00, 1.50, 3),
    ("Bieleta da barra estabilizadora", 4, 4, 38.00, 1.75, 4),
    ("Pivô de suspensão", 4, 4, 46.00, 1.75, 3),
    ("Bucha da bandeja", 4, 4, 21.00, 1.85, 3),
    ("Bateria 60 Ah", 5, 5, 390.00, 1.38, 3),
    ("Lâmpada H4 (par)", 5, 5, 26.00, 1.95, 6),
    ("Lâmpada H7 (par)", 5, 5, 31.00, 1.95, 4),
    ("Sensor de oxigênio (sonda lambda)", 5, 5, 210.00, 1.45, 2),
    ("Relé auxiliar 12 V", 5, 5, 14.00, 1.90, 3),
    ("Óleo de motor 5W30 sintético 1 L", 6, 6, 34.00, 1.55, 10),
    ("Óleo de motor 15W40 mineral 1 L", 6, 6, 21.00, 1.60, 6),
    ("Óleo de câmbio 75W80 1 L", 6, 6, 42.00, 1.55, 2),
    ("Graxa multiuso 500 g", 6, 6, 19.00, 1.80, 2),
    ("Aditivo de radiador 1 L", 7, 6, 18.00, 1.85, 5),
    ("Bomba d'água", 7, 3, 145.00, 1.50, 3),
    ("Válvula termostática", 7, 3, 68.00, 1.60, 2),
    ("Mangueira do radiador", 7, 3, 39.00, 1.70, 3),
    ("Palheta do limpador (par)", 8, 5, 29.00, 1.90, 5),
    ("Tapete de borracha (jogo)", 8, 5, 48.00, 1.80, 2),
    ("Capa de volante", 8, 5, 22.00, 2.00, 1),
]

VENDEDORES = [
    ("Ana Ribeiro", date(2022, 3, 1)),
    ("Bruno Carvalho", date(2023, 6, 12)),
    ("Carla Mendes", date(2021, 9, 6)),
    ("Diego Nunes", date(2024, 2, 19)),
    ("Elaine Prado", date(2025, 8, 4)),  # entrou no meio do período
]

CIDADES = [("São Paulo", "SP", 6), ("Guarulhos", "SP", 3), ("Osasco", "SP", 2),
           ("Santo André", "SP", 2), ("São Bernardo do Campo", "SP", 2),
           ("Mogi das Cruzes", "SP", 1), ("Barueri", "SP", 1), ("Diadema", "SP", 1)]

NOMES = ["Lucas", "Mariana", "Rafael", "Juliana", "Felipe", "Camila", "Gustavo",
         "Patrícia", "Rodrigo", "Fernanda", "Thiago", "Aline", "Marcelo", "Beatriz",
         "André", "Larissa", "Eduardo", "Renata", "Vinícius", "Tatiane"]
SOBRENOMES = ["Silva", "Santos", "Oliveira", "Souza", "Lima", "Pereira", "Costa",
              "Almeida", "Ferreira", "Gomes", "Martins", "Araújo", "Barbosa", "Rocha"]
OFICINAS = ["Oficina Mecânica", "Auto Center", "Centro Automotivo", "Mecânica",
            "Funilaria e Mecânica", "Auto Peças e Serviços"]
NOMES_FANTASIA = ["Bom Motor", "Roda Viva", "Pista Livre", "Garagem 21", "Torque Certo",
                  "São Jorge", "Dois Irmãos", "Vila Nova", "Estrela", "Rota Sul",
                  "Pit Stop", "Boa Vista", "Primavera", "Central", "Avenida"]

# Peso de cada mês no volume de vendas (sazonalidade).
SAZONALIDADE = {1: 0.80, 2: 0.85, 3: 1.00, 4: 0.95, 5: 1.00, 6: 1.05,
                7: 1.10, 8: 1.05, 9: 1.00, 10: 1.05, 11: 1.15, 12: 1.30}


def sql_texto(valor):
    return "'" + str(valor).replace("'", "''") + "'"


def sql_valor(valor):
    if isinstance(valor, str):
        return sql_texto(valor)
    if isinstance(valor, date):
        return sql_texto(valor.isoformat())
    if isinstance(valor, float):
        return f"{valor:.2f}"
    return str(valor)


def inserts(tabela, colunas, linhas, lote=50):
    blocos = []
    for i in range(0, len(linhas), lote):
        valores = ",\n".join(
            "    (" + ", ".join(sql_valor(v) for v in linha) + ")"
            for linha in linhas[i:i + lote])
        blocos.append(f"INSERT INTO {tabela} ({', '.join(colunas)}) VALUES\n{valores};")
    return "\n\n".join(blocos)


def data_aleatoria(inicio, fim):
    return inicio + timedelta(days=random.randint(0, (fim - inicio).days))


def gerar_clientes():
    clientes = []
    usados = set()
    cidades = [c for c in CIDADES for _ in range(c[2])]
    for i in range(1, 81):
        pj = i <= 30
        while True:
            if pj:
                nome = f"{random.choice(OFICINAS)} {random.choice(NOMES_FANTASIA)}"
            else:
                sobrenome1, sobrenome2 = random.sample(SOBRENOMES, 2)
                nome = f"{random.choice(NOMES)} {sobrenome1} {sobrenome2}"
            if nome not in usados:
                usados.add(nome)
                break
        cidade, uf, _ = random.choice(cidades)
        if random.random() < 0.6:
            cadastro = data_aleatoria(date(2023, 1, 1), date(2024, 12, 31))
        else:
            cadastro = data_aleatoria(INICIO, date(2026, 6, 30))
        # ~15% dos clientes param de comprar em algum momento (clientes "perdidos").
        churn = data_aleatoria(date(2025, 6, 1), date(2026, 6, 30)) if random.random() < 0.15 else None
        clientes.append({"id": i, "nome": nome, "tipo": "PJ" if pj else "PF",
                         "cidade": cidade, "uf": uf, "cadastro": cadastro, "churn": churn})
    return clientes


def main():
    clientes = gerar_clientes()
    produtos = []
    for i, (desc, cat, forn, custo, margem, pop) in enumerate(PRODUTOS, start=1):
        venda_2025 = round(custo * margem, 2)
        produtos.append({"id": i, "codigo": f"AP-{1000 + i}", "desc": desc, "cat": cat,
                         "forn": forn, "custo": custo, "venda_2025": venda_2025,
                         "venda_2026": round(venda_2025 * REAJUSTE_2026, 2), "pop": pop})

    pedidos, itens = [], []
    dia = INICIO
    id_pedido = 0
    total_dias = (FIM - INICIO).days
    while dia <= FIM:
        if dia.weekday() != 6:  # não abre aos domingos
            crescimento = 1.0 + 0.45 * (dia - INICIO).days / total_dias
            taxa = 2.2 * crescimento * SAZONALIDADE[dia.month]
            qtd_pedidos = int(taxa) + (1 if random.random() < taxa - int(taxa) else 0)
            ativos = [c for c in clientes
                      if c["cadastro"] <= dia and (c["churn"] is None or dia < c["churn"])]
            vendedores = [v for v, (_, adm) in enumerate(VENDEDORES, start=1) if adm <= dia]
            for _ in range(qtd_pedidos):
                if not ativos:
                    break
                pesos = [3 if c["tipo"] == "PJ" else 1 for c in ativos]
                cliente = random.choices(ativos, weights=pesos)[0]
                pj = cliente["tipo"] == "PJ"
                id_pedido += 1
                formas = ["PIX", "CARTAO", "BOLETO", "DINHEIRO"]
                forma = random.choices(formas, weights=[4, 3, 3, 1] if pj else [5, 4, 0, 1])[0]
                cancelado = random.random() < (0.10 if forma == "BOLETO" else 0.04)
                pedidos.append((id_pedido, cliente["id"], random.choice(vendedores), dia,
                                "CANCELADO" if cancelado else "FATURADO", forma))

                qtd_itens = random.randint(1, 5 if pj else 3)
                escolhidos = set()
                while len(escolhidos) < qtd_itens:
                    escolhidos.add(random.choices(produtos, weights=[p["pop"] for p in produtos])[0]["id"])
                for id_prod in sorted(escolhidos):
                    p = produtos[id_prod - 1]
                    # Oficinas levam mais unidades de peças baratas e poucas das caras.
                    limite_pj = 10 if p["custo"] < 50 else 4 if p["custo"] < 200 else 2
                    qtd = random.randint(1, limite_pj) if pj else random.randint(1, 2)
                    if p["custo"] >= 200 and not pj:
                        qtd = 1
                    if p["cat"] == 6 and not pj:
                        qtd = 4  # pessoa física costuma levar 4 litros de óleo
                    preco = p["venda_2026"] if dia.year >= 2026 else p["venda_2025"]
                    desconto = random.choice([0, 0, 5, 10]) if pj else random.choice([0, 0, 0, 5])
                    itens.append((id_pedido, id_prod, qtd, preco, float(desconto)))
        dia += timedelta(days=1)

    linhas_produtos = []
    for p in produtos:
        estoque_min = max(5, p["pop"] * 4)
        estoque = random.randint(0, estoque_min - 1) if random.random() < 0.2 \
            else random.randint(estoque_min, estoque_min * 4)
        ativo = 0 if p["desc"] == "Capa de volante" else 1
        linhas_produtos.append((p["id"], p["codigo"], p["desc"], p["cat"], p["forn"],
                                p["custo"], p["venda_2026"], estoque, estoque_min, ativo))

    cabecalho = "\n".join([
        "-- =============================================================",
        "-- 02_dados.sql",
        "-- Dados FICTÍCIOS gerados por scripts/gerar_dados.py (semente 42).",
        "-- Período dos pedidos: 02/01/2025 a 31/10/2026.",
        "-- =============================================================",
        "",
        "PRAGMA foreign_keys = ON;",
        "BEGIN TRANSACTION;",
    ])
    partes = [
        cabecalho,
        inserts("categorias", ["id_categoria", "nome"],
                [(i, n) for i, n in enumerate(CATEGORIAS, start=1)]),
        inserts("fornecedores", ["id_fornecedor", "razao_social", "cidade", "uf"],
                [(i, *f) for i, f in enumerate(FORNECEDORES, start=1)]),
        inserts("produtos", ["id_produto", "codigo", "descricao", "id_categoria", "id_fornecedor",
                             "preco_custo", "preco_venda", "estoque_atual", "estoque_minimo", "ativo"],
                linhas_produtos),
        inserts("clientes", ["id_cliente", "nome", "tipo", "cidade", "uf", "data_cadastro"],
                [(c["id"], c["nome"], c["tipo"], c["cidade"], c["uf"], c["cadastro"]) for c in clientes]),
        inserts("vendedores", ["id_vendedor", "nome", "data_admissao"],
                [(i, n, d) for i, (n, d) in enumerate(VENDEDORES, start=1)]),
        inserts("pedidos", ["id_pedido", "id_cliente", "id_vendedor", "data_pedido", "status",
                            "forma_pagamento"], pedidos),
        inserts("itens_pedido", ["id_pedido", "id_produto", "quantidade", "preco_unitario",
                                 "desconto_pct"], itens),
        "COMMIT;\n",
    ]
    destino = Path(__file__).resolve().parent.parent / "sql" / "02_dados.sql"
    destino.write_text("\n\n".join(partes), encoding="utf-8", newline="\n")
    print(f"{len(clientes)} clientes, {len(produtos)} produtos, "
          f"{len(pedidos)} pedidos e {len(itens)} itens gravados em {destino}")


if __name__ == "__main__":
    main()
