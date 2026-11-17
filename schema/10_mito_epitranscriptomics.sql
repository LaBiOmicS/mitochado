-- ============================================================================
-- mitoChado: 10_mito_epitranscriptomics.sql
-- Mito-Epitranscriptômica: Modificações Químicas Pós-Transcricionais
-- em tRNAs e rRNAs Mitocondriais e Enzimas Modificadoras Nucleares
-- ============================================================================

CREATE TYPE mitorna_modification_type AS ENUM (
    'tau_m5_u',             -- 5-taurinomethyluridine (chave para wobble em tRNA-Leu/Trp)
    'tau_m5_s2_u',          -- 5-taurinomethyl-2-thiouridine (tRNA-Gln, Lys, Glu)
    'ms2_i6_a',             -- 2-methylthio-N6-isopentenyladenosine
    'pseudouridine',        -- Pseudouridina (Psi) no T-loop
    'dihydrouridine',       -- Di-hidrouridina no D-loop
    'm1A',                  -- 1-methyladenosine
    'm1G',                  -- 1-methylguanosine
    'm5C',                  -- 5-methylcytosine
    'queuosine'             -- Queuosina
);

CREATE TABLE mitorna_chemical_modification (
    id BIGSERIAL PRIMARY KEY,
    feature_id BIGINT NOT NULL REFERENCES mitofeature(id) ON DELETE CASCADE,
    residue_position INT NOT NULL,                -- Posição canônica do tRNA/rRNA (ex: 34 para wobble, 37, 55)
    unmodified_base CHAR(1) NOT NULL,             -- 'U', 'A', 'C', 'G'
    modification_type mitorna_modification_type NOT NULL,
    
    -- Enzimas Nucleares Responsáveis pela Catálise
    nuclear_modifying_enzyme TEXT NOT NULL,       -- Ex: 'MTO1', 'GTPBP3', 'TRMT10C', 'NSUN3', 'TFB1M'
    uniprot_enzyme_id TEXT,                       -- Ex: 'Q96MT3'
    
    -- Papel Fisiológico e Patologia por Deficiência de Modificação
    biological_function TEXT,                     -- Ex: 'Decodes UUG/UUA with high fidelity, prevents translational stalling'
    pathology_on_deficiency TEXT,                 -- Ex: 'Mitochondrial Myopathy and Sideroblastic Anemia (MLASA)', 'Hypertrophic Cardiomyopathy'
    omim_id TEXT,                                 -- Ex: '614702'
    
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uq_mitorna_mod UNIQUE (feature_id, residue_position, modification_type)
);

CREATE INDEX idx_mitomod_feature ON mitorna_chemical_modification (feature_id);
CREATE INDEX idx_mitomod_enzyme ON mitorna_chemical_modification (nuclear_modifying_enzyme);
CREATE INDEX idx_mitomod_type ON mitorna_chemical_modification (modification_type);
