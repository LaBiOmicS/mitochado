-- ============================================================================
-- mitoChado: 09_numts_and_false_positive_filter.sql
-- NUMTs (Nuclear-Mitochondrial Segments) e Filtro de Falso-Positivos em NGS
-- ============================================================================

CREATE TABLE numt_locus (
    id BIGSERIAL PRIMARY KEY,
    tax_id INT NOT NULL REFERENCES organism(tax_id) ON DELETE CASCADE,
    
    -- Localização no Genoma Nuclear
    nuclear_chromosome TEXT NOT NULL,             -- Ex: 'chr1', 'chrX'
    nuclear_coordinates INT8RANGE NOT NULL,       -- [start, end) no cromossomo nuclear
    nuclear_strand SMALLINT NOT NULL CHECK (nuclear_strand IN (1, -1)),
    
    -- Segmento Mitocondrial de Origem
    source_mitogenome_id INT NOT NULL REFERENCES mitogenome(id) ON DELETE CASCADE,
    mito_homologous_coordinates INT8RANGE NOT NULL, -- Coordenadas homólogas no mtDNA
    spanned_mitogenes TEXT[] DEFAULT '{}',        -- Ex: ARRAY['ND1', 'trnI', 'ND2']
    
    -- Métricas de Divergência Evolutiva
    sequence_identity_percentage DOUBLE PRECISION NOT NULL, -- % de identidade BLAST
    alignment_length_bp INT NOT NULL,
    divergence_mya DOUBLE PRECISION,              -- Idade estimada da inserção (milhões de anos)
    blast_evalue DOUBLE PRECISION,
    
    -- Status Populacional e Risco Clínico
    is_insertion_polymorphic BOOLEAN DEFAULT FALSE, -- True se varia entre indivíduos da espécie
    ngs_false_positive_risk TEXT NOT NULL DEFAULT 'HIGH', -- 'HIGH', 'MEDIUM', 'LOW'
    
    sequence TEXT,                                -- Sequência nucleotídica do NUMT
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);

-- Índices Espaciais
CREATE INDEX idx_numt_nuclear_coords ON numt_locus USING gist (nuclear_chromosome, nuclear_coordinates);
CREATE INDEX idx_numt_mito_coords ON numt_locus USING gist (source_mitogenome_id, mito_homologous_coordinates);
CREATE INDEX idx_numt_tax_id ON numt_locus (tax_id);
