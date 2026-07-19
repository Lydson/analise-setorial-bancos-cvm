"""
Script 2 de 3 — Extract & Transform

Responsabilidade:
- Abrir os ZIPs da CVM
- Extrair os demonstrativos consolidados (BPA, BPP e DRE)
- Filtrar apenas os 4 maiores bancos
- Salvar CSVs prontos para carregar no BigQuery
"""

import os
import zipfile

import pandas as pd

# ==========================
# Configurações
# ==========================

ANOS = range(2016, 2026)

PASTA_RAW = "dados/raw"
PASTA_PROCESSADOS = "dados/processados"

# Códigos oficiais da CVM
BANCOS = {
    1023: "Banco do Brasil",
    906: "Bradesco",
    19348: "Itaú Unibanco",
    20532: "Santander",
}

DEMONSTRATIVOS = [
    "BPA",
    "BPP",
    "DRE",
]


def criar_pasta():
    os.makedirs(PASTA_PROCESSADOS, exist_ok=True)
    print(f"Pasta '{PASTA_PROCESSADOS}' pronta.")


def extrair_ano(ano):
    """
    Abre o ZIP de um ano e retorna um dicionário
    contendo os DataFrames filtrados.
    """

    caminho_zip = os.path.join(
        PASTA_RAW,
        f"dfp_cia_aberta_{ano}.zip"
    )

    if not os.path.exists(caminho_zip):
        print(f"[AVISO] ZIP de {ano} não encontrado.")
        return {}

    resultados = {}

    with zipfile.ZipFile(caminho_zip) as zf:

        for tipo in DEMONSTRATIVOS:

            nome_csv = f"dfp_cia_aberta_{tipo}_con_{ano}.csv"

            if nome_csv not in zf.namelist():
                print(f"[AVISO] {nome_csv} não encontrado.")
                continue

            with zf.open(nome_csv) as arquivo:

                df = pd.read_csv(
                    arquivo,
                    sep=";",
                    encoding="latin-1"
                )

            # ==========================
            # Filtra pelos códigos CVM
            # ==========================

            df_filtrado = df[
                df["CD_CVM"].isin(BANCOS.keys())
            ].copy()

            df_filtrado.columns = (
                df_filtrado.columns.str.lower()
            )

            print(f"\n[{tipo}] {ano}")

            for codigo, nome in BANCOS.items():

                qtd = (
                    df_filtrado["cd_cvm"] == codigo
                ).sum()

                print(f"   {nome:<18} {qtd:>4} linhas")

            resultados[tipo] = df_filtrado

    return resultados


def main():

    criar_pasta()

    print(
        f"\nProcessando DFPs "
        f"de {min(ANOS)} a {max(ANOS)}...\n"
    )

    consolidado = {
        tipo: []
        for tipo in DEMONSTRATIVOS
    }

    for ano in ANOS:

        print("=" * 40)
        print(f"Ano {ano}")

        dados = extrair_ano(ano)

        for tipo, df in dados.items():
            consolidado[tipo].append(df)

    print("\nSalvando arquivos...")

    for tipo, lista in consolidado.items():

        if not lista:
            continue

        df_final = pd.concat(
            lista,
            ignore_index=True
        )

        caminho = os.path.join(
            PASTA_PROCESSADOS,
            f"{tipo.lower()}_bancos.csv"
        )

        df_final.to_csv(
            caminho,
            index=False,
            encoding="utf-8"
        )

        print(f"\n✅ {tipo}")
        print(f"Linhas: {len(df_final):,}")
        print(f"Arquivo: {caminho}")

        print("\nEmpresas encontradas:")

        for empresa in sorted(
            df_final["denom_cia"].unique()
        ):
            print(f"   • {empresa}")

    print("\n✅ Extract & Transform concluído.")


if __name__ == "__main__":
    main()