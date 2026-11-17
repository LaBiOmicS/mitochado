# Roadmap de Expansões Futuras: mitoChado (Plantas, Fungos, Protistas & Códigos Genéticos)

Este documento preserva em detalhes todo o planejamento, estrutura DDL e modelo biológico para as extensões do **mitoChado** na árvore da vida, prontas para serem ativadas quando retornarmos.

---

## 1. Mapeamento Completo de Códigos Genéticos Mitocondriais do NCBI

O mitoChado suportará nativamente todas as tabelas oficiais de tradução mitocondrial:

| NCBI ID | Nome do Código | Táxons de Aplicação | Regras Específicas de Códons |
| :---: | :--- | :--- | :--- |
| **1** | Standard / Universal | **Plantas terrestres** (*Viridiplantae*) | TAA, TAG, TGA são Stop; ATG, CTG, TTG como Start |
| **2** | Vertebrate Mitochondrial | Mamíferos, aves, répteis, anfíbios, peixes | UGA = Trp; AGA/AGG = **Stop**; AUA = Met |
| **3** | Yeast Mitochondrial | Leveduras (*Saccharomyces*, etc.) | UGA = Trp; **CUN = Thr** (em vez de Leu!); AUA = Met |
| **4** | Mold & Protozoan Mt | Fungos filamentosos, protozoários flagelados | UGA = Trp; UUG e CUG funcionam como Start |
| **5** | Invertebrate Mitochondrial | Artrópodes, moluscos, nematódeos | UGA = Trp; **AGA/AGG = Ser**; AUA = Met |
| **9** | Echinoderm & Flatworm Mt | Equinodermos e platelmintos | UGA = Trp; **AAA = Asn**; AGA/AGG = Ser |
| **13** | Ascidian Mitochondrial | Urocordados / Ascídias | UGA = Trp; **AGA/AGG = Gly** |
| **14** | Alternative Flatworm Mt | Platelmintos parasitas (*Schistosoma*) | **UAA = Tyr** (não é Stop!); UGA = Trp |
| **16** | Chlorophycean Mt | Algas verdes (*Chlamydomonas*) | **UAG = Leu** (não é Stop!) |
| **21** | Trematode Mt | Trematódeos e fascíolas | UGA = Trp; ATA = Met; AGA/AGG = Ser |
| **22** | Scenedesmus obliquus Mt | Algas verdes *Scenedesmus* | UCA = Stop; UAG = Leu |
| **23** | Thraustochytrium Mt | Protozoários marinhos *Thraustochytrium* | TTA = Stop |
| **24** | Pterobranchia Mt | Hemicordados *Pterobranchia* | AGA = Ser; AGG = Lys |

---

## 2. Tipos de Topologia Mitocondrial por Clado

```sql
CREATE TYPE mitochondrial_topology_type AS ENUM (
    'circular_single',         -- Metazoa padrão (~16.5 kb único anel)
    'circular_multipartite',    -- Plantas com múltiplos subcírculos recombinantes / piolhos
    'linear_tandem',           -- Apicomplexa / Plasmodium (~6 kb repetições em tandem)
    'linear_hairpin',          -- Ciliados (Paramecium, Tetrahymena) com telômeros em grampo
    'kdna_network',            -- Kinetoplastida (Trypanosoma, Leishmania) maxicírculos e minicírculos
    'branching_recombinant'    -- Plantas vasculares (Silene) com formas dinâmicas ramificadas
);
```

---

## 3. Íntrons Catalíticos (Grupo I e II) & Trans-Splicing (Plantas e Fungos)

### 3.1 Tabela `mitointron`
Mapeia íntrons auto-catalíticos de Grupo I e Grupo II encontrados em plantas e fungos:
- Identificação de *Homing Endonucleases* móveis (famílias **LAGLIDADG**, **GIY-YIG**).
- Identificação de maturases codificadas intronicamente.
- Sítios doadores e aceptores de splicing.

### 3.2 Tabela `mitochondrial_trans_splicing_junction`
Resolve o maior desafio de montagem em plantas terrestres: genes como *nad1*, *nad2* e *nad5*, cujos éxons estão localizados em moléculas circulares distintas ou separados por dezenas de kilobases e unidos pós-transcricionalmente por *trans-splicing*.

---

## 4. Redes de kDNA em Kinetoplastídeos (*Trypanosoma* / *Leishmania*)

### 4.1 Tabela `kdna_minicircle_library`
- Associa classes de minicírculos (~1 kb) aos genes criptográficos dos maxicírculos (~20-40 kb).
- Mapeia sequências de *Guide RNAs* (gRNAs) e regiões de ancoragem 5'.
- Quantifica o número de inserções e deleções de Uridinas (U-insertion/U-deletion pan-editing).
