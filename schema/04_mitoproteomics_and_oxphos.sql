-- ============================================================================
-- mitoChado: 04_mitoproteomics_and_oxphos.sql
-- Subunidades OXPHOS (Complexos I a V) e Anotação Funcional de Proteínas
-- ============================================================================

-- 1. Complexos de Fosforilação Oxidativa
CREATE TYPE oxphos_complex AS ENUM (
    'complex_I',   -- NADH:Ubiquinone Oxidoreductase (ND1-6, ND4L)
    'complex_II',  -- Succinate Dehydrogenase (100% nuclear)
    'complex_III', -- Cytochrome bc1 Complex (CYTB)
    'complex_IV',  -- Cytochrome c Oxidase (COX1, COX2, COX3)
    'complex_V',   -- ATP Synthase (ATP6, ATP8)
    'non_oxphos'   -- Outras proteínas mitocondriais
);

-- 2. Tabela de Proteínas Mitocondriais (Mapeamento Funcional)
CREATE TABLE mitoprotein (
    id BIGSERIAL PRIMARY KEY,
    tax_id INT NOT NULL REFERENCES organism(tax_id) ON DELETE CASCADE,
    gene_symbol TEXT NOT NULL,                    -- Ex: 'ND1', 'COX1', 'CYTB'
    uniprot_accession TEXT,                       -- Ex: 'P03886'
    encoded_by TEXT NOT NULL CHECK (encoded_by IN ('mtDNA', 'nuclear')),
    feature_id BIGINT REFERENCES mitofeature(id) ON DELETE CASCADE,
    complex oxphos_complex NOT NULL,
    subcomplex_module TEXT,                       -- Ex: 'N-module', 'Q-module', 'P-module'
    molecular_weight_kda DOUBLE PRECISION,
    isoelectric_point DOUBLE PRECISION,
    amino_acid_sequence TEXT,
    embedding vector(1280),                       -- Embedding vetorial de proteína (ESM-2/AlphaFold)
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX idx_mitoprot_tax_symbol ON mitoprotein (tax_id, gene_symbol);
CREATE INDEX idx_mitoprot_complex ON mitoprotein (complex);
CREATE INDEX idx_mitoprot_origin ON mitoprotein (encoded_by);
CREATE INDEX idx_mitoprot_feat ON mitoprotein (feature_id);
