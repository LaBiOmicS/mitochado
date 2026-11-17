-- ============================================================================
-- mitoChado: 04_mitoproteomics_and_oxphos.sql
-- Mitoproteômica: Complexos OXPHOS (I-V), Origem Dual (mtDNA vs Nuclear),
-- Sinais de Endereçamento (MTS) e PTMs
-- ============================================================================

-- 1. Complexos de Fosforilação Oxidativa e Vias Mitocondriais
CREATE TYPE oxphos_complex AS ENUM (
    'complex_I',   -- NADH:Ubiquinone Oxidoreductase
    'complex_II',  -- Succinate Dehydrogenase (100% nuclear)
    'complex_III', -- Cytochrome bc1 Complex
    'complex_IV',  -- Cytochrome c Oxidase (COX)
    'complex_V',   -- ATP Synthase
    'non_oxphos'   -- TCA cycle, beta-oxidation, mitoribosome, import machinery
);

-- 2. Tabela de Proteínas Mitocondriais (Origem Dual: mtDNA + Nuclear)
CREATE TABLE mitoprotein (
    id BIGSERIAL PRIMARY KEY,
    tax_id INT NOT NULL REFERENCES organism(tax_id) ON DELETE CASCADE,
    gene_symbol TEXT NOT NULL,                    -- Ex: 'ND1', 'COX1', 'NDUFS1', 'SDHA'
    uniprot_accession TEXT,                       -- Ex: 'P03886'
    encoded_by TEXT NOT NULL CHECK (encoded_by IN ('mtDNA', 'nuclear')),
    feature_id BIGINT REFERENCES mitofeature(id), -- Aponta para mitofeature se for mtDNA
    complex oxphos_complex NOT NULL,
    subcomplex_module TEXT,                       -- Ex: 'N-module', 'Q-module', 'P-module' (Complex I)
    
    -- Sinal de Endereçamento Mitocondrial (MTS) para proteínas nucleares
    has_mitochondrial_targeting_signal BOOLEAN DEFAULT FALSE,
    mts_cleavage_site INT,                        -- Posição do corte pela MPP (Mitochondrial Processing Peptidase)
    submitochondrial_localization TEXT,           -- 'Matrix', 'Inner Membrane (IMM)', 'Intermembrane Space (IMS)', 'Outer Membrane (OMM)'
    
    molecular_weight_kda DOUBLE PRECISION,
    isoelectric_point DOUBLE PRECISION,
    amino_acid_sequence TEXT NOT NULL,
    
    -- Embeddings de IA para estrutura e afinidade de ligantes/subunidades
    embedding vector(1280),
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX idx_mitoprot_tax_symbol ON mitoprotein (tax_id, gene_symbol);
CREATE INDEX idx_mitoprot_complex ON mitoprotein (complex);
CREATE INDEX idx_mitoprot_origin ON mitoprotein (encoded_by);
CREATE INDEX idx_mitoprot_embedding_hnsw ON mitoprotein USING hnsw (embedding vector_cosine_ops);

-- 3. Modificações Pós-Traducionais Mitocondriais (PTMs)
-- Regulação por Sirtuínas mitocondriais (SIRT3/4/5) e oxidação por ROS
CREATE TABLE mitoprotein_ptm (
    id BIGSERIAL PRIMARY KEY,
    mitoprotein_id BIGINT NOT NULL REFERENCES mitoprotein(id) ON DELETE CASCADE,
    residue_position INT NOT NULL,                -- Ex: Lysine 42
    amino_acid CHAR(1) NOT NULL,                  -- 'K', 'S', 'T', 'C', 'M'
    ptm_type TEXT NOT NULL,                       -- 'Acetylation', 'Succinylation', 'Malonylation', 'Phosphorylation', 'Oxidation'
    regulatory_enzyme TEXT,                       -- Ex: 'SIRT3', 'PKA-mt'
    functional_effect TEXT,                       -- Ex: 'Inactivates enzyme', 'Stimulates ATP production'
    evidence_pmid TEXT
);

CREATE INDEX idx_mitoprot_ptm_lookup ON mitoprotein_ptm (mitoprotein_id, residue_position);
