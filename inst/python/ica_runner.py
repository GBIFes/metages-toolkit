"""Download the current IPT archive and invoke the original GBIF ICA code."""
import argparse
import contextlib
import datetime
import importlib.util
import json
import logging
import math
import sys
import tempfile
from importlib.metadata import distribution
from pathlib import Path
from urllib.parse import parse_qs, urlencode, urlsplit, urlunsplit


def load_calculator():
    # Load only gbif_data: the package __init__ imports the entire FAIR evaluator.
    package = distribution("fair-eva-plugin-gbif")
    path = Path(package.locate_file("fair_eva/plugin/gbif/gbif_data.py"))
    spec = importlib.util.spec_from_file_location("metages_gbif_data", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    if not module.SHP_PATH.is_file():
        raise RuntimeError("Missing plugin country boundaries")
    return module


def archive_url(url):
    parts = urlsplit(url)
    if parts.scheme not in ("http", "https") or not parts.netloc:
        raise ValueError("url_ipt must be an HTTP(S) IPT URL")
    resource = parse_qs(parts.query).get("r", [])
    if not resource or not resource[0]:
        raise ValueError("url_ipt must contain the IPT resource parameter r")
    base = parts.path.rsplit("/", 1)[0]
    return urlunsplit((parts.scheme, parts.netloc, base + "/archive.do",
                       urlencode({"r": resource[0]}), ""))


def calculate(module, url):
    import requests
    with tempfile.TemporaryDirectory(prefix="metages-ica-") as folder:
        archive = Path(folder) / "archive.zip"
        with requests.get(archive_url(url), stream=True, timeout=(30, 120)) as response:
            response.raise_for_status()
            with archive.open("wb") as output:
                for chunk in response.iter_content(chunk_size=1024 * 1024):
                    output.write(chunk)
        scores = module.ICA(str(archive))
    result = {target: float(scores[source]) for target, source in
              {"ICA": "ICA", "Icat": "Taxonomic", "Icag": "Geographic",
               "Icad": "Temporal"}.items()}
    if not all(math.isfinite(value) for value in result.values()):
        raise ValueError("ICA returned non-finite scores")
    result["fecha_validacion"] = datetime.date.today().isoformat()
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    logging.basicConfig(stream=sys.stderr, level=logging.WARNING)
    try:
        with contextlib.redirect_stdout(sys.stderr):
            module = load_calculator()
            result = {"ready": True} if args.check else calculate(
                module, json.load(sys.stdin)["url_ipt"])
        print(json.dumps(result, allow_nan=False))
        return 0
    except Exception as error:
        print(json.dumps({"error": str(error)}))
        return 1


if __name__ == "__main__":
    sys.exit(main())
