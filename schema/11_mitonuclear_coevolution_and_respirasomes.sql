-- ============================================================================
-- mitoChado: 11_mitonuclear_coevolution_and_respirasomes.sql
-- Co-evolução Núcleo-Mitocondrial, Interfaces Estruturais
-- e Supercomplexos Respiratórios (Respirasomas)
-- ============================================================================

-- 1. Pares de Interação Direta e Co-evolução Núcleo-Mitocondrial
CREATE TABLE mitonuclear_interaction_pair (
    id BIGSERIAL PRIMARY KEY,
    mt_protein_id BIGINT NOT NULL REFERENCES mitoprotein(id) ON DELETE CASCADE,
    nuclear_protein_id BIGINT NOT NULL REFERENCES mitoprotein(id) ON DELETE CASCADE,
    
    -- Mapeamento da Interface de Contato Físico
    mt_interface_residues INT[] DEFAULT '{}',      -- Lista de posições de aminoácidos na proteína mtDNA
    nuclear_interface_residues INT[] DEFAULT '{}', -- Posições na proteína nuclear
    contact_surface_area_angstrom2 DOUBLE PRECISION,
    binding_affinity_kd_nm DOUBLE PRECISION,
    
    -- Incompatibilidade Cito-Nuclear e Terapia Mitocondrial (MRT)
    coevolutionary_correlation_score DOUBLE PRECISION, -- Score de covariância evolutiva
    mismatch_pathogenicity_risk TEXT DEFAULT 'LOW',    -- 'HIGH', 'MODERATE', 'LOW'
    
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uq_mitonuclear_pair UNIQUE (mt_protein_id, nuclear_protein_id)
);

CREATE INDEX idx_mitonuc_mt ON mitonuclear_interaction_pair (mt_protein_id);
CREATE INDEX idx_mitonuc_nuclear ON mitonuclear_interaction_pair (nuclear_protein_id);

-- 2. Supercomplexos Respiratórios (Respirasomas) e Cardiolipina
CREATE TABLE respirasome_supercomplex (
    id SERIAL PRIMARY KEY,
    tax_id INT NOT NULL REFERENCES organism(tax_id) ON DELETE CASCADE,
    stoichiometry TEXT NOT NULL,                  -- Ex: 'I_1_III_2_IV_1' (Respirasoma Canônico), 'III_2_IV_2'
    name TEXT NOT NULL,                           -- Ex: 'Mammalian Respirasome Megacomplex'
    molecular_mass_mda DOUBLE PRECISION,          -- Massa molecular em Megadaltons (~1.7 MDa)
    
    -- Papel da Cardiolipina na Estabilidade do Complexo
    cardiolipin_binding_sites INT NOT NULL DEFAULT 0,
    destabilized_in_barth_syndrome BOOLEAN NOT NULL DEFAULT TRUE, -- Síndrome de Barth (mutação em Tafazzina)
    
    -- Estrutura Cryo-EM PDB
    pdb_id TEXT,                                  -- Ex: '5XTH', '7V29'
    cryoem_resolution_angstrom DOUBLE PRECISION,  -- Ex: 3.2
    
    participating_protein_ids BIGINT[] DEFAULT '{}',
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);

CREATE INDEX idx_respirasome_tax ON respirasome_supercomplex (tax_id);
CREATE INDEX idx_respirasome_pdb ON respirasome_supercomplex (pdb_id);
