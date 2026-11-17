-- ============================================================================
-- mitoChado: 06_seed_mitochondrial_core.sql
-- Seed de Códigos Genéticos do NCBI e Dados Mitocondriais Canônicos
-- ============================================================================

-- Códigos Genéticos Mitocondriais Oficiais do NCBI
INSERT INTO mitochondrial_genetic_code (id, name, description, start_codons, stop_codons)
VALUES 
    (2, 'The Vertebrate Mitochondrial Code', 'Código mitocondrial de vertebrados (mamíferos, aves, peixes, anfíbios, répteis)', 
     ARRAY['ATG', 'ATA', 'ATC', 'ATT', 'GTG'], ARRAY['TAA', 'TAG', 'AGA', 'AGG']),
    (5, 'The Invertebrate Mitochondrial Code', 'Código mitocondrial de invertebrados (artrópodes, moluscos, anelídeos)', 
     ARRAY['ATG', 'ATA', 'ATC', 'ATT', 'GTG', 'TTG'], ARRAY['TAA', 'TAG']),
    (9, 'The Echinoderm and Flatworm Mitochondrial Code', 'Equinodermos e platelmintos', 
     ARRAY['ATG', 'GTG'], ARRAY['TAA', 'TAG']),
    (14, 'The Alternative Flatworm Mitochondrial Code', 'Platelmintos alternativo (Schistosoma)', 
     ARRAY['ATG', 'GTG'], ARRAY['TAG'])
ON CONFLICT (id) DO NOTHING;

-- Haplogrupos Raiz Humanos Canônicos
INSERT INTO mitochondrial_haplogroup (name, parent_haplogroup, clade, description)
VALUES 
    ('L', NULL, 'Human', 'Haplogrupo mitocondrial mais basal (Eve Mitocondrial)'),
    ('L0', 'L', 'Human', 'Linhagem mitocondrial ancestral africana'),
    ('L1', 'L', 'Human', 'Linhagem mitocondrial centro-africana'),
    ('L2', 'L', 'Human', 'Linhagem mitocondrial oeste-africana'),
    ('L3', 'L', 'Human', 'Linhagem ancestral da expansão Out-of-Africa'),
    ('M', 'L3', 'Human', 'Macrogrupo mitocondrial euroasiático/asiático'),
    ('N', 'L3', 'Human', 'Macrogrupo mitocondrial eurasiático e nativo-americano'),
    ('R', 'N', 'Human', 'Subclado de N ancestral de B, F, J, T, P, U, H, V')
ON CONFLICT (name) DO NOTHING;
