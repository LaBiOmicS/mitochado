-- ============================================================================
-- mitoChado: 12_mdps_circrnas_and_cfmtdna.sql
-- Catálogo Completo de MDPs (Humanin, MOTS-c, SHLP1-6),
-- cf-mtDNA (DAMPs) e DNA Barcoding Ecológico (BOLD Folmer)
-- ============================================================================

-- 1. Peptídeos Derivados de Mitocôndria (Mitochondrial-Derived Peptides - MDPs)
CREATE TABLE mitochondrial_derived_peptide (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,                           -- Ex: 'Humanin', 'MOTS-c', 'SHLP2', 'SHLP3'
    host_rna_feature_id BIGINT REFERENCES mitofeature(id) ON DELETE CASCADE,
    amino_acid_sequence TEXT NOT NULL,
    peptide_length INT NOT NULL,                  -- Ex: 24 aa para Humanin, 16 aa para MOTS-c
    molecular_weight_da DOUBLE PRECISION,
    
    -- Mecanismo de Ação e Receptores Celulares
    cell_surface_receptor TEXT,                   -- Ex: 'FPRL1 (FPR2)', 'CNTFR/WSX-1/gp130 complex'
    intracellular_binding_partner TEXT,           -- Ex: 'Bax', 'Bid', 'IGFBP3'
    primary_biological_function TEXT NOT NULL,    -- Ex: 'Neuroprotection, suppresses Bax translocation, anti-apoptotic'
    metabolic_role TEXT,                          -- Ex: 'Enhances insulin sensitivity via AMPK activation'
    
    is_circulating_hormone BOOLEAN NOT NULL DEFAULT TRUE,
    plasma_half_life_minutes DOUBLE PRECISION,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);

CREATE INDEX idx_mdp_name ON mitochondrial_derived_peptide (name);
CREATE INDEX idx_mdp_host ON mitochondrial_derived_peptide (host_rna_feature_id);

-- 2. cf-mtDNA (DNA Mitocondrial Circulante Livre de Células - DAMP & Inflamação)
CREATE TABLE cell_free_mtdna_biomarker (
    id BIGSERIAL PRIMARY KEY,
    sample_id TEXT NOT NULL,
    clinical_cohort TEXT,                         -- Ex: 'Healthy_Aging', 'Septic_Shock', 'Heart_Failure', 'Metastatic_CRC'
    
    -- Quantificação e Fragmentômica
    plasma_concentration_copies_per_ul DOUBLE PRECISION NOT NULL,
    mean_fragment_size_bp INT,                    -- Perfil de tamanho (geralmente < 100 pb em cf-mtDNA)
    unmethylated_cpg_ratio DOUBLE PRECISION,      -- Relação de CpGs hipometilados
    
    -- Ativação Inflamatória Imune Inata
    activates_tlr9 BOOLEAN NOT NULL DEFAULT TRUE, -- Toll-like receptor 9
    activates_nlrp3_inflammasome BOOLEAN NOT NULL DEFAULT TRUE,
    serum_il6_pg_ml DOUBLE PRECISION,
    
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);

CREATE INDEX idx_cfmtdna_cohort ON cell_free_mtdna_biomarker (clinical_cohort);

-- 3. Marcadores Padronizados de DNA Barcoding (BOLD e Citocromo b)
CREATE TABLE dna_barcode_marker (
    id SERIAL PRIMARY KEY,
    mitogenome_id INT NOT NULL REFERENCES mitogenome(id) ON DELETE CASCADE,
    feature_id BIGINT NOT NULL REFERENCES mitofeature(id) ON DELETE CASCADE,
    marker_name TEXT NOT NULL,                    -- 'BOLD_Folmer_658bp', 'Cytb_Vertebrate_Barcode', '16S_Marine_Barcode'
    coordinates INT8RANGE NOT NULL,               -- Região do fragmento no mtDNA
    forward_primer TEXT,                          -- Ex: 'GGTCAACAAATCATAAAGATATTGG' (LCO1490)
    reverse_primer TEXT,                          -- Ex: 'TAAACTTCAGGGTGACCAAAAAATCA' (HCO2198)
    barcode_sequence TEXT NOT NULL,
    bold_process_id TEXT,                         -- Identificador BOLD Systems
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX idx_barcode_marker ON dna_barcode_marker (marker_name);
CREATE INDEX idx_barcode_mito ON dna_barcode_marker (mitogenome_id);

-- 4. Seed de Peptídeos Mitocondriais Canônicos (Humanin, MOTS-c, SHLP2, SHLP3)
INSERT INTO mitochondrial_derived_peptide (name, amino_acid_sequence, peptide_length, cell_surface_receptor, primary_biological_function, metabolic_role)
VALUES 
    ('Humanin', 'MAPRGFSCLLLLTSEIDLPVKRRA', 24, 'FPRL1 (FPR2) / CNTFR-WSX1-gp130', 
     'Neuroprotective, cytoprotective against Alzheimer amyloid beta, binds and sequesters Bax to inhibit apoptosis', 
     'Improves insulin sensitivity, suppresses atherosclerosis and endothelial dysfunction'),
    
    ('MOTS-c', 'MRWQEMGYIFYPRKLR', 16, 'Target: Folate-methionine cycle and AICAR analog', 
     'Mitochondrial exercise-mimetic, promotes metabolic homeostasis, suppresses diet-induced obesity', 
     'Activates AMPK, enhances glucose disposal in skeletal muscle, reverses insulin resistance'),
    
    ('SHLP2', 'MGNYIFFTYVTLTKKLR', 17, 'Cytoprotective receptor', 
     'Pro-survival, prevents apoptotic cell death, promotes mitochondrial bioenergetics and ATP generation', 
     'Suppresses age-related metabolic decline and neurodegeneration'),
    
    ('SHLP3', 'MLAFLLAYLSLTLR', 14, 'Cytoprotective receptor', 
     'Suppresses apoptosis, enhances cell viability and increases mitochondrial respiration', 
     'Insulin sensitizer and regulator of cellular aging')
ON CONFLICT DO NOTHING;
