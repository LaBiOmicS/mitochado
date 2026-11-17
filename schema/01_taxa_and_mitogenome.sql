-- ============================================================================
-- mitoChado: 01_taxa_and_mitogenome.sql
-- Organismos, Códigos Genéticos Mitocondriais e Montagens de Mitogenomas
-- ============================================================================

-- 1. Tabela de Códigos Genéticos Mitocondriais (NCBI Translation Tables)
CREATE TABLE mitochondrial_genetic_code (
    id INT PRIMARY KEY,                           -- Ex: 1 (Plantas), 2 (Vertebrados), 3 (Leveduras), 4 (Fungos), 5 (Invertebrados)
    name TEXT NOT NULL,                           -- Nome oficial do código NCBI
    description TEXT,
    start_codons TEXT[] NOT NULL DEFAULT '{}',    -- Códons de início alternativos
    stop_codons TEXT[] NOT NULL DEFAULT '{}'      -- Códons de parada
);

-- 2. Topologias Estruturais de Mitogenomas na Árvore da Vida
CREATE TYPE mitochondrial_topology_type AS ENUM (
    'circular_single',         -- Metazoa padrão (~16.5 kb único anel)
    'circular_multipartite',    -- Plantas com múltiplos subcírculos recombinantes / piolhos
    'linear_tandem',           -- Apicomplexa / Plasmodium (~6 kb repetições em tandem)
    'linear_hairpin',          -- Ciliados (Paramecium, Tetrahymena) com telômeros em grampo
    'kdna_network',            -- Kinetoplastida (Trypanosoma, Leishmania) maxicírculos e minicírculos
    'branching_recombinant'    -- Plantas vasculares (Silene) com formas dinâmicas ramificadas
);

-- 3. Organismos e Taxonomia
CREATE TABLE organism (
    tax_id INT PRIMARY KEY,                       -- NCBI TaxID
    scientific_name TEXT NOT NULL,
    common_name TEXT,
    lineage TEXT[] DEFAULT '{}',
    clade TEXT NOT NULL DEFAULT 'Metazoa',        -- 'Metazoa', 'Viridiplantae', 'Fungi', 'Alveolata', 'Euglenozoa'
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX idx_mito_org_name ON organism(scientific_name);
CREATE INDEX idx_mito_org_clade ON organism(clade);

-- 4. Mitogenomas (Instâncias completas ou montagens de mtDNA)
CREATE TABLE mitogenome (
    id SERIAL PRIMARY KEY,
    tax_id INT NOT NULL REFERENCES organism(tax_id) ON DELETE RESTRICT,
    accession TEXT UNIQUE NOT NULL,               -- Ex: 'NC_012920.1' (humano), 'NC_001284.2' (Arabidopsis)
    name TEXT NOT NULL,                           -- Nome ou descrição da montagem
    length INT NOT NULL CHECK (length > 0),       -- Tamanho em pb (16.5 kb em humanos até 367 kb em Arabidopsis)
    topology mitochondrial_topology_type NOT NULL DEFAULT 'circular_single',
    is_circular BOOLEAN GENERATED ALWAYS AS (topology IN ('circular_single', 'circular_multipartite')) STORED,
    genetic_code_id INT NOT NULL REFERENCES mitochondrial_genetic_code(id),
    
    -- Métricas composicionais do mtDNA
    gc_content DOUBLE PRECISION,                  -- % de GC
    at_skew DOUBLE PRECISION,                     -- (A - T) / (A + T)
    gc_skew DOUBLE PRECISION,                     -- (G - C) / (G + C)
    
    -- Topologia e Regiões Críticas de Replicação (quando aplicável)
    d_loop_coordinates INT8RANGE,                 -- Região de Controle / D-loop [start, end)
    oh_position INT,                              -- Origem de replicação da Fita Pesada (H-strand)
    ol_position INT,                              -- Origem de replicação da Fita Leve (L-strand)
    
    -- Subgenoma / Círculo componente (para plantas e kDNA)
    subgenome_identifier TEXT,                    -- Ex: 'Master_Circle', 'Subcircle_A', 'Maxicircle'
    
    -- Dados de Amostra e Heteroplasmia Média
    sample_id TEXT,
    tissue_or_cell_type TEXT,
    mtdna_copy_number_estimate DOUBLE PRECISION,
    
    is_canonical_reference BOOLEAN NOT NULL DEFAULT FALSE,
    raw_sequence TEXT,                            -- Sequência nucleotídica completa
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);

CREATE INDEX idx_mitogenome_tax_id ON mitogenome(tax_id);
CREATE INDEX idx_mitogenome_accession ON mitogenome(accession);
CREATE INDEX idx_mitogenome_topology ON mitogenome(topology);
CREATE INDEX idx_mitogenome_canonical ON mitogenome(is_canonical_reference);
