-- ============================================
-- PROJETO: Análise Setorial de Bancos Brasileiros (2016-2025)
-- ARQUIVO: 02_roe_setorial.sql
-- OBJETIVO: Calcular o ROE anual dos 4 maiores bancos brasileiros
-- ============================================
--
-- CONCEITO:
-- ROE (Return on Equity) = Lucro Líquido / Patrimônio Líquido × 100
-- Mede quanto o banco gera de lucro para cada R$100 de capital
-- dos acionistas. Quanto maior, mais rentável.
--
-- DIFERENÇA vs PROJETO BB (banco único):
-- JOIN agora usa DUAS colunas de ligação:
--   ON dre.dt_refer = bpp.dt_refer       ← mesmo ano
--   AND dre.cd_cvm = bpp.cd_cvm          ← mesmo banco
-- Sem o segundo critério, o lucro do BB cruzaria com o PL
-- do Itaú (mesma data, bancos diferentes) — resultado incorreto.
--
-- VARIAÇÕES DE NOMENCLATURA (CVM):
-- O Itaú usa nome diferente para a conta de Lucro Líquido:
--   BB, Bradesco, Santander: 'Lucro ou Prejuízo Líquido Consolidado do Período'
--   Itaú:                    'Lucro/Prejuízo Consolidado do Período'
-- Solução: OR com parênteses (sem parênteses, AND tem precedência
-- maior que OR e o filtro de ordem_exerc não se aplicaria a ambos)
-- ============================================


-- ============================================
-- PASSO 1: Lucro Líquido por banco e ano (exploração)
-- ============================================
-- Valida os dados antes de calcular o ROE completo.
-- Resultado esperado: 40 linhas (4 bancos × 10 anos), sem duplicação.
WITH lucro_anual AS (
  SELECT
    dt_refer,
    cd_cvm,
    denom_cia,
    vl_conta AS lucro_liquido
  FROM `analise-bancos-brasil.dfp_bancos.raw_dre`
  WHERE
    (ds_conta = 'Lucro ou Prejuízo Líquido Consolidado do Período'
    OR ds_conta = 'Lucro/Prejuízo Consolidado do Período')
    AND ordem_exerc = 'ÚLTIMO'
)
SELECT * FROM lucro_anual
ORDER BY denom_cia, dt_refer;


-- ============================================
-- PASSO 2: ROE SETORIAL (2016-2025)
-- ============================================
-- JOIN entre DRE (lucro) e BPP (patrimônio líquido)
-- usando cd_cvm + dt_refer como chave composta.
--
-- Insights observados:
--   Itaú: ROE consistentemente acima de 17%, chegando a 21,32% em 2025
--   Bradesco: queda de 17% (2016) para 8,68% (2023) — maior deterioração
--   BB e Santander: trajetórias similares, queda em 2025 (crise agro/outros)
--   Contraste 2025: Itaú subiu para 21,32% enquanto BB caiu para 8,67%
WITH lucro_anual AS (
  SELECT
    dt_refer,
    cd_cvm,
    denom_cia,
    vl_conta AS lucro_liquido
  FROM `analise-bancos-brasil.dfp_bancos.raw_dre`
  WHERE
    (ds_conta = 'Lucro ou Prejuízo Líquido Consolidado do Período'
    OR ds_conta = 'Lucro/Prejuízo Consolidado do Período')
    AND ordem_exerc = 'ÚLTIMO'
),
patrimonio_anual AS (
  SELECT
    dt_refer,
    cd_cvm,
    denom_cia,
    vl_conta AS patrimonio_liquido
  FROM `analise-bancos-brasil.dfp_bancos.raw_bpp`
  WHERE
    ds_conta = 'Patrimônio Líquido Consolidado'
    AND ordem_exerc = 'ÚLTIMO'
)
SELECT
  lucro_anual.dt_refer,
  lucro_anual.denom_cia,
  lucro_anual.lucro_liquido,
  patrimonio_anual.patrimonio_liquido,
  ROUND(
    (lucro_anual.lucro_liquido / patrimonio_anual.patrimonio_liquido) * 100
  , 2) AS roe_percentual
FROM lucro_anual
JOIN patrimonio_anual
  ON lucro_anual.dt_refer = patrimonio_anual.dt_refer
  AND lucro_anual.cd_cvm = patrimonio_anual.cd_cvm
ORDER BY
  lucro_anual.denom_cia,
  lucro_anual.dt_refer;
