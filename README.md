# mitoChado: The Mitochondrial Genomics Database Engine

**mitoChado** é um schema relacional e motor de dados especializado em **genômica, transcriptômica e filogenômica mitocondrial** para PostgreSQL (16/17+) com suporte a vetores (`pgvector`).

Ele foca no que realmente importa na biologia computacional de mitocôndrias, eliminando o inchaço do Chado tradicional e tratando com precisão matemática as peculiaridades do mtDNA:
- **Genomas circulares compactos** (~16.5 kb em animais) e coordenadas que atravessam a origem;
- **Códigos genéticos mitocondriais do NCBI** (Tabelas 1 a 24) com códons de início/parada específicos de cada táxon;
- **Sintenia e Ordem Gênica** (13 PCGs, 22 tRNAs, 2 rRNAs) essencial para mitofilogenômica;
- **Mitotranscriptômica Real**: Precursores policistrônicos, clivagem por tRNA (*tRNA punctuation model*) e **RNA editing** (C-para-U em plantas);
- **Poliadenilação formadora de códon** (códons incompletos T/TA terminados em TAA via poly-A);
- **Peptídeos Derivados de Mitocôndria (MDPs)** como **Humanin** e **MOTS-c**;
- **Heteroplasmia Contínua** (fração de 0.00 a 1.00 com detecção automática de homoplasmia).

---

## 📂 Arquitetura do Repositório

```
mitoChado/
├── docker/
│   └── docker-compose.yml       # PostgreSQL 17 + pgvector na porta 5433
├── schema/
│   ├── 00_extensions.sql        # btree_gist, uuid-ossp, vector
│   ├── 01_taxa_and_mitogenome.sql # Organismos, Códigos Genéticos NCBI, Mitogenomas e Skew
│   ├── 02_features_and_genes.sql# 13 PCGs, 22 tRNAs, 2 rRNAs, MDPs (Humanin), D-Loop e Sintenia
│   ├── 03_mitotranscriptomics.sql # Precursores policistrônicos, clivagem por tRNA, RNA editing e TPM
│   ├── 04_mitoproteomics_and_oxphos.sql # Mapeamento de subunidades OXPHOS (Complexos I a V)
│   ├── 05_mitophylogenomics_and_variants.sql # Variantes, Heteroplasmia, Haplogrupos e Supermatrizes
│   ├── 06_seed_mitochondrial_core.sql # Seed de Códigos Genéticos NCBI (1-24) e Haplogrupos
│   └── 07_plant_fungal_introns_trans_splicing.sql # Íntrons catalíticos e trans-splicing em plantas
├── src/mitochado/
│   ├── cli.py                   # Interface de linha de comando (`mitochado`)
│   ├── db.py                    # Conexão e execução de migrações
│   └── loaders/                 # Parsers e ingestores mitocondriais
├── docs/
│   └── SPECIFICATION.md         # Especificação formal enxuta
└── pyproject.toml
```

---

## ⚡ Início Rápido

### 1. Subir o Banco mitoChado com Docker
```bash
cd docker
docker compose up -d
```

### 2. Configurar o Ambiente Python
```bash
uv venv
source .venv/bin/activate
uv pip install -e .
```

### 3. Executar o CLI
```bash
# Testar conexão
mitochado ping

# Inicializar o schema mitoChado
mitochado init-db

# Registrar o mitogenoma de referência humano (rCRS)
mitochado add-mitogenome \
  --taxid 9606 \
  --scientific-name "Homo sapiens" \
  --accession "NC_012920.1" \
  --name "rCRS (Homo sapiens revised Cambridge Reference Sequence)" \
  --length 16569 \
  --code-id 2 \
  --topology circular_single \
  --clade Metazoa
```
