-- ============================================================================
-- mitoChado: 08_composition_skews_and_cub.sql
-- Assimetria de Fita (AT/GC Skew), Ponto de Inflexão (Origens OH/OL)
-- e Viés de Uso de Códons (RSCU, CAI, ENC, GC3)
-- ============================================================================

-- 1. Perfil de Assimetria de Fita e Curvas Cumulativas de Skew
-- O ponto de inflexão de skew prediz computacionalmente a origem de replicação
CREATE TABLE mitogenome_skew_profile (
    id BIGSERIAL PRIMARY KEY,
    mitogenome_id INT NOT NULL REFERENCES mitogenome(id) ON DELETE CASCADE,
    window_size INT NOT NULL DEFAULT 500,         -- Tamanho da janela deslizante (ex: 500 pb)
    step_size INT NOT NULL DEFAULT 50,            -- Salto da janela
    
    -- Pontos de Inflexão Preditos para Replicação
    predicted_oh_position INT,                    -- Origem de Fita Pesada inferida por inversão de GC-skew
    predicted_ol_position INT,                    -- Origem de Fita Leve inferida
    
    -- Vetor de valores de skew ao longo do anel (JSONB ou arrays)
    cumulative_gc_skew DOUBLE PRECISION[] DEFAULT '{}',
    cumulative_at_skew DOUBLE PRECISION[] DEFAULT '{}',
    
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uq_mitogenome_skew_window UNIQUE (mitogenome_id, window_size, step_size)
);

CREATE INDEX idx_mito_skew_profile ON mitogenome_skew_profile (mitogenome_id);

-- 2. Viés de Uso de Códons por Gene Mitocondrial (CUB - Codon Usage Bias)
CREATE TABLE feature_codon_usage (
    id BIGSERIAL PRIMARY KEY,
    feature_id BIGINT NOT NULL REFERENCES mitofeature(id) ON DELETE CASCADE,
    
    -- Métricas Globais de Viés
    cai DOUBLE PRECISION,                         -- Codon Adaptation Index (adaptabilidade ao pool de tRNAs)
    enc DOUBLE PRECISION,                         -- Effective Number of Codons (20 = extremo, 61 = nulo)
    gc3_percentage DOUBLE PRECISION,              -- % de GC na 3ª posição silenciosa do códon
    at3_percentage DOUBLE PRECISION,              -- % de AT na 3ª posição silenciosa
    
    -- Tabelas de Frequência e Preferência de Códons (RSCU)
    -- Formato JSON: {"ATG": 1.45, "ATA": 0.55, ...}
    rscu_profile JSONB NOT NULL DEFAULT '{}'::jsonb,
    codon_counts JSONB NOT NULL DEFAULT '{}'::jsonb,
    
    -- Pareamento Wobble e Adaptação
    wobble_pairing_fraction DOUBLE PRECISION,     -- Fração de códons dependentes de pareamento não-Watson-Crick
    superwobbling_observed BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uq_feature_codon_usage UNIQUE (feature_id)
);

CREATE INDEX idx_feat_cub_feature ON feature_codon_usage (feature_id);
CREATE INDEX idx_feat_cub_enc ON feature_codon_usage (enc);
