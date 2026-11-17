-- ============================================================================
-- mitoChado: 00_extensions.sql
-- Extensões PostgreSQL para o MitoChado
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gist";
CREATE EXTENSION IF NOT EXISTS "vector"; -- Busca vetorial para estruturas e proteínas mitocondriais
