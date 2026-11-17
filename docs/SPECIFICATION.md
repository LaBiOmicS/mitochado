# Especificação Formal: mitoChado v0.1 (2026 Edition)

O **mitoChado** é um ecossistema de banco de dados relacional e motor de dados especializado na biologia multi-ômica da mitocôndria.

---

## 1. Por que um Chado Específico para Mitocôndrias?

O Chado tradicional foi projetado para genomas nucleares lineares massivos, ignorando idiossincrasias que definem a biologia mitocondrial:

| Aspecto Biológico | Limitação no Chado Tradicional | Solução Nativa no mitoChado |
| :--- | :--- | :--- |
| **Topologia Circular** | Coordenadas lineares quebram se uma anotação atravessa o início do anel circular (D-loop) | Colunas `coordinates` + `spans_origin` e `secondary_coordinates` nativas |
| **Código Genético** | Pressupõe o código padrão universal (Tabela 1) | Suporte a tabelas NCBI específicas (2: Vertebrados, 5: Invertebrados...) com códons de início/fim reais |
| **Heteroplasmia** | Modela genótipos nucleares mendelianos (0/0, 0/1, 1/1) | Fração alélica contínua `heteroplasmy_level` (0.0 a 1.0) com flag automático de homoplasmia |
| **Mitotranscriptômica** | Pressupõe promotores e transcritos monocistrônicos clássicos | Unidades policistrônicas (HSP1/2, LSP), clivagem por tRNA punctuation model e edição de RNA |
| **Poliadenilação** | Ignora terminação formadora de códon | Suporte a códons incompletos (T ou TA) completados por poliadenilação |
| **Mitoproteoma Dual** | Não distingue proteínas codificadas no mtDNA vs importadas | Classificação estrita (`mtDNA` vs `nuclear`), complexos OXPHOS (I a V) e sinais MTS |
| **Micropeptídeos (MDPs)**| Ignora ORFs curtos codificados dentro de rRNAs | Entidade `mdp` de 1ª classe para **Humanin**, MOTS-c e SHLPs |
| **Filogenômica & Sintenia**| Não modela ordem circular de 37 genes | String de sintenia serializada e cálculo de quebras (*breakpoint distance*) |

---

## 2. Entidades Principais

### 2.1 `mitogenome`
Representa uma montagem completa ou parcial de mtDNA:
- `length`: Tamanho exato em pb (~16.5 kb em metazoários).
- `is_circular`: Topologia.
- `genetic_code_id`: FK para tabela de tradução do NCBI.
- `d_loop_coordinates`: Intervalo da região de controle não-codificante.
- `at_skew` e `gc_skew`: Assimetria composicional típica da replicação assimétrica do mtDNA.

### 2.2 `mitofeature`
Anotações dos 37 genes canônicos e elementos funcionais:
- Categorias: `pcg` (13 genes), `trna` (22 tRNAs), `rrna` (12S, 16S), `mdp` (Humanin, MOTS-c), `d_loop`.
- `synteny_order`: Posição ordinal no anel circular (1 a 37).
- `trna_anticodon` e `trna_secondary_structure`: Trevo mitocondrial.

### 2.3 `mitoprotein`
Origem dual da cadeia respiratória:
- `encoded_by`: `mtDNA` (13 proteínas) vs `nuclear` (~1500 proteínas).
- `complex`: `complex_I`, `complex_II`, `complex_III`, `complex_IV`, `complex_V`, `non_oxphos`.
- `has_mitochondrial_targeting_signal` e local submitocondrial (Matriz, Cristas, Membrana Interna, Espaço Intermembranas, Membrana Externa).
- `embedding`: Vetor de 1280 dimensões com índice **HNSW** para busca de homologia estrutural com IA.

### 2.4 `mitochondrial_variant`
- Rastreamento clínico de mutações e heteroplasmia (ex: `m.3243A>G`, `m.8344A>G`).
- `heteroplasmy_level`: Fração de 0.00 a 1.00.
- `is_homoplasmic`: Coluna gerada automaticamente (`>= 0.99`).
- `clinical_significance`: 'Pathogenic', 'Benign', 'VUS'.
