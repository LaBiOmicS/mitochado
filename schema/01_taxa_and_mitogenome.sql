-- ============================================================================
-- mitoChado: 01_taxa_and_mitogenome.sql
-- Organismos, Códigos Genéticos Mitocondriais e Montagens de Mitogenomas
-- ============================================================================

-- 1. Tabela de Códigos Genéticos Mitocondriais (NCBI Translation Tables)
CREATE TABLE mitochondrial_genetic_code (
    id INT PRIMARY KEY,                           -- Ex: 2 (Vertebrate Mt), 5 (Invertebrate Mt), 9, 14
    name TEXT NOT NULL,                           -- 'Vertebrate Mitochondrial', 'Invertebrate Mitochondrial'
    description TEXT,
    start_codons TEXT[] NOT NULL DEFAULT '{}',    -- Códons de início alternativos (ex: ATA, ATC, GTG, TTG)
    stop_codons TEXT[] NOT NULL DEFAULT '{}'      -- Códons de parada (ex: AGA/AGG stop em vertebrados)
);

-- 2. Organismos e Taxonomia
CREATE TABLE organism (
    tax_id INT PRIMARY KEY,                       -- NCBI TaxID
    scientific_name TEXT NOT NULL,
    common_name TEXT,
    lineage TEXT[] DEFAULT '{}',
    clade TEXT,                                   -- 'Metazoa', 'Fungi', 'Viridiplantae', 'Protista'
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX idx_mito_org_name ON organism(scientific_name);

-- 3. Mitogenomas (Instâncias completas ou montagens de mtDNA)
CREATE TABLE mitogenome (
    id SERIAL PRIMARY KEY,
    tax_id INT NOT NULL REFERENCES organism(tax_id) ON DELETE RESTRICT,
    accession TEXT UNIQUE NOT NULL,               -- Ex: 'NC_012920.1' (rCRS humano), 'NC_001643.1'
    name TEXT NOT NULL,                           -- Ex: 'Homo sapiens revised Cambridge Reference Sequence'
    length INT NOT NULL CHECK (length > 0),       -- Tamanho em pb (~16569 pb em humanos)
    is_circular BOOLEAN NOT NULL DEFAULT TRUE,    -- Circular (padrão metazoário) vs Linear
    genetic_code_id INT NOT NULL REFERENCES mitochondrial_genetic_code(id),
    
    -- Métricas composicionais do mtDNA
    gc_content DOUBLE PRECISION,                  -- % de GC
    at_skew DOUBLE PRECISION,                     -- (A - T) / (A + T)
    gc_skew DOUBLE PRECISION,                     -- (G - C) / (G + C)
    
    -- Topologia e Regiões Críticas de Replicação
    d_loop_coordinates INT8RANGE,                 -- Região de Controle / D-loop [start, end)
    oh_position INT,                              -- Origem de replicação da Fita Pesada (H-strand)
    ol_position INT,                              -- Origem de replicação da Fita Leve (L-strand)
    
    -- Dados de Amostra e Heteroplasmia Média
    sample_id TEXT,
    tissue_or_cell_type TEXT,
    mtdna_copy_number_estimate DOUBLE PRECISION,
    
    is_canonical_reference BOOLEAN NOT NULL DEFAULT FALSE,
    raw_sequence TEXT,                            -- Sequência nucleotídica completa (opcional se compactado)
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);

CREATE INDEX idx_mitogenome_tax_id ON mitogenome(tax_id);
CREATE INDEX idx_mitogenome_accession ON mitogenome(accession);
CREATE INDEX idx_mitogenome_canonical ON mitogenome(is_canonical_reference);
