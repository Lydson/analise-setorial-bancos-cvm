-- ============================================
-- PROJETO: Análise Setorial de Bancos Brasileiros (2016-2025)
-- ARQUIVO: 03_margem_financeira_setorial.sql
-- OBJETIVO: Calcular a Margem Financeira anual dos 4 maiores bancos
-- ============================================
--
-- CONCEITO:
-- Margem Financeira = Resultado Bruto de Intermediação Financeira
--                     / Receitas de Intermediação Financeira × 100
--
-- Equivalente à "margem bruta" para bancos — mede quanto sobra
-- da atividade-fim (captar e emprestar) ANTES de despesas
-- operacionais, pessoal e impostos.
--
-- VARIAÇÕES DE NOMENCLATURA ENTRE BANCOS:
-- BB, Bradesco, Santander: 'Receitas de Intermediação Financeira'
--                          'Resultado Bruto de Intermediação Financeira'
-- Itaú:                    'Receitas da Intermediação Financeira'
--                          'Resultado Bruto Intermediação Financeira'
-- Solução: IN ('variação1', 'variação2') dentro do CASE WHEN
-- IN é mais legível que OR quando há múltiplos valores equivalentes.
--
-- DIFERENÇA vs PROJETO BB:
-- Adicionamos cd_cvm e denom_cia no SELECT e GROUP BY para
-- manter os 4 bancos separados na mesma query.
-- ============================================


-- ============================================
-- EXPLORAÇÃO: nomes de conta de Intermediação por banco (2024)
-- ============================================
-- Confirma variações de nomenclatura antes de montar a query final.
SELECT DISTINCT
  cd_cvm,
  denom_cia,
  ds_conta
FROM `analise-bancos-brasil.dfp_bancos.raw_dre`
WHERE
  ordem_exerc = 'ÚLTIMO'
  AND dt_refer = '2024-12-31'
  AND (ds_conta LIKE '%Intermediação%'
    OR ds_conta LIKE '%Resultado Bruto%')
ORDER BY
  cd_cvm,
  ds_conta;


-- ============================================
-- MARGEM FINANCEIRA SETORIAL (2016-2025)
-- ============================================
-- CTE usa SUM(CASE WHEN) para pivotar duas contas diferentes
-- (Receita e Resultado Bruto) em colunas separadas sem JOIN.
-- GROUP BY por dt_refer + cd_cvm + denom_cia garante uma linha
-- por banco por ano.
--
-- Insights observados:
--   2020: Selic na mínima histórica (2%) — despesas de captação
--         caíram, inflando a margem bruta de todos os bancos
--   2022: Selic subiu para 13,75% — receita quase dobrou, mas
--         despesas de captação também subiram, comprimindo a margem
--   2025: Bradesco com menor margem (28,25%) — pressão de custos
--         de captação com Selic alta e carteira mais arriscada
WITH margem_base AS (
  SELECT
    dt_refer,
    cd_cvm,
    denom_cia,
    SUM(CASE WHEN ds_conta IN (
      'Receitas de Intermediação Financeira',
      'Receitas da Intermediação Financeira'
    ) THEN vl_conta ELSE 0 END) AS receita_financeira,
    SUM(CASE WHEN ds_conta IN (
      'Resultado Bruto de Intermediação Financeira',
      'Resultado Bruto Intermediação Financeira'
    ) THEN vl_conta ELSE 0 END) AS resultado_bruto
  FROM `analise-bancos-brasil.dfp_bancos.raw_dre`
  WHERE ordem_exerc = 'ÚLTIMO'
  GROUP BY
    dt_refer,
    cd_cvm,
    denom_cia
)
SELECT
  dt_refer,
  denom_cia,
  receita_financeira,
  resultado_bruto,
  ROUND((resultado_bruto / receita_financeira) * 100, 2) AS margem_financeira
FROM margem_base
ORDER BY
  denom_cia,
  dt_refer;
