"""Sanitized reports use a typed allowlist, never raw analysis text or credentials."""

import json
import math
from datetime import datetime, timezone
from pathlib import Path

from app.backend.analyzer import FINDING_TYPES
from app.backend.policy import RULE_LABELS
from app.version import VERSION

DISCLAIMER = (
    "Estimates are approximations, not guarantees. Character-space entropy assumes random selection; "
    "human-chosen passwords may be far more predictable. For inputs above 128 characters, "
    "zxcvbn estimates use a bounded sample. No dataset match does not prove a password has never leaked."
)
RECOMMENDATIONS = [
    "Use a unique password for every account.",
    "Prefer cryptographically generated passwords or unrelated random passphrase tokens.",
    "Enable multi-factor authentication wherever available.",
]


def _number(value):
    return value if type(value) in (int, float) and math.isfinite(value) else 0


def sanitized_report(analysis: dict, breach: dict | None = None, policy: dict | None = None) -> dict:
    status = (breach or {}).get("status", "idle")
    if status not in {"idle", "checking", "clear", "compromised", "error"}:
        status = "idle"
    classification = analysis.get("classification")
    if classification not in {
        "Waiting",
        "Critical",
        "Weak",
        "Moderate",
        "Strong",
        "Very Strong",
        "Exceptional",
    }:
        classification = "Waiting"
    allowed_types = set(FINDING_TYPES.values())
    return {
        "application": "TwardyPass",
        "version": VERSION,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "score": _number(analysis.get("score")),
        "classification": classification,
        "length": _number(analysis.get("length")),
        "entropy": _number(analysis.get("entropy")),
        "guesses_log10": _number(analysis.get("guesses_log10")),
        "dna": {
            **{
                key: _number(analysis.get("dna", {}).get(key))
                for key in ("length", "unpredictability", "patternSafety", "characterMix")
            },
            "breachSafety": 100 if status == "clear" else 0 if status == "compromised" else None,
        },
        "finding_types": sorted(
            {f.get("type") for f in analysis.get("findings", []) if f.get("type") in allowed_types}
        ),
        "recommendations": RECOMMENDATIONS,
        "breach": {"status": status, "count": _number((breach or {}).get("count"))},
        "policy": None
        if not policy
        else {
            "passed": policy.get("passed") is True,
            "rules": [
                {"id": r["id"], "passed": r.get("passed") is True}
                for r in policy.get("rules", [])
                if r.get("id") in RULE_LABELS
            ],
        },
        "disclaimer": DISCLAIMER,
    }


def write_json(path: Path, report: dict):
    path.write_text(json.dumps(report, indent=2, ensure_ascii=True), encoding="utf-8")


def write_pdf(path: Path, report: dict):
    from reportlab.lib import colors
    from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
    from reportlab.lib.units import inch
    from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

    styles = getSampleStyleSheet()
    styles.add(
        ParagraphStyle(
            "Caption",
            fontName="Helvetica",
            fontSize=9,
            leading=14,
            textColor=colors.HexColor("#536174"),
            spaceAfter=6,
        )
    )
    doc = SimpleDocTemplate(
        str(path),
        pagesize=(595, 842),
        leftMargin=46,
        rightMargin=46,
        topMargin=32,
        bottomMargin=32,
        title="TwardyPass sanitized report",
        author="TWARDY.exe / Filip Twardowski",
    )
    story = [
        Paragraph("TwardyPass", styles["Title"]),
        Paragraph("PASSWORD SECURITY REPORT  /  v" + VERSION, styles["Caption"]),
        Paragraph("by TWARDY.exe / Filip Twardowski", styles["Caption"]),
        Paragraph(report["timestamp"], styles["Caption"]),
        Spacer(1, 8),
    ]
    rows = [
        ["LOCAL ASSESSMENT", "RESULT"],
        ["Security score", str(report["score"]) + " / 100"],
        ["Classification", report["classification"]],
        ["Length", str(report["length"])],
        ["Character-space entropy estimate", str(report["entropy"]) + " bits"],
        ["Estimated guesses (log10)", str(report["guesses_log10"])],
    ]
    for key, value in report["dna"].items():
        rows.append(["DNA / " + key, "UNKNOWN" if value is None else str(value)])
    rows.append(["Manual breach lookup", report["breach"]["status"].upper()])
    rows.append(["Dataset occurrences", str(report["breach"]["count"])])
    table = Table(rows, colWidths=[3.8 * inch, 3.15 * inch], hAlign="LEFT")
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#101822")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                ("FONTSIZE", (0, 0), (-1, -1), 9),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
                ("TOPPADDING", (0, 0), (-1, -1), 5),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.HexColor("#F0F4F8"), colors.white]),
            ]
        )
    )
    story.extend(
        [
            table,
            Spacer(1, 15),
            Paragraph("Findings", styles["Heading2"]),
            Paragraph(", ".join(report["finding_types"]) or "No findings", styles["BodyText"]),
        ]
    )
    if report["policy"]:
        story.append(
            Paragraph("Policy: " + ("PASS" if report["policy"]["passed"] else "FAIL"), styles["Heading2"])
        )
        for rule in report["policy"]["rules"]:
            story.append(
                Paragraph(
                    RULE_LABELS[rule["id"]] + ": " + ("PASS" if rule["passed"] else "FAIL"),
                    styles["BodyText"],
                )
            )
    story.append(Paragraph("Recommendations", styles["Heading2"]))
    for item in report["recommendations"]:
        story.append(Paragraph(item, styles["BodyText"]))
    story.extend(
        [
            Spacer(1, 15),
            Paragraph(DISCLAIMER, styles["Caption"]),
            Paragraph(
                "Sanitized export: no password, personal context, hash or matched fragments.",
                styles["Caption"],
            ),
        ]
    )
    doc.build(story)
