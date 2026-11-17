-- ============================================================================
-- mitoChado (Draft): 06_full_ncbi_genetic_codes.sql
-- Seed de Códigos Genéticos Mitocondriais do NCBI para Plantas, Fungos, etc.
-- ============================================================================

INSERT INTO mitochondrial_genetic_code (id, name, description, start_codons, stop_codons)
VALUES 
    -- 1. Plantas terrestres (Viridiplantae) usam o código padrão universal na mitocôndria
    (1, 'The Standard Code (Plant Mitochondria)', 
     'Plantas terrestres (Viridiplantae) usam o código padrão universal na mitocôndria', 
     ARRAY['ATG', 'CTG', 'TTG'], ARRAY['TAA', 'TAG', 'TGA']),

    -- 2. Vertebrados
    (2, 'The Vertebrate Mitochondrial Code', 
     'Vertebrados (mamíferos, aves, peixes, anfíbios, répteis)', 
     ARRAY['ATG', 'ATA', 'ATC', 'ATT', 'GTG'], ARRAY['TAA', 'TAG', 'AGA', 'AGG']),

    -- 3. Leveduras
    (3, 'The Yeast Mitochondrial Code', 
     'Leveduras (Saccharomyces, Candida). Nota: CUN codifica Treonina em vez de Leucina!', 
     ARRAY['ATG', 'ATA', 'GTG'], ARRAY['TAA', 'TAG']),

    -- 4. Fungos filamentosos, protozoários e celenterados
    (4, 'The Mold, Protozoan, and Coelenterate Mitochondrial Code', 
     'Fungos filamentosos, protozoários flagelados e celenterados', 
     ARRAY['ATG', 'ATA', 'ATC', 'ATT', 'GTG', 'TTG', 'CTG'], ARRAY['TAA', 'TAG']),

    -- 5. Invertebrados
    (5, 'The Invertebrate Mitochondrial Code', 
     'Artrópodes, moluscos, anelídeos, nemátodes. AGA/AGG codifica Serina!', 
     ARRAY['ATG', 'ATA', 'ATC', 'ATT', 'GTG', 'TTG'], ARRAY['TAA', 'TAG']),

    -- 9. Equinodermos e Platelmintos
    (9, 'The Echinoderm and Flatworm Mitochondrial Code', 
     'Equinodermos (ouriços, estrelas-do-mar) e platelmintos. AAA codifica Asparagina!', 
     ARRAY['ATG', 'GTG'], ARRAY['TAA', 'TAG']),

    -- 13. Ascídias
    (13, 'The Ascidian Mitochondrial Code', 
     'Urocordados/Ascídias. AGA/AGG codifica Glicina!', 
     ARRAY['ATG', 'ATA', 'GTG'], ARRAY['TAA', 'TAG']),

    -- 14. Platelmintos Alternativo
    (14, 'The Alternative Flatworm Mitochondrial Code', 
     'Platelmintos parasitas (Schistosoma). UAA codifica Tirosina!', 
     ARRAY['ATG', 'GTG'], ARRAY['TAG']),

    -- 16. Clorófitas (Algas Verdes)
    (16, 'Chlorophycean Mitochondrial Code', 
     'Algas verdes clorofíceas (Chlamydomonas). UAG codifica Leucina!', 
     ARRAY['ATG'], ARRAY['TAA', 'TGA']),

    -- 21. Trematódeos
    (21, 'Trematode Mitochondrial Code', 
     'Trematódeos e fascíolas', 
     ARRAY['ATG', 'GTG'], ARRAY['TAG']),

    -- 22. Scenedesmus
    (22, 'Scenedesmus obliquus Mitochondrial Code', 
     'Algas verdes (Scenedesmus obliquus). UCA = Stop, UAG = Leu', 
     ARRAY['ATG'], ARRAY['TAA', 'TCA']),

    -- 23. Thraustochytrium
    (23, 'Thraustochytrium Mitochondrial Code', 
     'Protozoários marinhos fungóides (Thraustochytrium). TTA = Stop', 
     ARRAY['ATG'], ARRAY['TAA', 'TAG', 'TGA', 'TTA']),

    -- 24. Pterobranchia
    (24, 'Pterobranchia Mitochondrial Code', 
     'Hemicordados (Pterobranchia). AGA = Ser, AGG = Lys', 
     ARRAY['ATG', 'GTG'], ARRAY['TAA', 'TAG'])
ON CONFLICT (id) DO UPDATE 
SET name = EXCLUDED.name, description = EXCLUDED.description, 
    start_codons = EXCLUDED.start_codons, stop_codons = EXCLUDED.stop_codons;
