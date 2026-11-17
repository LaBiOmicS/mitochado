# mitoChado: The Mitochondrial Multi-Omics Database Engine

**mitoChado** é um schema relacional e motor de dados especializado em **mitogenômica, mitotranscriptômica, mitoproteômica e mitofilogenômica** para PostgreSQL (16/17+) com suporte a vetores (`pgvector`).

Enquanto genomas nucleares lidam com dezenas de cromossomos lineares de bilhões de pares de bases, a biologia mitocondrial possui particularidades únicas que são distorcidas quando forçadas em schemas genéricos como o Chado tradicional:
- **Genomas circulares compactos** (~16.5 kb em animais) e coordenadas que atravessam a origem;
- **Códigos genéticos mitocondriais próprios** (Tabelas NCBI 2, 5, 9, 14...) com códons de início/parada não-canônicos;
- **Sintenia e Ordem Gênica canônica** (13 PCGs, 22 tRNAs, 2 rRNAs) crucial para filogenômica de metazoários;
- **Mitotranscriptômica e Modelo de Pontuação por tRNA**: Clivagem de precursores policistrônicos gigantes por RNase P e ELAC2;
- **Poliadenilação formadora de códon de parada** (códons incompletos T/TA terminados em TAA via poly-A);
- **Peptídeos Derivados de Mitocôndria (MDPs)** como **Humanin**, MOTS-c e SHLPs codificados em pequenos ORFs alternativos;
- **Origem Genética Dual do Mitoproteoma**: 13 proteínas de origem mtDNA vs ~1500 nucleares importadas via sinal de endereçamento mitocondrial (MTS);
- **Heteroplasmia** e quantificação de frações alélicas patogênicas (MELAS, MERRF, LHON).

---

## 📂 Arquitetura do Repositório

```
mitoChado/
├── docker/
│   └── docker-compose.yml       # PostgreSQL 17 + pgvector na porta 5433
├── schema/
│   ├── 00_extensions.sql        # btree_gist, uuid-ossp, vector
│   ├── 01_taxa_and_mitogenome.sql # Organismos, Códigos Genéticos NCBI e MtDNA
│   ├── 02_features_and_genes.sql# 13 PCGs, 22 tRNAs, 2 rRNAs, MDPs (Humanin), D-Loop
│   ├── 03_mitotranscriptomics.sql # Precursores policistrônicos, clivagem, RNA editing, expressão
│   ├── 04_mitoproteomics_and_oxphos.sql # Complexos I-V, origem dual, MTS, PTMs, vetores IA
│   ├── 05_mitophylogenomics_and_variants.sql # Haplogrupos, Heteroplasmia e Rearranjos de Sintenia
│   └── 06_seed_mitochondrial_core.sql # Seed de Códigos Genéticos NCBI e Haplogrupos canônicos
├── src/mitochado/
│   ├── cli.py                   # Interface de linha de comando (`mitochado`)
│   ├── db.py                    # Conexão e execução de migrações
│   └── loaders/                 # Parsers e ingestores mitocondriais
├── docs/
│   └── SPECIFICATION.md         # Especificação formal detalhada
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
  --code-id 2
```
