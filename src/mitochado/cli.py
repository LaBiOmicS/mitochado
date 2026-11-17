"""mitoChado Command-Line Interface (CLI)."""

import json
from pathlib import Path
from typing import Optional
import typer
from rich.console import Console
from rich.table import Table

from mitochado.db import DEFAULT_MITO_PG_URL, execute_schema_files, get_connection
from mitochado.loaders.genbank import parse_genbank_mitogenome
from mitochado.loaders.fasta import parse_mitogenome_fasta

app = typer.Typer(
    name="mitochado",
    help="mitoChado: Mitochondrial Multi-Omics Database Engine (2026 Edition)",
    add_completion=False,
)
console = Console()

SCHEMA_DIR = Path(__file__).resolve().parent.parent.parent / "schema"

@app.command()
def ping(db_url: str = typer.Option(DEFAULT_MITO_PG_URL, "--db-url", "-d", help="Database connection URL")):
    """Test connection to PostgreSQL mitoChado database."""
    try:
        with get_connection(db_url) as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT version();")
                ver = cur.fetchone()["version"]
                console.print(f"[bold green]✓ Conexão ao mitoChado bem-sucedida![/bold green]\n{ver}")
    except Exception as e:
        console.print(f"[bold red]✗ Erro ao conectar ao mitoChado:[/bold red] {e}")
        raise typer.Exit(code=1)

@app.command()
def init_db(
    schema_path: Path = typer.Option(SCHEMA_DIR, "--schema-dir", "-s", help="Path to SQL schema directory"),
    db_url: str = typer.Option(DEFAULT_MITO_PG_URL, "--db-url", "-d", help="Database connection URL"),
):
    """Initializes mitoChado DDL schemas, extensions, and mitochondrial genetic codes."""
    try:
        console.print(f"[bold cyan]Executando migrações do mitoChado em {schema_path}...[/bold cyan]")
        applied = execute_schema_files(schema_path, db_url)
        for f in applied:
            console.print(f"  [green]✓[/green] Aplicado: {f}")
        console.print("[bold green]✓ Banco mitoChado inicializado com sucesso![/bold green]")
    except Exception as e:
        console.print(f"[bold red]✗ Falha na inicialização do mitoChado:[/bold red] {e}")
        raise typer.Exit(code=1)

@app.command()
def add_mitogenome(
    tax_id: int = typer.Option(..., "--taxid", "-t", help="NCBI TaxID (e.g., 9606, 3702 for Arabidopsis)"),
    scientific_name: str = typer.Option(..., "--scientific-name", "-s", help="Scientific Name (e.g., 'Homo sapiens', 'Arabidopsis thaliana')"),
    accession: str = typer.Option(..., "--accession", "-a", help="GenBank/RefSeq accession (e.g., 'NC_012920.1', 'NC_001284.2')"),
    name: str = typer.Option(..., "--name", "-n", help="Mitogenome description/name"),
    length: int = typer.Option(..., "--length", "-l", help="Length in base pairs"),
    code_id: int = typer.Option(2, "--code-id", "-c", help="NCBI translation table (1: Plants, 2: Vertebrates, 3: Yeast, 4: Mold/Protozoa, 5: Invertebrates)"),
    topology: str = typer.Option("circular_single", "--topology", help="Topology: circular_single, circular_multipartite, linear_tandem, linear_hairpin, kdna_network"),
    clade: str = typer.Option("Metazoa", "--clade", help="Clade: Metazoa, Viridiplantae, Fungi, Alveolata, Euglenozoa"),
    is_canonical: bool = typer.Option(True, "--canonical/--non-canonical"),
    db_url: str = typer.Option(DEFAULT_MITO_PG_URL, "--db-url", "-d"),
):
    """Registers an organism and its mitochondrial genome with specific topology and genetic code."""
    with get_connection(db_url) as conn:
        with conn.cursor() as cur:
            # 1. Garante o organismo com seu clado
            cur.execute(
                """
                INSERT INTO organism (tax_id, scientific_name, clade)
                VALUES (%s, %s, %s)
                ON CONFLICT (tax_id) DO UPDATE SET scientific_name = EXCLUDED.scientific_name, clade = EXCLUDED.clade;
                """,
                (tax_id, scientific_name, clade),
            )
            # 2. Insere o mitogenoma com a topologia exata
            cur.execute(
                """
                INSERT INTO mitogenome (
                    tax_id, accession, name, length, topology, genetic_code_id, is_canonical_reference
                ) VALUES (%s, %s, %s, %s, %s, %s, %s)
                RETURNING id;
                """,
                (tax_id, accession, name, length, topology, code_id, is_canonical),
            )
            mito_id = cur.fetchone()["id"]
            conn.commit()

    console.print(f"[bold green]✓ Mitogenoma registrado com ID {mito_id}:[/bold green] {accession} ({scientific_name})")
    console.print(f"  [cyan]Clado:[/cyan] {clade} | [cyan]Topologia:[/cyan] {topology} | [cyan]Código NCBI:[/cyan] {code_id}")

@app.command()
def list_mitogenomes(db_url: str = typer.Option(DEFAULT_MITO_PG_URL, "--db-url", "-d")):
    """Lists registered mitogenomes and their properties."""
    with get_connection(db_url) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT m.id, m.accession, m.name, o.scientific_name, m.length, mgc.name AS code_name
                FROM mitogenome m
                JOIN organism o ON o.tax_id = m.tax_id
                JOIN mitochondrial_genetic_code mgc ON mgc.id = m.genetic_code_id
                ORDER BY m.id;
                """
            )
            rows = cur.fetchall()

    if not rows:
        console.print("[yellow]Nenhum mitogenoma registrado.[/yellow]")
        return

    table = Table(title="Mitogenomas Cadastrados no mitoChado")
    table.add_column("ID", style="dim")
    table.add_column("Accession", style="bold cyan")
    table.add_column("Espécie", style="green")
    table.add_column("Tamanho (pb)", justify="right")
    table.add_column("Código Genético", style="magenta")

    for r in rows:
        table.add_row(
            str(r["id"]),
            r["accession"],
            r["scientific_name"],
            str(r["length"]),
            r["code_name"],
        )
    console.print(table)

@app.command()
def add_variant(
    mitogenome_id: int = typer.Option(..., "--mitogenome-id", "-m"),
    position: int = typer.Option(..., "--position", "-p", help="1-based position on mtDNA (e.g. 3243)"),
    ref: str = typer.Option(..., "--ref", "-r", help="Reference allele (e.g. A)"),
    alt: str = typer.Option(..., "--alt", "-a", help="Alternative allele (e.g. G)"),
    heteroplasmy: float = typer.Option(..., "--heteroplasmy", "-h", help="Heteroplasmy level (0.0 to 1.0)"),
    significance: str = typer.Option("VUS", "--significance", "-s", help="Pathogenicity (e.g. Pathogenic, Benign)"),
    disease: Optional[str] = typer.Option(None, "--disease", help="Associated pathology (e.g. MELAS)"),
    db_url: str = typer.Option(DEFAULT_MITO_PG_URL, "--db-url", "-d"),
):
    """Registers a mitochondrial variant with heteroplasmy level and clinical significance."""
    hgvs = f"m.{position}{ref}>{alt}"
    with get_connection(db_url) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO mitochondrial_variant (
                    mitogenome_id, position, ref_allele, alt_allele,
                    heteroplasmy_level, clinical_significance, associated_disease, hgvs_nomenclature
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id, is_homoplasmic;
                """,
                (mitogenome_id, position, ref, alt, heteroplasmy, significance, disease, hgvs),
            )
            row = cur.fetchone()
            var_id = row["id"]
            is_homo = row["is_homoplasmic"]
            conn.commit()

    homo_tag = "[cyan]Homoplásmica[/cyan]" if is_homo else f"[magenta]Heteroplásmica ({heteroplasmy*100:.1f}%)[/magenta]"
    console.print(f"[bold green]✓ Variante registrada com ID {var_id}:[/bold green] {hgvs} ({homo_tag}) - {significance}")

@app.command()
def load_gbk(
    gbk_path: Path = typer.Argument(..., help="Path to GenBank file (.gbk, .gb)"),
    db_url: str = typer.Option(DEFAULT_MITO_PG_URL, "--db-url", "-d"),
):
    """Parses a GenBank file with BioPython and loads the organism, mitogenome, and all 37 features."""
    console.print(f"[bold cyan]Lendo arquivo GenBank mitocondrial:[/bold cyan] {gbk_path}")
    data = parse_genbank_mitogenome(gbk_path)
    
    org = data["organism"]
    mito = data["mitogenome"]
    feats = data["features"]
    
    with get_connection(db_url) as conn:
        with conn.cursor() as cur:
            # 1. Registra ou atualiza organismo
            cur.execute(
                """
                INSERT INTO organism (tax_id, scientific_name, lineage)
                VALUES (%s, %s, %s)
                ON CONFLICT (tax_id) DO UPDATE SET scientific_name = EXCLUDED.scientific_name
                RETURNING tax_id;
                """,
                (org["tax_id"], org["scientific_name"], org["lineage"]),
            )
            tax_id = cur.fetchone()["tax_id"]
            
            # 2. Registra o mitogenoma completo com métricas
            d_loop_range = None
            if mito["d_loop_coords"]:
                d_loop_range = f"[{mito['d_loop_coords'][0]},{mito['d_loop_coords'][1]})"
                
            cur.execute(
                """
                INSERT INTO mitogenome (
                    tax_id, accession, name, length, topology, genetic_code_id,
                    gc_content, at_skew, gc_skew, raw_sequence, d_loop_coordinates
                ) VALUES (
                    %s, %s, %s, %s, %s, %s,
                    %s, %s, %s, %s, %s::int8range
                )
                ON CONFLICT (accession) DO UPDATE SET
                    name = EXCLUDED.name, length = EXCLUDED.length,
                    gc_content = EXCLUDED.gc_content, at_skew = EXCLUDED.at_skew, gc_skew = EXCLUDED.gc_skew
                RETURNING id;
                """,
                (
                    tax_id, mito["accession"], mito["name"], mito["length"], mito["topology"],
                    mito["genetic_code_id"], mito["gc_content"], mito["at_skew"], mito["gc_skew"],
                    mito["raw_sequence"], d_loop_range
                ),
            )
            mitogenome_id = cur.fetchone()["id"]
            
            # 3. Insere todas as features (13 PCGs, 22 tRNAs, rRNAs, D-Loop)
            cur.execute("DELETE FROM mitofeature WHERE mitogenome_id = %s;", (mitogenome_id,))
            
            for f in feats:
                cur.execute(
                    """
                    INSERT INTO mitofeature (
                        mitogenome_id, category, gene_symbol, coordinates, strand,
                        synteny_order, protein_sequence, trna_amino_acid, trna_anticodon, metadata
                    ) VALUES (
                        %s, %s, %s, int8range(%s, %s, '[)'), %s,
                        %s, %s, %s, %s, %s::jsonb
                    );
                    """,
                    (
                        mitogenome_id, f["category"], f["gene_symbol"], f["start"], f["end"], f["strand"],
                        f["synteny_order"], f["protein_sequence"], f["trna_amino_acid"], f["trna_anticodon"],
                        json.dumps(f["attributes"])
                    ),
                )
            conn.commit()

    console.print(f"[bold green]✓ Sucesso![/bold green] Mitogenoma [bold cyan]{mito['accession']}[/bold cyan] carregado!")
    console.print(f"  • [green]Espécie:[/green] {org['scientific_name']} (TaxID: {tax_id})")
    console.print(f"  • [green]Comprimento:[/green] {mito['length']} pb | [green]%GC:[/green] {mito['gc_content']}% | [green]AT-skew:[/green] {mito['at_skew']} | [green]GC-skew:[/green] {mito['gc_skew']}")
    console.print(f"  • [green]Features anotadas:[/green] {len(feats)} (ordenadas por sintenia)")

if __name__ == "__main__":
    app()
