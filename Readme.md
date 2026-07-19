# Análise Setorial de Bancos Brasileiros (2016-2025)

Projeto de análise de dados aplicado a finanças, comparando os **4 maiores
bancos brasileiros** usando dados públicos da CVM (Comissão de Valores
Mobiliários), Python e BigQuery.

## Dashboard

![Dashboard Análise Setorial](docs/dashboard_preview.png)

🔗 [Acessar dashboard no Looker Studio](https://datastudio.google.com/...)

---

## Objetivo

Construir uma pipeline ETL completa (do dado bruto ao dashboard) para
responder:

- Como o ROE dos 4 maiores bancos evoluiu entre 2016 e 2025?
- Qual banco é mais eficiente operacionalmente?
- Como a Selic afetou a Margem Financeira do setor?
- Quem cresceu mais em lucro e receita na última década (CAGR)?
- Como cada banco se comportou em crises (pandemia 2020, agro 2024-2025)?

---

## Bancos analisados

| Banco | Código CVM | Ticker |
|---|:---:|:---:|
| Banco do Brasil | 1023 | BBAS3 |
| Bradesco | 906 | BBDC4 |
| Itaú Unibanco | 19348 | ITUB4 |
| Santander Brasil | 20532 | SANB11 |

> Identificação feita via `CD_CVM` (código numérico oficial da CVM),
> mais robusto que filtro por nome — evita capturar empresas com nomes
> similares (ex: Itaúsa ao buscar por "Itaú").

---

## Indicadores calculados

| Indicador | Fórmula | Tabela fonte |
|---|---|:---:|
| **ROE** | Lucro Líquido / Patrimônio Líquido | DRE + BPP |
| **Margem Financeira** | Resultado Bruto / Receita de Intermediação | DRE |
| **Índice de Eficiência** | Despesas Adm. / Receitas Operacionais | DRE |
| **YoY Lucro** | (Lucro atual − anterior) / anterior | DRE |
| **YoY Receita** | (Receita atual − anterior) / anterior | DRE |
| **CAGR Lucro** | (Lucro 2025 / Lucro 2016)^(1/9) − 1 | DRE |
| **CAGR Receita** | (Receita 2025 / Receita 2016)^(1/9) − 1 | DRE |

---

## Stack

- **Python** — pipeline ETL (download, extração, transformação, carga)
- **Google BigQuery** — armazenamento e queries analíticas na nuvem
- **SQL** — CTEs, JOINs, CASE WHEN, LAG(), POWER(), PARTITION BY, VIEWs
- **Looker Studio** — dashboard interativo (integração nativa com BigQuery)

---

## Fonte de dados

[Portal de Dados Abertos da CVM](https://dados.cvm.gov.br/dados/CIA_ABERTA/DOC/DFP/DADOS/)
— Demonstrações Financeiras Padronizadas (DFP), 2016-2025.

Arquivos ZIP baixados automaticamente via Python, extraídos e filtrados
pelos 4 bancos, carregados em 3 tabelas no BigQuery.

---

## Arquitetura da solução

```
CVM (dados públicos)
       │
       ▼
01_download_cvm.py          ← baixa os ZIPs (2016-2025)
       │
       ▼
02_extract_transform.py     ← extrai CSVs, filtra por CD_CVM, limpa
       │
       ▼
03_upload_bigquery.py       ← carrega nas tabelas raw_* do BigQuery
       │
       ▼
BigQuery (dfp_bancos)
├── raw_bpa    ← Balanço Patrimonial Ativo
├── raw_bpp    ← Balanço Patrimonial Passivo
└── raw_dre    ← Demonstração de Resultado
       │
       ▼
SQL (queries/)              ← indicadores financeiros
       │
       ▼
Looker Studio               ← dashboard comparativo
```

---

## Modelo de dados

Três tabelas com estrutura idêntica, separadas por tipo de demonstrativo.
Todos os 4 bancos estão nas mesmas tabelas — a coluna `cd_cvm` identifica
o banco em cada linha.

| Coluna | Tipo | Descrição |
|---|---|---|
| `cnpj_cia` | STRING | CNPJ da empresa |
| `dt_refer` | STRING | Data de referência (ex: 2024-12-31) |
| `versao` | INTEGER | Versão da entrega na CVM |
| `denom_cia` | STRING | Nome da empresa |
| `cd_cvm` | INTEGER | Código oficial da CVM |
| `grupo_dfp` | STRING | Tipo de demonstrativo |
| `moeda` | STRING | Moeda (sempre REAL) |
| `escala_moeda` | STRING | Escala (MIL = valores em R$ mil) |
| `ordem_exerc` | STRING | ÚLTIMO ou PENÚLTIMO |
| `dt_fim_exerc` | STRING | Data fim do exercício |
| `cd_conta` | STRING | Código da conta contábil |
| `ds_conta` | STRING | Descrição da conta contábil |
| `vl_conta` | FLOAT | Valor da conta |
| `st_conta_fixa` | STRING | S/N — conta fixa no plano |

> **Importante**: cada arquivo DFP da CVM contém o ano atual (`ÚLTIMO`)
> e o ano anterior (`PENÚLTIMO`) para comparação. As queries filtram
> sempre `ordem_exerc = 'ÚLTIMO'` para evitar duplicação.

---

## Estrutura do repositório

```
├── scripts/
│   ├── 01_download_cvm.py          # baixa ZIPs da CVM
│   ├── 02_extract_transform.py     # extrai, filtra e limpa dados
│   └── 03_upload_bigquery.py       # carrega no BigQuery
├── queries/
│   ├── 01_exploracao.sql           # exploração inicial das tabelas
│   ├── 02_roe_setorial.sql         # ROE comparativo dos 4 bancos
│   ├── 03_margem_financeira.sql    # Margem Financeira setorial
│   ├── 04_indice_eficiencia.sql    # Índice de Eficiência setorial
│   ├── 05_yoy_setorial.sql         # YoY com PARTITION BY banco
│   ├── 06_cagr_setorial.sql        # CAGR comparativo
│   └── 07_view_consolidada.sql     # VIEW com todos os indicadores
├── dashboard/
│   └── prints/                     # screenshots do Looker Studio
├── docs/
│   └── dashboard_preview.png       # preview do dashboard
├── requirements.txt
└── README.md
```

---

## Como reproduzir

### Pré-requisitos

- Python 3.11+
- Conta Google Cloud com BigQuery ativado
- Service Account com permissões `BigQuery Data Editor` e `BigQuery Job User`

### Instalação

```bash
git clone https://github.com/Lydson/analise-setorial-bancos-cvm.git
cd analise-setorial-bancos-cvm
pip install -r requirements.txt
```

### Credenciais

Coloque o arquivo JSON da Service Account em `credentials/` e configure:

```bash
# Windows PowerShell
$env:GOOGLE_APPLICATION_CREDENTIALS = "credentials/seu-arquivo.json"

# Mac/Linux
export GOOGLE_APPLICATION_CREDENTIALS="credentials/seu-arquivo.json"
```

### Execução

```bash
# 1. Baixar os dados da CVM
python scripts/01_download_cvm.py

# 2. Extrair e transformar
python scripts/02_extract_transform.py

# 3. Carregar no BigQuery
python scripts/03_upload_bigquery.py
```

### Queries SQL

As queries estão na pasta `queries/` e podem ser rodadas diretamente
no console do BigQuery (`console.cloud.google.com/bigquery`).

---

## Conceitos SQL aplicados

| Conceito | Onde foi usado |
|---|---|
| `JOIN` | Cruzar DRE com BPP para calcular ROE |
| `CASE WHEN` | Pivotar contas em colunas (Margem, Eficiência) |
| `GROUP BY` | Agregar por banco e ano |
| CTEs (`WITH`) | Organizar queries complexas em etapas |
| `LAG()` | YoY — variação ano a ano |
| `PARTITION BY` | Reiniciar o LAG para cada banco independentemente |
| `POWER()` | CAGR — taxa composta de crescimento |
| `CREATE VIEW` | Consolidar todos os indicadores em uma consulta |

> **Novidade em relação ao projeto anterior (BB individual):**
> `PARTITION BY` dentro de `LAG()` — divide a janela por banco,
> calculando o YoY de cada banco de forma independente na mesma query.

---

## Status

🚧 Em desenvolvimento

- [x] Pipeline ETL (download → extract → upload BigQuery)
- [ ] Queries SQL analíticas
- [ ] VIEW consolidada
- [ ] Dashboard no Looker Studio

---

## Projeto anterior

Este projeto é a continuação de:
[Análise Financeira: Banco do Brasil (2016-2025)](https://github.com/Lydson/Analise_Banco_do_Brasil_CVM)

---

## Autor

**Lydson** — Analista de Operações com foco em dados financeiros

[GitHub](https://github.com/Lydson) · [LinkedIn](https://www.linkedin.com/in/lydson/)