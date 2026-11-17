"""GenBank (.gb / .gbk) loader for mitoChado using BioPython."""

import re
from pathlib import Path
from typing import Any, Optional
from Bio import SeqIO
from Bio.SeqFeature import SeqFeature

def calculate_composition_metrics(sequence: str) -> dict[str, float]:
    """Calculates %GC, AT-skew and GC-skew from a nucleotide sequence."""
    seq = sequence.upper()
    length = len(seq)
    if length == 0:
        return {"gc_content": 0.0, "at_skew": 0.0, "gc_skew": 0.0}
        
    a = seq.count("A")
    t = seq.count("T")
    c = seq.count("C")
    g = seq.count("G")
    
    gc_content = ((g + c) / length) * 100.0
    at_skew = (a - t) / (a + t) if (a + t) > 0 else 0.0
    gc_skew = (g - c) / (g + c) if (g + c) > 0 else 0.0
    
    return {
        "gc_content": round(gc_content, 2),
        "at_skew": round(at_skew, 4),
        "gc_skew": round(gc_skew, 4),
    }

def extract_taxid_from_feature(feat: SeqFeature) -> Optional[int]:
    """Extracts NCBI Taxonomy ID from a 'source' feature's db_xref."""
    for xref in feat.qualifiers.get("db_xref", []):
        if "taxon:" in xref:
            try:
                return int(xref.split("taxon:")[1])
            except ValueError:
                pass
    return None

def extract_trna_info(feat: SeqFeature) -> tuple[Optional[str], Optional[str]]:
    """Extracts amino acid and anticodon from tRNA qualifiers."""
    anticodon = None
    amino_acid = None
    
    # 1. Tenta pegar anticódon explícito
    raw_anticodon = feat.qualifiers.get("anticodon", [])
    if raw_anticodon:
        # Formato comum: '(pos:1601..1603,aa:Phe,seq:gaa)'
        match = re.search(r'seq:([A-Za-z]{3})', raw_anticodon[0])
        if match:
            anticodon = match.group(1).upper()
            
    # 2. Tenta inferir aminoácido
    product = feat.qualifiers.get("product", [""])[0]
    gene = feat.qualifiers.get("gene", [""])[0]
    text = f"{product} {gene}"
    
    aa_map = {
        "Ala": "A", "Cys": "C", "Asp": "D", "Glu": "E", "Phe": "F",
        "Gly": "G", "His": "H", "Ile": "I", "Lys": "K", "Leu": "L",
        "Met": "M", "Asn": "N", "Pro": "P", "Gln": "Q", "Arg": "R",
        "Ser": "S", "Thr": "T", "Val": "V", "Trp": "W", "Tyr": "Y"
    }
    for code3, code1 in aa_map.items():
        if code3.lower() in text.lower():
            amino_acid = code1
            break
            
    return amino_acid, anticodon

def parse_genbank_mitogenome(filepath: Path) -> dict[str, Any]:
    """Parses a GenBank mitogenome file into structured mitoChado entities."""
    record = SeqIO.read(str(filepath), "genbank")
    raw_seq = str(record.seq).upper()
    metrics = calculate_composition_metrics(raw_seq)
    
    tax_id = 9606 # Default fallback
    transl_table = 2
    organism_name = record.annotations.get("organism", record.description)
    lineage = record.annotations.get("taxonomy", [])
    
    topology_annot = record.annotations.get("topology", "circular").lower()
    topology = "circular_single" if "circular" in topology_annot else "linear_tandem"
    
    features_to_insert = []
    d_loop_coords = None
    
    for f in record.features:
        if f.type == "source":
            extracted_tax = extract_taxid_from_feature(f)
            if extracted_tax:
                tax_id = extracted_tax
            raw_transl = f.qualifiers.get("transl_table")
            if raw_transl:
                transl_table = int(raw_transl[0])
        elif f.type in ("CDS", "tRNA", "rRNA", "D-loop", "regulatory"):
            # Determina a categoria
            if f.type == "CDS":
                cat = "pcg"
            elif f.type == "tRNA":
                cat = "trna"
            elif f.type == "rRNA":
                cat = "rrna"
            else:
                cat = "d_loop"
                
            gene_name = f.qualifiers.get("gene", f.qualifiers.get("product", [f.type]))[0]
            
            # Coordenadas 0-based half-open nativas do BioPython
            start_pos = int(f.location.start)
            end_pos = int(f.location.end)
            strand = 1 if f.location.strand == 1 else -1
            
            trna_aa, trna_anti = (None, None)
            if cat == "trna":
                trna_aa, trna_anti = extract_trna_info(f)
                
            prot_seq = f.qualifiers.get("translation", [None])[0] if cat == "pcg" else None
            
            if cat == "d_loop" and not d_loop_coords:
                d_loop_coords = (start_pos, end_pos)
                
            features_to_insert.append({
                "category": cat,
                "gene_symbol": gene_name,
                "start": start_pos,
                "end": end_pos,
                "strand": strand,
                "protein_sequence": prot_seq,
                "trna_amino_acid": trna_aa,
                "trna_anticodon": trna_anti,
                "attributes": {k: v[0] if len(v) == 1 else v for k, v in f.qualifiers.items() if k != "translation"},
            })

    # Ordena as features por coordenada inicial para definir a ordem de sintenia (1 a N)
    features_to_insert.sort(key=lambda x: x["start"])
    for idx, feat in enumerate(features_to_insert, 1):
        feat["synteny_order"] = idx
        
    return {
        "organism": {
            "tax_id": tax_id,
            "scientific_name": organism_name,
            "lineage": lineage,
        },
        "mitogenome": {
            "accession": record.id,
            "name": record.description,
            "length": len(raw_seq),
            "topology": topology,
            "genetic_code_id": transl_table,
            "gc_content": metrics["gc_content"],
            "at_skew": metrics["at_skew"],
            "gc_skew": metrics["gc_skew"],
            "raw_sequence": raw_seq,
            "d_loop_coords": d_loop_coords,
        },
        "features": features_to_insert,
    }
