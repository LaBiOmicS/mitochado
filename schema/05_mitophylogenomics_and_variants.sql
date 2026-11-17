-- ============================================================================
-- mitoChado: 05_mitophylogenomics_and_variants.sql
-- Mitofilogenômica: Haplogrupos, Heteroplasmia, Rearranjos de Ordem Gênica
-- e Matrizes de Superalinhamento
-- ============================================================================

-- 1. Haplogrupos Mitocondriais (PhyloTree / HaploGrep)
CREATE TABLE mitochondrial_haplogroup (
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,                    -- Ex: 'L0', 'L3', 'H', 'H1', 'U5b', 'M'
    parent_haplogroup TEXT REFERENCES mitochondrial_haplogroup(name),
    clade TEXT NOT NULL,                          -- 'Human', 'Canis', 'Bovine', etc.
    defining_mutations TEXT[] NOT NULL DEFAULT '{}', -- Ex: ['m.263A>G', 'm.315.1insC', 'm.16519T>C']
    geographic_origin TEXT,
    description TEXT
);

CREATE INDEX idx_mitohaplo_name ON mitochondrial_haplogroup(name);

-- 2. Variantes Mitocondriais e Heteroplasmia (Clínica e Populacional)
CREATE TABLE mitochondrial_variant (
    id BIGSERIAL PRIMARY KEY,
    mitogenome_id INT NOT NULL REFERENCES mitogenome(id) ON DELETE CASCADE,
    position INT NOT NULL,                        -- Posição 1-based (ex: 3243 para m.3243A>G)
    ref_allele TEXT NOT NULL,                     -- Ex: 'A'
    alt_allele TEXT NOT NULL,                     -- Ex: 'G'
    
    -- Heteroplasmia (Fração Alélica na amostra: 0.00 a 1.00)
    heteroplasmy_level DOUBLE PRECISION NOT NULL CHECK (heteroplasmy_level >= 0.0 AND heteroplasmy_level <= 1.0),
    read_depth INT,                               -- Cobertura de sequenciamento no locus
    alt_depth INT,                                -- Contagem de reads da variante
    
    -- Efeito e Patogenicidade (MITOMAP / ClinVar)
    feature_id BIGINT REFERENCES mitofeature(id),
    hgvs_nomenclature TEXT,                       -- Ex: 'm.3243A>G'
    clinical_significance TEXT,                   -- 'Pathogenic' (ex: MELAS), 'Benign', 'VUS'
    associated_disease TEXT,                      -- Ex: 'MELAS', 'MERRF', 'LHON', 'Leigh Syndrome'
    is_homoplasmic BOOLEAN GENERATED ALWAYS AS (heteroplasmy_level >= 0.99) STORED,
    
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX idx_mitovar_pos ON mitochondrial_variant (mitogenome_id, position);
CREATE INDEX idx_mitovar_pathogenic ON mitochondrial_variant (clinical_significance);

-- 3. Rearranjos de Ordem Gênica (Gene Order Synteny)
-- Marcador filogenômico profundo em metazoários
CREATE TABLE mitogenome_gene_order (
    id BIGSERIAL PRIMARY KEY,
    mitogenome_id INT NOT NULL REFERENCES mitogenome(id) ON DELETE CASCADE,
    gene_order_string TEXT NOT NULL,              -- Representação serializada da ordem gênica (ex: '+cox1,+trnL1,+cox2,+trnK...')
    rearrangement_class TEXT,                     -- 'Ancestral_Coelomata', 'Ancestral_Arthropod', 'Vertebrate_Canonical'
    breakpoint_distance_to_ancestral INT,         -- Distância de quebra em relação ao ancestral do clado
    inversion_count INT,
    transposition_count INT
);

CREATE INDEX idx_mitosynteny_class ON mitogenome_gene_order (rearrangement_class);

-- 4. Partições de Matrizes Filogenômicas (13 PCGs + 2 rRNAs)
CREATE TABLE mitophylogenomic_dataset (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,                           -- Ex: 'Mammalia_13PCG_2rRNA_Supermatrix'
    description TEXT,
    included_features TEXT[] NOT NULL DEFAULT '{"ND1","ND2","ND3","ND4","ND4L","ND5","ND6","CYTB","COX1","COX2","COX3","ATP6","ATP8","12S","16S"}',
    matrix_format TEXT NOT NULL DEFAULT 'PHYLIP', -- 'FASTA', 'PHYLIP', 'NEXUS'
    alignment_storage_path TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);
