"""Query Understanding for fixed lists, amounts and dates (stdlib only).

Elasticsearch never applies typo or synonym tolerance to a fixed-list field: the user's words are
turned into one listed value here, from the field catalog, *before* the search template runs,
and the template filters with `term` on that value. The result says how the value was obtained
so the UI can show it as an editable filter chip:

  resolved    code, label or curated wording           -> apply the filter
  suggested   1 edit away from a code or label         -> ask the user to confirm ("did you mean")
  ambiguous   curated wording with several values      -> ask the user to choose
  invalid     anything else                            -> keep the query, list the valid values

Amounts (en locale) always need a currency, and a date that reads both as MM/DD and DD/MM is
returned as ambiguous rather than guessed.

    python3 query_understanding.py account base_currency krone
    python3 query_understanding.py account amount "2,500.00 EUR"
    python3 query_understanding.py customer date 05/07/2025
"""
import json
import re
import sys
from datetime import date, timedelta
from pathlib import Path

CATALOG_DIR = Path(__file__).resolve().parent


def catalog(entity):
    return json.loads((CATALOG_DIR / f"{entity}_field_catalog.json").read_text())


def field_spec(entity, field):
    spec = next(f for f in catalog(entity)["fields"] if f["field"] == field)
    if "values_from" in spec:
        spec = {**field_spec(entity, spec["values_from"]), "field": field}
    return spec


def edit_distance(a, b):
    """Damerau-Levenshtein distance: an adjacent transposition counts as 1 edit, as in ES fuzziness."""
    d = [[i + j if i * j == 0 else 0 for j in range(len(b) + 1)] for i in range(len(a) + 1)]
    for i in range(1, len(a) + 1):
        for j in range(1, len(b) + 1):
            d[i][j] = min(d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + (a[i - 1] != b[j - 1]))
            if i > 1 and j > 1 and a[i - 1] == b[j - 2] and a[i - 2] == b[j - 1]:
                d[i][j] = min(d[i][j], d[i - 2][j - 2] + 1)
    return d[len(a)][len(b)]


def resolve_choice(entity, field, text):
    spec, t = field_spec(entity, field), " ".join(text.lower().split())
    for v in spec["values"]:
        if t == v["code"].lower() or t in v["labels"]:
            return {"status": "resolved", "value": v["code"], "via": "code or label"}
    if t in spec.get("ambiguous", {}):
        return {"status": "ambiguous", "choices": spec["ambiguous"][t]}
    for v in spec["values"]:
        if t in v["wording"]:
            return {"status": "resolved", "value": v["code"], "via": "curated wording"}
    if len(t) >= 3:
        near = sorted({v["code"] for v in spec["values"]
                       for w in [v["code"].lower(), *v["labels"]] if edit_distance(t, w) <= 1})
        if near:
            return {"status": "suggested", "choices": near, "via": "spelling, user confirms"}
    return {"status": "invalid", "valid": [v["code"] for v in spec["values"]]}


AMOUNT_EN = re.compile(r"^\s*(\d{1,3}(?:,\d{3})+|\d+)(?:\.(\d{1,3}))?\s*([A-Za-z]{3})?\s*$")


def parse_amount(entity, text, currency_field="base_currency"):
    """en locale: 2,500.00 EUR -> 2500.0 EUR. 2.500,00 is not an en amount: invalid, never 2.5."""
    m = AMOUNT_EN.match(text)
    if not m:
        return {"status": "invalid", "reason": "not an en amount (1,234.56 CUR)"}
    amount = float(m.group(1).replace(",", "") + "." + (m.group(2) or "0"))
    if not m.group(3):
        return {"status": "needs_currency", "amount": amount}
    currency = resolve_choice(entity, currency_field, m.group(3))
    if currency["status"] != "resolved":
        return {"status": "invalid_currency", "amount": amount, "currency": currency}
    return {"status": "resolved", "amount": amount, "currency": currency["value"]}


def parse_date(text):
    """ISO date -> day range [gte, lt). 05/07/2025 -> ambiguous; 25/07/2025 -> only valid as DD/MM."""
    t = text.strip()
    if re.fullmatch(r"\d{4}-\d{2}-\d{2}", t):
        d = date.fromisoformat(t)
        return {"status": "resolved", "gte": d.isoformat(), "lt": (d + timedelta(days=1)).isoformat()}
    m = re.fullmatch(r"(\d{1,2})/(\d{1,2})/(\d{4})", t)
    if not m:
        return {"status": "invalid"}
    a, b, y = int(m.group(1)), int(m.group(2)), int(m.group(3))
    readings = []
    for label, month, day in (("MM/DD", a, b), ("DD/MM", b, a)):
        try:
            readings.append((label, date(y, month, day)))
        except ValueError:
            pass
    days = sorted({d for _, d in readings})
    if not days:
        return {"status": "invalid"}
    if len(days) > 1:
        return {"status": "ambiguous", "choices": [f"{d.isoformat()} ({label})" for label, d in readings]}
    return {"status": "resolved", "gte": days[0].isoformat(), "lt": (days[0] + timedelta(days=1)).isoformat(),
            "via": "only valid as " + "/".join(label for label, _ in readings)}


def understand(entity, field, text):
    if field == "amount":
        return parse_amount(entity, text)
    if field == "date":
        return parse_date(text)
    return resolve_choice(entity, field, text)


if __name__ == "__main__":
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    print(json.dumps(understand(*sys.argv[1:]), indent=2))
