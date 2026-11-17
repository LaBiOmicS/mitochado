"""FASTA loader for mitoChado using BioPython."""

from pathlib import Path
from typing import Iterator
from Bio import SeqIO
from mitochado.loaders.genbank import calculate_composition_metrics

def parse_mitogenome_fasta(filepath: Path) -> Iterator[dict[str, any]]:
    """Reads FASTA file and yields mitogenome metadata and sequences."""
    for record in SeqIO.parse(str(filepath), "fasta"):
        raw_seq = str(record.seq).upper()
        metrics = calculate_composition_metrics(raw_seq)
        
        yield {
            "accession": record.id,
            "name": record.description,
            "length": len(raw_seq),
            "gc_content": metrics["gc_content"],
            "at_skew": metrics["at_skew"],
            "gc_skew": metrics["gc_skew"],
            "raw_sequence": raw_seq,
        }
