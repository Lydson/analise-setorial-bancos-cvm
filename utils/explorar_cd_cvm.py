import zipfile
import pandas as pd

ANO = 2025

with zipfile.ZipFile(f"dados/raw/dfp_cia_aberta_{ANO}.zip") as zf:
    with zf.open(f"dfp_cia_aberta_DRE_con_{ANO}.csv") as f:
        df = pd.read_csv(f, sep=";", encoding="latin-1")

empresas = (
    df[["CD_CVM", "DENOM_CIA"]]
    .drop_duplicates()
    .sort_values("DENOM_CIA")
)

# Mostrar apenas bancos conhecidos
filtro = empresas["DENOM_CIA"].str.contains(
    "BRASIL|ITAU|ITAÚ|BRAD|SANTANDER",
    case=False,
    na=False,
)

print(empresas[filtro].to_string(index=False))