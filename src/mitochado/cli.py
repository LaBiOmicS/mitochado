"""mitoChado Command-Line Interface (CLI)."""

from pathlib import Path
from typing import Optional
import typer
from rich.console import Console
from rich.table import Table

from mitochado.db import DEFAULT_MITO_PG_URL, execute_schema_files, get_connection

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

if __name__ == "__main__":
    app()
