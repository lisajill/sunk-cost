#!/usr/bin/env python3
"""
One-off seed generator for Sunk Cost.

Reads the Furniture and Property Upgrades tabs from an existing house
cost-tracking spreadsheet and produces the app's items.json seed file.
Not part of the app itself -- run once during setup.

Mapping rules:
  - note contains "gone", "gone now", or "replaced"  -> status: gone
  - note contains "not spent yet"                    -> status: planned
  - otherwise                                        -> status: owned
  - a cost cell that isn't a real number (e.g. "???") becomes a blank
    (null) cost, regardless of status -- everything else keeps its
    actual dollar amount, including planned items that already had a
    budgeted estimate (e.g. "Outdoor lighting" at $1500, not spent yet).

Uses only the Python standard library (zipfile + xml) since this machine
doesn't have openpyxl installed, and installing a new package just for a
one-off script isn't worth it.
"""
import argparse
import json
import sys
import uuid
import zipfile
from datetime import datetime, timedelta, timezone
from pathlib import Path
from xml.etree import ElementTree as ET

NS = {"s": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}

SHEET_FILES = {
    "Furniture": "xl/worksheets/sheet4.xml",
    "Property Upgrades": "xl/worksheets/sheet5.xml",
}

GONE_MARKERS = ("gone", "gone now", "replaced")
PLANNED_MARKERS = ("not spent yet",)


def load_shared_strings(zf):
    with zf.open("xl/sharedStrings.xml") as f:
        root = ET.parse(f).getroot()
    strings = []
    for si in root.findall("s:si", NS):
        texts = si.findall(".//s:t", NS)
        strings.append("".join(t.text or "" for t in texts))
    return strings


def cell_value(cell, shared_strings):
    t = cell.get("t")
    v = cell.find("s:v", NS)
    if v is None:
        return None
    if t == "s":
        return shared_strings[int(v.text)]
    return v.text


def parse_rows(zf, sheet_path, shared_strings):
    with zf.open(sheet_path) as f:
        root = ET.parse(f).getroot()
    rows = []
    for row in root.findall(".//s:sheetData/s:row", NS):
        cells = row.findall("s:c", NS)
        values = [cell_value(c, shared_strings) for c in cells]
        rows.append(values)
    return rows


def to_number(raw):
    if raw is None:
        return None
    try:
        return float(str(raw).strip())
    except ValueError:
        return None


def classify_status(note):
    note_lower = (note or "").lower()
    if any(marker in note_lower for marker in GONE_MARKERS):
        return "gone"
    if any(marker in note_lower for marker in PLANNED_MARKERS):
        return "planned"
    return "owned"


def build_items(xlsx_path):
    items = []
    base_time = datetime.now(timezone.utc)

    with zipfile.ZipFile(xlsx_path) as zf:
        shared_strings = load_shared_strings(zf)

        index = 0
        for category, sheet_path in SHEET_FILES.items():
            rows = parse_rows(zf, sheet_path, shared_strings)
            # First row is the header ("Item", "Cost", ...); skip it.
            for row in rows[1:]:
                if not row or not row[0]:
                    continue
                name = str(row[0]).strip()
                if not name:
                    continue

                raw_cost = row[1] if len(row) > 1 else None
                # Notes can land in any later cell (col C, D, ...); join
                # whatever text is there so "not spent yet" is found
                # regardless of which column it happened to be typed in.
                note = " ".join(str(v) for v in row[2:] if v)

                status = classify_status(note)
                cost = to_number(raw_cost)

                date_added = base_time - timedelta(seconds=index)
                items.append(
                    {
                        "id": str(uuid.uuid4()),
                        "name": name,
                        "category": category,
                        "cost": cost,
                        "status": status,
                        "dateAdded": date_added.strftime("%Y-%m-%dT%H:%M:%S.")
                        + f"{date_added.microsecond // 1000:03d}Z",
                    }
                )
                index += 1

    return items


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("xlsx_path", type=Path, help="Path to the source .xlsx spreadsheet")
    parser.add_argument("output_path", type=Path, help="Where to write the seed items.json")
    args = parser.parse_args()

    items = build_items(args.xlsx_path)
    app_data = {"items": items, "homeValue": None}

    args.output_path.parent.mkdir(parents=True, exist_ok=True)
    args.output_path.write_text(json.dumps(app_data, indent=2, sort_keys=True))

    print(f"Wrote {len(items)} items to {args.output_path}")
    by_status = {}
    for item in items:
        by_status[item["status"]] = by_status.get(item["status"], 0) + 1
    for status, count in sorted(by_status.items()):
        print(f"  {status}: {count}")


if __name__ == "__main__":
    sys.exit(main())
