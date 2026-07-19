"""
Script 3 de 3 — Upload para o BigQuery
Responsabilidade: ler os CSVs processados e carregar
nas tabelas raw_bpa, raw_bpp, raw_dre do BigQuery.
"""

import os
import pandas as pd
from google.cloud import bigquery

# --- Credenciais ---
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = \
    "credentials/analise-bancos-brasil-71f20dcbbe2d.json"

# --- Configurações ---
PROJETO = "analise-bancos-brasil"
DATASET = "dfp_bancos"
PASTA_PROCESSADOS = "dados/processados"

# Mapeamento: arquivo CSV → tabela no BigQuery
TABELAS = {
    "bpa_bancos.csv": "raw_bpa",
    "bpp_bancos.csv": "raw_bpp",
    "dre_bancos.csv": "raw_dre",
}


def carregar_tabela(client, df, nome_tabela):
    """
    Carrega um DataFrame numa tabela do BigQuery.
    write_disposition='WRITE_TRUNCATE' recria a tabela
    do zero a cada execução — útil para re-rodar sem duplicar.
    """
    tabela_ref = f"{PROJETO}.{DATASET}.{nome_tabela}"

    job_config = bigquery.LoadJobConfig(
        write_disposition="WRITE_TRUNCATE",
        autodetect=True,  # BigQuery infere os tipos das colunas
    )

    job = client.load_table_from_dataframe(
        df, tabela_ref, job_config=job_config
    )
    job.result()  # aguarda conclusão

    tabela = client.get_table(tabela_ref)
    print(f"  ✅ {nome_tabela}: {tabela.num_rows:,} linhas carregadas")


def main():
    print("Conectando ao BigQuery...")
    client = bigquery.Client(project=PROJETO)
    print(f"Projeto: {client.project}\n")

    for arquivo, tabela in TABELAS.items():
        caminho = os.path.join(PASTA_PROCESSADOS, arquivo)

        if not os.path.exists(caminho):
            print(f"[AVISO] {arquivo} não encontrado — rode o Script 2 primeiro")
            continue

        print(f"Carregando {arquivo} → {DATASET}.{tabela} ...")
        df = pd.read_csv(caminho, encoding="utf-8")
        print(f"  Linhas lidas: {len(df):,}")

        carregar_tabela(client, df, tabela)

    print("\n✅ Upload concluído.")
    print(f"Acesse: console.cloud.google.com/bigquery → {PROJETO} → {DATASET}")


if __name__ == "__main__":
    main()
