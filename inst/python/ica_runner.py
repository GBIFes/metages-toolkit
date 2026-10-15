"""Descargar un DwC-A y ejecutar el calculador ICA original de GBIF."""
import argparse
import contextlib
import datetime
import importlib.util
import json
import logging
import math
import os
import re
import subprocess
import sys
import tempfile
from importlib.metadata import PackageNotFoundError, distribution
from pathlib import Path
from decimal import Decimal, ROUND_DOWN, localcontext
from urllib.parse import urlsplit, urlunsplit


def prepare_environment():
    """Reutilizar un venv explicito o crear uno persistente para el workflow."""
    if sys.platform == "win32":
        raise RuntimeError("El catalogo oficial requiere fcntl; ejecuta R y Python en Linux o WSL")
    executable = Path(sys.executable)
    if sys.prefix == sys.base_prefix:
        cache = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
        directory = Path(os.environ.get("METAGES_ICA_VENV", cache / "metagesToolkit/ica-venv"))
        directory = directory.expanduser().resolve()
        executable = directory / "bin/python"
        if not executable.is_file():
            if importlib.util.find_spec("ensurepip") is None:
                raise RuntimeError(
                    "Falta ensurepip para crear el venv. En Ubuntu/WSL ejecuta una vez: "
                    "sudo apt install python3-venv")
            subprocess.run([sys.executable, "-m", "venv", str(directory)],
                           check=True, stdout=sys.stderr, stderr=sys.stderr, timeout=120)
    process = subprocess.run(
        [str(executable), str(Path(__file__).resolve()), "--check", "--update"],
        check=True, capture_output=True, text=True, timeout=3500)
    if process.stderr:
        print(process.stderr, file=sys.stderr)
    return json.loads(process.stdout)


def ensure_dependencies():
    """Instalar solo las dependencias de calculo que no estan disponibles."""
    dependencies = {"dwca": "python-dwca-reader", "geopandas": "geopandas",
                    "numpy": "numpy", "pandas": "pandas", "pycountry": "pycountry",
                    "requests": "requests", "shapely": "shapely"}
    missing = [package for module, package in dependencies.items()
               if importlib.util.find_spec(module) is None]
    if missing:
        subprocess.run([sys.executable, "-m", "pip", "install", *missing],
                       check=True, stdout=sys.stderr, stderr=sys.stderr, timeout=1800)


def update_calculator():
    """Instalar la ultima revision de main si falta o ha cambiado."""
    if sys.platform == "win32":
        raise RuntimeError("El catalogo oficial requiere fcntl; ejecuta R y Python en Linux o WSL")
    repository = "https://github.com/ferag/fair-eva-plugin-gbif"
    try:
        remote = subprocess.run(
            ["git", "ls-remote", repository, "refs/heads/main"],
            check=True, capture_output=True, text=True, timeout=120)
        latest = remote.stdout.split()[0] if remote.stdout.split() else ""
        if not re.fullmatch(r"[0-9a-f]{40}", latest):
            raise RuntimeError("No se pudo identificar la ultima revision del plugin")
        try:
            current = installed_commit()
        except PackageNotFoundError:
            current = None
        if current != latest:
            subprocess.run(
                [sys.executable, "-m", "pip", "install", "--upgrade",
                 "--force-reinstall", "--no-deps",
                 f"fair-eva-plugin-gbif @ git+{repository}@{latest}"],
                check=True, stdout=sys.stderr, stderr=sys.stderr, timeout=3300)
    except (OSError, subprocess.SubprocessError) as error:
        raise RuntimeError("No se pudo actualizar el plugin desde main: " + str(error)) from error


def load_calculator():
    # quality necesita contexto de paquete para resolver .catalogue sin FAIR EVA.
    if sys.platform == "win32":
        raise RuntimeError("El catalogo oficial requiere fcntl; ejecuta R y Python en Linux o WSL")
    package = distribution("fair-eva-plugin-gbif")
    path = Path(package.locate_file("fair_eva/plugin/gbif/quality.py"))
    if not path.is_file():
        raise RuntimeError("Falta quality.py; actualiza el plugin desde main segun la documentacion")
    spec = importlib.util.spec_from_file_location(
        "metages_gbif_quality", path, submodule_search_locations=[str(path.parent)])
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    if not module.SHP_PATH.is_file():
        raise RuntimeError("Missing plugin country boundaries")
    return module


def installed_commit():
    """Identificar el commit instalado solo para comprobar actualizaciones."""
    package = distribution("fair-eva-plugin-gbif")
    origin = json.loads(package.read_text("direct_url.json") or "{}")
    return origin.get("vcs_info", {}).get("commit_id")


def truncate_component(value):
    """Truncar a cuatro decimales o hasta el primero distinto de cero."""
    number = Decimal(str(value))
    if not number.is_finite():
        raise ValueError("El calculador devolvio un componente no finito")
    with localcontext() as context:
        context.prec = max(28, len(number.as_tuple().digits) + abs(number.adjusted()) + 5)
        fraction = abs(number) % 1
        places = -fraction.adjusted() if fraction and fraction < Decimal("0.0001") else 4
        return float(number.quantize(Decimal(1).scaleb(-places), rounding=ROUND_DOWN))


def archive_url(url):
    parts = urlsplit(url)
    if parts.scheme not in ("http", "https") or not parts.netloc:
        raise ValueError("url_ipt must be an HTTP(S) URL")
    is_ipt = ("ipt" in (parts.hostname or "").lower().split(".") or
              "ipt" in parts.path.lower().split("/"))
    if not is_ipt:
        return url
    path = parts.path.rstrip("/")
    parent, separator, endpoint = path.rpartition("/")
    if endpoint not in ("resource", "resource.do"):
        return url
    trailing_slashes = parts.path[len(path):]
    archive_endpoint = endpoint.replace("resource", "archive", 1)
    archive_path = parent + separator + archive_endpoint + trailing_slashes
    return urlunsplit(parts._replace(path=archive_path))


def calculate(module, url):
    import requests
    with tempfile.TemporaryDirectory(prefix="metages-ica-") as folder:
        archive = Path(folder) / "archive.zip"
        with requests.get(archive_url(url), stream=True, timeout=(30, 120)) as response:
            response.raise_for_status()
            with archive.open("wb") as output:
                for chunk in response.iter_content(chunk_size=1024 * 1024):
                    output.write(chunk)
        scores = module.ICA(
            str(archive),
            catalogue_dir=os.environ.get("METAGES_ICA_CATALOGUE_DIR") or None)
    result = {target: float(scores[source]) for target, source in
              {"ICA": "ICA", "Icat": "Taxonomic", "Icag": "Geographic",
               "Icad": "Temporal"}.items()}
    if not all(math.isfinite(value) for value in result.values()):
        raise ValueError("ICA returned non-finite scores")
    for field in ("ICA", "Icat", "Icag", "Icad"):
        result[field] = truncate_component(result[field])
    result["fecha_validacion"] = datetime.date.today().isoformat()
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--update", action="store_true")
    parser.add_argument("--prepare", action="store_true")
    args = parser.parse_args()
    logging.basicConfig(stream=sys.stderr, level=logging.WARNING)
    try:
        if args.prepare:
            result = prepare_environment()
            print(json.dumps(result, allow_nan=False))
            return 0
        with contextlib.redirect_stdout(sys.stderr):
            if args.update:
                if sys.platform == "win32":
                    raise RuntimeError("El catalogo oficial requiere fcntl; ejecuta R y Python en Linux o WSL")
                ensure_dependencies()
                update_calculator()
            module = load_calculator()
            result = {"ready": True,
                      "python_executable": sys.executable} if args.check or args.update else calculate(
                module, json.load(sys.stdin)["url_ipt"])
        print(json.dumps(result, allow_nan=False))
        return 0
    except Exception as error:
        detail = str(error)
        if isinstance(error, subprocess.CalledProcessError):
            detail += "\n" + (error.stderr or "") + (error.stdout or "")
        print(json.dumps({"error": detail}))
        return 1


if __name__ == "__main__":
    sys.exit(main())
