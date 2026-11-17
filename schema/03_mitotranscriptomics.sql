-- ============================================================================
-- mitoChado: 03_mitotranscriptomics.sql
-- Mitotranscriptômica: Unidades Policistrônicas, Clivagem de tRNA,
-- RNA Editing, Poliadenilação e Expressão
-- ============================================================================

-- 1. Unidades de Transcrição Policistrônicas (Precursores de Fita Pesada e Leve)
CREATE TABLE mitotranscript_precursor (
    id SERIAL PRIMARY KEY,
    mitogenome_id INT NOT NULL REFERENCES mitogenome(id) ON DELETE CASCADE,
    strand SMALLINT NOT NULL CHECK (strand IN (1, -1)),
    promoter_name TEXT NOT NULL,                  -- 'HSP1', 'HSP2' (Heavy Strand Promoter), 'LSP' (Light)
    start_pos INT NOT NULL,
    end_pos INT NOT NULL,
    description TEXT
);

-- 2. Locais de Clivagem e Processamento de RNA (Modelo de Pontuação por tRNA)
CREATE TABLE mitorna_cleavage_site (
    id BIGSERIAL PRIMARY KEY,
    mitogenome_id INT NOT NULL REFERENCES mitogenome(id) ON DELETE CASCADE,
    flanking_trna_id BIGINT REFERENCES mitofeature(id) ON DELETE CASCADE,
    cleavage_end TEXT NOT NULL CHECK (cleavage_end IN ('5_prime', '3_prime')),
    enzyme TEXT,                                  -- Ex: 'RNase P (mitocondrial)', 'ELAC2 (RNase Z)'
    exact_position INT NOT NULL,                  -- Posição exata do corte nucleotídico
    cleavage_efficiency DOUBLE PRECISION          -- Eficiência/fração de clivagem observada
);

-- 3. Eventos de Edição de RNA Mitocondrial (RNA Editing)
-- Comum em plantas (C->U), metazoários e tripanosomatídeos
CREATE TABLE mitorna_editing (
    id BIGSERIAL PRIMARY KEY,
    mitogenome_id INT NOT NULL REFERENCES mitogenome(id) ON DELETE CASCADE,
    feature_id BIGINT REFERENCES mitofeature(id) ON DELETE CASCADE,
    position INT NOT NULL,                        -- Posição no mtDNA
    ref_base CHAR(1) NOT NULL,                    -- Ex: 'C'
    edited_base CHAR(1) NOT NULL,                 -- Ex: 'U' (ou 'I' em A->I)
    editing_type TEXT NOT NULL,                   -- 'C_to_U', 'U_to_C', 'A_to_I', 'U_insertion'
    editing_frequency DOUBLE PRECISION,           -- Frequência/proporção observada (0.0 a 1.0)
    functional_impact TEXT,                       -- Ex: 'Creates AUG start codon', 'Amino acid substitution (Ser->Phe)'
    sample_condition TEXT,                        -- Condição / tecido
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX idx_mitorna_editing_pos ON mitorna_editing (mitogenome_id, position);

-- 4. RNAs Não-Codificadores Mitocondriais (lncRNAs, circRNAs, mitosRNAs)
CREATE TABLE mitornas_regulatory (
    id BIGSERIAL PRIMARY KEY,
    mitogenome_id INT NOT NULL REFERENCES mitogenome(id) ON DELETE CASCADE,
    rna_type TEXT NOT NULL,                       -- 'lncRNA_mitochondrial', 'circRNA_mecciRNA', 'mitosRNA'
    identifier TEXT NOT NULL,                     -- Ex: 'ASncmtRNA-1', 'mecciND1'
    coordinates INT8RANGE NOT NULL,
    strand SMALLINT NOT NULL CHECK (strand IN (1, -1)),
    is_circular BOOLEAN NOT NULL DEFAULT FALSE,
    host_gene_id BIGINT REFERENCES mitofeature(id),
    functional_role TEXT                          -- Ex: 'Retrograde nuclear signaling', 'Apoptosis regulation'
);

-- 5. Quantificação de Expressão Mitotranscriptômica
CREATE TABLE mitotranscript_expression (
    id BIGSERIAL PRIMARY KEY,
    feature_id BIGINT NOT NULL REFERENCES mitofeature(id) ON DELETE CASCADE,
    sample_id TEXT NOT NULL,
    condition TEXT,                               -- Ex: 'Control', 'Metabolic_Stress', 'Aging'
    tpm DOUBLE PRECISION NOT NULL,                -- Transcripts Per Million
    raw_counts DOUBLE PRECISION,
    coverage_depth DOUBLE PRECISION,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    CONSTRAINT uq_mitotranscript_sample UNIQUE (feature_id, sample_id)
);

CREATE INDEX idx_mito_exp_sample ON mitotranscript_expression (sample_id);
