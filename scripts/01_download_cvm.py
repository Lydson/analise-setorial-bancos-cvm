"""
Script 1 de 3 — Download
Responsabilidade: baixar os ZIPs da CVM (2016-2025) e salvar localmente.
Não filtra, não transforma — apenas baixa e salva.
"""

import requests
import os

# --- Configurações ---
ANOS = range(2016, 2026)
URL_BASE = "https://dados.cvm.gov.br/dados/CIA_ABERTA/DOC/DFP/DADOS/dfp_cia_aberta_{ano}.zip"
PASTA_RAW = "dados/raw"

# --- Bancos que serão analisados ---
# O filtro acontece no Script 2, mas já documentamos aqui
# quais bancos fazem parte do escopo do projeto
BANCOS_ESCOPO = [
    "BCO BRASIL S.A.",
    "ITAU UNIBANCO HOLDING S.A.",
    "BCO BRADESCO S.A.",
    "BCO SANTANDER (BRASIL) S.A.",
]


def criar_pasta():
    os.makedirs(PASTA_RAW, exist_ok=True)
    print(f"Pasta '{PASTA_RAW}' pronta.")


def baixar_zip(ano):
    """Baixa o ZIP de um ano específico e salva localmente."""
    url = URL_BASE.format(ano=ano)
    caminho = os.path.join(PASTA_RAW, f"dfp_cia_aberta_{ano}.zip")

    if os.path.exists(caminho):
        print(f"[SKIP] {ano} — já existe em {caminho}")
        return

    print(f"[DOWN] Baixando {url} ...")
    resposta = requests.get(url, timeout=60)
    resposta.raise_for_status()

    with open(caminho, "wb") as f:
        f.write(resposta.content)

    tamanho_mb = len(resposta.content) / 1_000_000
    print(f"[OK]   {ano} — {tamanho_mb:.1f} MB salvo em {caminho}")


def main():
    criar_pasta()
    print(f"\nBaixando DFPs de {min(ANOS)} a {max(ANOS)}...")
    print(f"Escopo de análise: {len(BANCOS_ESCOPO)} bancos")
    print("(Filtro aplicado no Script 2 — extract_transform.py)\n")

    for ano in ANOS:
        try:
            baixar_zip(ano)
        except requests.exceptions.RequestException as e:
            print(f"[ERRO] {ano}: {e}")

    print("\n✅ Download concluído.")
    print(f"Arquivos salvos em: {PASTA_RAW}")


if __name__ == "__main__":
    main()