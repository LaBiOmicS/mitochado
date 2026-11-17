-- ============================================================================
-- mitoChado: 02_features_and_genes.sql
-- Anotações Mitogenômicas: 13 PCGs, 22 tRNAs, 2 rRNAs, MDPs (Humanin) e D-Loop
-- ============================================================================

-- 1. Tipos de Elementos Mitocondriais
CREATE TYPE mitofeature_category AS ENUM (
    'pcg',               -- Protein Coding Gene (ND1-6, COX1-3, CYTB, ATP6/8)
    'trna',              -- Transfer RNA (22 tRNAs canônicos)
    'rrna',              -- Ribosomal RNA (12S / 16S)
    'mdp',               -- Mitochondrial-Derived Peptide (Humanin, MOTS-c, SHLPs)
    'd_loop',            -- Região de Controle / Non-Coding Region (NCR)
    'origin_rep',        -- Origem de Replicação (OH ou OL)
    'intergenic_spacer', -- Espaçador intergênico
    'numt'               -- Segmento mitocondrial inserido no genoma nuclear
);

-- 2. Tabela de Features Mitocondriais
CREATE TABLE mitofeature (
    id BIGSERIAL PRIMARY KEY,
    mitogenome_id INT NOT NULL REFERENCES mitogenome(id) ON DELETE CASCADE,
    category mitofeature_category NOT NULL,
    gene_symbol TEXT NOT NULL,                    -- Ex: 'COX1', 'ND4', 'trnL1', 'rrnS', 'Humanin'
    standard_name TEXT,                           -- Nome canônico HUGO / MitoZ / MITOS
    
    -- Coordenadas 0-based half-open no mtDNA
    coordinates INT8RANGE NOT NULL,               -- [start, end)
    spans_origin BOOLEAN NOT NULL DEFAULT FALSE,  -- True se a feature atravessa a origem circular (ex: 16500 -> 50)
    secondary_coordinates INT8RANGE,              -- Segunda porção caso atravesse a origem circular
    strand SMALLINT NOT NULL CHECK (strand IN (1, -1)), -- 1 = Heavy Strand (H), -1 = Light Strand (L)
    
    -- Ordem gênica no genoma (Sintenia mitocondrial)
    synteny_order INT,                            -- 1 a 37 na ordem circular
    
    -- Estrutura de Leitura e Códons para PCGs
    start_codon TEXT,                             -- Códon de início real (ex: 'ATG', 'ATA', 'GTG')
    stop_codon TEXT,                              -- Códon de parada (ex: 'TAA', 'TAG', 'AGA', ou 'T--' incompleto)
    is_stop_codon_incomplete BOOLEAN NOT NULL DEFAULT FALSE, -- True se finalizado por poliadenilação (ex: T ou TA)
    
    -- Atributos de tRNAs
    trna_amino_acid CHAR(1),                      -- 'L', 'S', 'M', etc.
    trna_anticodon VARCHAR(3),                    -- Ex: 'TAA', 'GAA'
    trna_secondary_structure TEXT,                -- Notação Dot-Bracket da estrutura em trevo (cloverleaf)
    
    -- Sequências de Nucleotídeos e Aminoácidos
    nucleotide_sequence TEXT,
    protein_sequence TEXT,
    
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);

-- Índices Espaciais e de Busca
CREATE INDEX idx_mitofeat_coords ON mitofeature USING gist (mitogenome_id, coordinates);
CREATE INDEX idx_mitofeat_symbol ON mitofeature (mitogenome_id, gene_symbol);
CREATE INDEX idx_mitofeat_category ON mitofeature (category);
CREATE INDEX idx_mitofeat_strand ON mitofeature (strand);
CREATE INDEX idx_mitofeat_order ON mitofeature (mitogenome_id, synteny_order);
