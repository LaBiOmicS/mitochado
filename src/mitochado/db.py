"""Database connection and migration utilities for mitoChado."""

import os
from pathlib import Path
import psycopg
from psycopg.rows import dict_row

DEFAULT_MITO_PG_URL = os.getenv(
    "MITOCHADO_DATABASE_URL",
    "postgresql://mitochado_admin:mitochado_secret_password@localhost:5433/mitochado"
)

def get_connection(db_url: str = DEFAULT_MITO_PG_URL) -> psycopg.Connection:
    """Returns a psycopg3 connection with dict_row factory."""
    return psycopg.connect(db_url, row_factory=dict_row)

def execute_schema_files(schema_dir: Path, db_url: str = DEFAULT_MITO_PG_URL) -> list[str]:
    """Applies all sorted .sql migration files from schema directory."""
    sql_files = sorted(schema_dir.glob("*.sql"))
    applied = []
    
    with psycopg.connect(db_url) as conn:
        with conn.cursor() as cur:
            for sql_file in sql_files:
                sql_text = sql_file.read_text(encoding="utf-8")
                cur.execute(sql_text)
                applied.append(sql_file.name)
        conn.commit()
        
    return applied
