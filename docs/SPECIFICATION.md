# Especificação Formal: mitoChado (Edição Enxuta & Focada)

O **mitoChado** é um schema relacional e motor de dados especializado na **genômica, transcriptômica e filogenômica mitocondrial**.

Ele foca exclusivamente no que define a biologia mitocondrial computacional, sem inchaço e sem tabelas desnecessárias de dados clínicos ou biofísicos.

---

## 1. O Núcleo Mitogenômico

| Dimensão | O que o mitoChado resolve |
| :--- | :--- |
| **Topologia Circular & Origem** | Modela anéis circulares que cruzam a coordenada zero (`spans_origin`), além de genomas lineares (*Plasmodium*) e multipartites (plantas). |
| **Códigos Genéticos NCBI** | Suporte às tabelas de tradução mitocondrial do NCBI (Tabela 1 a 24). |
| **Sintenia e Ordem Gênica** | Ordem circular dos 37 genes canônicos (13 PCGs, 22 tRNAs, 2 rRNAs) e detecção de rearranjos filogenômicos. |
| **Heteroplasmia Real** | Nível de heteroplasmia de variantes (`heteroplasmy_level` de 0.00 a 1.00) e cálculo automático de homoplasmia. |
| **Mitotranscriptômica** | Precursores policistrônicos, clivagem de tRNAs (*tRNA punctuation model*) e eventos de **RNA editing** (C-para-U em plantas). |
| **Códons Incompletos** | Modelação de terminação formadora de códon via poliadenilação pós-transcricional. |
| **Peptídeos Mitocondriais (MDPs)** | Modelação direta de **Humanin** e **MOTS-c** como features biológicas originárias dos rRNAs. |

---

## 2. Estrutura dos Schemas

```
schema/
├── 00_extensions.sql        # btree_gist, uuid-ossp, vector
├── 01_taxa_and_mitogenome.sql # Organismos (TaxID), Mitogenomas (Comprimento, Topologia, Código NCBI, Skew)
├── 02_features_and_genes.sql# 13 PCGs, 22 tRNAs (cloverleaf), 2 rRNAs, MDPs (Humanin), D-Loop e Sintenia
├── 03_mitotranscriptomics.sql # Precursores policistrônicos, clivagem por tRNA, RNA editing (C->U) e TPM
├── 04_mitoproteomics_and_oxphos.sql # Subunidades OXPHOS (Complexos I a V) e sequências proteicas
├── 05_mitophylogenomics_and_variants.sql # Variantes, Heteroplasmia, Haplogrupos e Supermatrizes filogenômicas
├── 06_seed_mitochondrial_core.sql # Seed de Códigos Genéticos NCBI (1-24) e Haplogrupos basais
└── 07_plant_fungal_introns_trans_splicing.sql # Íntrons de Grupo I/II e trans-splicing em plantas
```

---

## 3. Entidades Centrais

1. **`mitogenome`**: Montagem mitocondrial, comprimento, topologia (`circular_single`, `circular_multipartite`, `linear_tandem`), código genético, %GC e AT/GC skew.
2. **`mitofeature`**: Genes, tRNAs (com anticódon e estrutura secundária), rRNAs, MDPs (Humanin, MOTS-c), códons de início/fim e ordem de sintenia.
3. **`mitochondrial_variant`**: Posição, alelos de referência e mutante, nível de heteroplasmia (0.00 a 1.00) e significância funcional.
4. **`mitorna_editing`**: Edição de RNA pós-transcricional (frequência, tipo de conversão).
5. **`mitogenome_gene_order`**: Ordem gênica serializada e distância de quebra (*breakpoint distance*).
6. **`mitoprotein`**: Subunidades de OXPHOS (Complexos I a V).
