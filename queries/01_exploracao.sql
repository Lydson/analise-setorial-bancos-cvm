-- ============================================
-- PROJETO: Análise Setorial de Bancos Brasileiros (2016-2025)
-- ARQUIVO: 01_exploracao.sql
-- OBJETIVO: Exploração inicial das tabelas no BigQuery
--           para confirmar dados antes de calcular indicadores
-- ============================================
--
-- DIFERENÇA BigQuery vs PostgreSQL:
--   - Nome de tabela completo entre backticks: `projeto.dataset.tabela`
--   - Necessário quando o nome do projeto tem hífen (analise-bancos-brasil)
-- ============================================


-- ============================================
-- 1. CONFIRMAR OS 4 BANCOS E O VOLUME DE DADOS
-- ============================================
-- Resultado esperado: 4 bancos, 10 anos cada (2016-2025)
-- CD_CVM:
--   906   → BCO BRADESCO S.A.
--   1023  → BCO BRASIL S.A.
--   19348 → ITAU UNIBANCO HOLDING S.A.
--   20532 → BCO SANTANDER (BRASIL) S.A.
SELECT
  cd_cvm,
  denom_cia,
  COUNT(*)        AS total_linhas,
  MIN(dt_refer)   AS primeiro_ano,
  MAX(dt_refer)   AS ultimo_ano
FROM `analise-bancos-brasil.dfp_bancos.raw_dre`
GROUP BY
  cd_cvm,
  denom_cia
ORDER BY
  cd_cvm;


-- ============================================
-- 2. EXPLORAR CONTAS DA DRE (2024)
-- ============================================
-- Lista todos os nomes de conta disponíveis por banco.
-- Usado para identificar variações de nomenclatura entre bancos
-- e ao longo dos anos — problema comum em dados da CVM.
--
-- Descoberta principal:
--   Itaú usa 'Lucro/Prejuízo Consolidado do Período'
--   BB, Bradesco e Santander usam
--   'Lucro ou Prejuízo Líquido Consolidado do Período'
SELECT DISTINCT
  cd_cvm,
  denom_cia,
  ds_conta
FROM `analise-bancos-brasil.dfp_bancos.raw_dre`
WHERE
  ordem_exerc = 'ÚLTIMO'
  AND dt_refer = '2024-12-31'
ORDER BY
  cd_cvm,
  ds_conta;


-- ============================================
-- 3. EXPLORAR CONTAS DO BPP — PATRIMÔNIO LÍQUIDO
-- ============================================
-- Confirma que todos os bancos têm 'Patrimônio Líquido Consolidado'
-- com o mesmo nome (sem variações de nomenclatura).
-- Resultado: nome estável nos 4 bancos — sem necessidade de OR.
SELECT DISTINCT
  cd_cvm,
  denom_cia,
  ds_conta
FROM `analise-bancos-brasil.dfp_bancos.raw_bpp`
WHERE
  ordem_exerc = 'ÚLTIMO'
  AND dt_refer = '2024-12-31'
  AND ds_conta LIKE '%Patrimônio Líquido%'
ORDER BY
  cd_cvm,
  ds_conta;
