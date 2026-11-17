# Especificação Formal: mitoChado v0.2 (2026 Edition)

O **mitoChado** é um ecossistema de banco de dados relacional e motor de dados especializado na biologia multi-ômica da mitocôndria.

---

## 1. Por que um Chado Específico para Mitocôndrias?

O Chado tradicional foi projetado para genomas nucleares lineares massivos, ignorando idiossincrasias que definem a biologia mitocondrial:

| Aspecto Biológico | Limitação no Chado Tradicional | Solução Nativa no mitoChado |
| :--- | :--- | :--- |
| **Topologia Circular & Multipartite** | Coordenadas lineares quebram na origem do anel | Colunas `coordinates` + `spans_origin` e suporte a topologias multicírculo (plantas) |
| **Códigos Genéticos Próprios** | Pressupõe o código universal nuclear | Suporte completo às 12+ tabelas de tradução do NCBI (1, 2, 3, 4, 5, 9, 13, 14, 16, 21-24) |
| **Heteroplasmia Contínua** | Força genótipos mendelianos (0/0, 0/1, 1/1) | Fração alélica contínua `heteroplasmy_level` (0.0 a 1.0) com flag automático de homoplasmia |
| **Mitotranscriptômica** | Assume transcritos monocistrônicos clássicos | Precursores policistrônicos (HSP/LSP), clivagem por tRNA punctuation model e RNA editing |
| **Poliadenilação Formadora de Códon** | Ignora terminação formadora de códon | Suporte a códons incompletos (T/TA) completados por poliadenilação |
| **Mitoproteoma Dual** | Não distingue proteínas codificadas no mtDNA vs importadas | Classificação estrita (`mtDNA` vs `nuclear`), complexos OXPHOS (I a V) e sinais MTS |
| **Micropeptídeos (MDPs)** | Ignora ORFs curtos codificados dentro de rRNAs | Entidade `mdp` de 1ª classe para **Humanin**, **MOTS-c** e **SHLP1-6** |
| **Falso-Positivo por NUMTs** | Mapeia sequências nucleares como mtDNA | Tabela `numt_locus` com coordenadas nucleares para filtragem de variantes em NGS |
| **Mito-Epitranscriptômica** | Não modela modificações em tRNAs | Mapeamento de modificações químicas ($\tau m^5 U$, $ms^2 i^6 A$) e enzimas nucleares |
| **Co-evolução Núcleo-Mitocondrial** | Ignora epistasia entre genomas | Pares de contato físico estrutural e montagem de **Respirasomas** |

---

## 2. Dicionário de Módulos e Tabelas

### 2.1 `mitogenome`
- `length`: Tamanho exato em pb (~16.5 kb em metazoários a centenas de kb em plantas).
- `topology`: `circular_single`, `circular_multipartite`, `linear_tandem`, `linear_hairpin`, `kdna_network`, `branching_recombinant`.
- `genetic_code_id`: FK para tabela de tradução do NCBI (1 a 24).
- `at_skew` e `gc_skew`: Assimetria composicional do mtDNA.

### 2.2 `mitofeature`
- Categorias: `pcg` (13 genes), `trna` (22 tRNAs), `rrna` (12S, 16S), `mdp`, `d_loop`.
- `synteny_order`: Posição ordinal no anel circular (1 a 37).
- `trna_anticodon` e `trna_secondary_structure`: Notação Dot-Bracket da estrutura em trevo.

### 2.3 `mitogenome_skew_profile` & `feature_codon_usage`
- Curvas cumulativas de AT/GC-skew com detecção automática do ponto de inflexão das origens de replicação ($O_H$ e $O_L$).
- Métricas CUB: **RSCU**, **CAI** calibrado, **ENC** (Effective Number of Codons) e frações de **pareamento Wobble**.

### 2.4 `numt_locus`
- Segmentos homólogos de mtDNA inseridos no genoma nuclear.
- Coordenadas nucleares (`int8range`), % de identidade de sequência e avaliação de risco de falso-positivo em NGS (`HIGH`, `MEDIUM`, `LOW`).

### 2.5 `mitorna_chemical_modification`
- Catálogo de modificações epitranscriptômicas em tRNAs (posições 34, 37, 55).
- Associação com enzimas nucleares (*MTO1*, *GTPBP3*, *NSUN3*) e patologias por deficiência (MLASA, miopatias).

### 2.6 `mitonuclear_interaction_pair` & `respirasome_supercomplex`
- Interfaces de contato físico entre proteínas do mtDNA e proteínas nucleares.
- Predição de incompatibilidade cito-nuclear em transplantes mitocondriais e MRT.
- Estequiometria de supercomplexos ($I_1 III_2 IV_1$, $III_2 IV_2$) e sítios de ancoragem de **Cardiolipina**.

### 2.7 `mitochondrial_derived_peptide` (MDPs)
- Peptídeos com atividade hormonal circulante: **Humanin**, **MOTS-c**, **SHLP1-6**.
- Receptores celulares acoplados (FPRL1, complexo CNTFR/gp130) e alvos metabólicos (AMPK, Bax).

### 2.8 `cell_free_mtdna_biomarker`
- Fragmentômica de cf-mtDNA plasmático (<100 pb).
- Sinalização imune inata como DAMP via receptores **TLR9** e inflamassomo **NLRP3**.

### 2.9 `dna_barcode_marker`
- Fragmentos canônicos de 658 pb do **COI (Folmer Region)** para o consórcio global BOLD.
- Marcadores de Citocromo b (*Cytb*) para taxonomia e rastreamento de fraudes biológicas.
