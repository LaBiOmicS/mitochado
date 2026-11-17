-- ============================================================================
-- mitoChado (Draft): 07_future_kingdoms_introns_trans_splicing.sql
-- Íntrons Mitocondriais (Grupo I e II), Trans-Splicing em Plantas
-- e Redes de kDNA em Kinetoplastídeos (Trypanosoma)
-- ============================================================================

-- 1. Tipos de Topologias Mitocondriais na Árvore da Vida
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'mitochondrial_topology_type') THEN
        CREATE TYPE mitochondrial_topology_type AS ENUM (
            'circular_single',         -- Metazoa padrão (~16.5 kb único anel)
            'circular_multipartite',    -- Plantas com múltiplos subcírculos recombinantes / piolhos
            'linear_tandem',           -- Apicomplexa / Plasmodium (~6 kb repetições em tandem)
            'linear_hairpin',          -- Ciliados (Paramecium, Tetrahymena) com telômeros em grampo
            'kdna_network',            -- Kinetoplastida (Trypanosoma, Leishmania) maxicírculos e minicírculos
            'branching_recombinant'    -- Plantas vasculares (Silene) com formas dinâmicas ramificadas
        );
    END IF;
END$$;

-- 2. Tipos de Íntrons Mitocondriais Catalíticos
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'mitointron_type') THEN
        CREATE TYPE mitointron_type AS ENUM (
            'group_I',               -- Ribozima auto-catalítica com guanosina cofator
            'group_II',              -- Precursor evolucionário dos íntrons spliceossomais (estrutura lariat)
            'group_II_twintron',     -- Íntron dentro de íntron
            'archaeal_like'          -- Íntrons atípicos em alguns protozoários
        );
    END IF;
END$$;

-- 3. Tabela de Íntrons Mitocondriais (Plantas e Fungos)
CREATE TABLE IF NOT EXISTS mitointron (
    id BIGSERIAL PRIMARY KEY,
    mitogenome_id INT NOT NULL REFERENCES mitogenome(id) ON DELETE CASCADE,
    host_gene_id BIGINT NOT NULL REFERENCES mitofeature(id) ON DELETE CASCADE,
    intron_number INT NOT NULL,                  -- Ex: intron 1, 2, 3 do gene cox1
    intron_type mitointron_type NOT NULL,
    coordinates INT8RANGE NOT NULL,              -- [start, end)
    
    -- Elementos Genéticos Móveis dentro do Íntron (HEGs e Maturases)
    has_homing_endonuclease BOOLEAN DEFAULT FALSE,
    heg_family TEXT,                             -- 'LAGLIDADG', 'GIY-YIG', 'H-N-H', 'His-Cys box'
    maturase_protein_id BIGINT,                  -- FK se codificar maturase própria
    
    -- Splicing
    is_trans_spliced BOOLEAN NOT NULL DEFAULT FALSE, -- True em plantas (ex: nad1, nad2, nad5)
    donor_splice_site TEXT,                      -- Sequência do sítio 5'
    acceptor_splice_site TEXT,                   -- Sequência do sítio 3'
    
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_mitointron_host ON mitointron (host_gene_id);
CREATE INDEX IF NOT EXISTS idx_mitointron_type ON mitointron (intron_type);
CREATE INDEX IF NOT EXISTS idx_mitointron_trans ON mitointron (is_trans_spliced);

-- 4. Junções de Trans-Splicing Mitocondrial (Plantas - Viridiplantae)
CREATE TABLE IF NOT EXISTS mitochondrial_trans_splicing_junction (
    id BIGSERIAL PRIMARY KEY,
    mitogenome_id INT NOT NULL REFERENCES mitogenome(id) ON DELETE CASCADE,
    upstream_exon_feature_id BIGINT NOT NULL REFERENCES mitofeature(id),
    downstream_exon_feature_id BIGINT NOT NULL REFERENCES mitofeature(id),
    intermediate_intron_id BIGINT REFERENCES mitointron(id),
    distance_between_exons_bp BIGINT,            -- Distância linear ou indicação de subcírculos diferentes
    is_inter_molecular BOOLEAN NOT NULL DEFAULT FALSE, -- True se éxons estiverem em subcírculos distintos
    evidence TEXT,                               -- Ex: 'cDNA sequencing', 'Iso-Seq'
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

-- 5. Biblioteca de Minicírculos e gRNAs de kDNA (Kinetoplastida: Trypanosoma / Leishmania)
CREATE TABLE IF NOT EXISTS kdna_minicircle_library (
    id BIGSERIAL PRIMARY KEY,
    tax_id INT NOT NULL REFERENCES organism(tax_id) ON DELETE CASCADE,
    minicircle_class TEXT NOT NULL,              -- Classe ou contig do minicírculo (~1 kb)
    length INT NOT NULL,
    grna_sequence TEXT NOT NULL,                 -- Sequência do Guide RNA
    target_maxicircle_gene TEXT NOT NULL,        -- Ex: 'COX2', 'ND7', 'CYTB'
    target_editing_domain INT8RANGE NOT NULL,    -- Região do pré-mRNA do maxicírculo que é editada
    anchor_region TEXT,                          -- Região de ancoragem 5' do gRNA
    uridine_additions_count INT,                 -- Número de uridinas adicionadas
    uridine_deletions_count INT,                 -- Número de uridinas deletadas
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_kdna_target ON kdna_minicircle_library (tax_id, target_maxicircle_gene);
