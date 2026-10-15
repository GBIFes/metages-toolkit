"""Pruebas del adaptador; ejecutar con el entorno Python de ICA."""
import importlib.util
import io
import json
import math
import os
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path
from unittest.mock import Mock, patch

path = Path(__file__).resolve().parents[2] / "inst/python/ica_runner.py"
spec = importlib.util.spec_from_file_location("ica_runner", path)
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)


class AdapterTests(unittest.TestCase):
    def test_venv_created_only_when_missing(self):
        for exists in (True, False):
            with self.subTest(exists=exists), \
                    patch.object(runner.sys, "platform", "linux"), \
                    patch.object(runner.sys, "prefix", "/base"), \
                    patch.object(runner.sys, "base_prefix", "/base"), \
                    patch.dict(os.environ, METAGES_ICA_VENV="/home/user/ica venv"), \
                    patch.object(runner.importlib.util, "find_spec", return_value=Mock()), \
                    patch.object(runner.Path, "is_file", return_value=exists), \
                    patch.object(runner.subprocess, "run", return_value=Mock(
                        stdout='{"ready":true,"python_executable":"/home/user/ica venv/bin/python"}',
                        stderr="")) as run:
                result = runner.prepare_environment()
                self.assertTrue(result["ready"])
                self.assertEqual(run.call_count, 1 if exists else 2)
                self.assertEqual(run.call_args.args[0][0],
                                 str(runner.Path("/home/user/ica venv").resolve() / "bin/python"))
                if not exists:
                    self.assertEqual(run.call_args_list[0].args[0][1:3], ["-m", "venv"])

    def test_dependencies_installed_only_when_missing(self):
        with patch.object(runner.importlib.util, "find_spec", return_value=Mock()), \
                patch.object(runner.subprocess, "run") as run:
            runner.ensure_dependencies()
            run.assert_not_called()
        with patch.object(runner.importlib.util, "find_spec",
                          side_effect=lambda name: None if name == "dwca" else Mock()), \
                patch.object(runner.subprocess, "run") as run:
            runner.ensure_dependencies()
            self.assertEqual(run.call_args.args[0],
                             [sys.executable, "-m", "pip", "install", "python-dwca-reader"])

    def test_no_reinstallation_when_commit_matches(self):
        latest = "a" * 40
        with patch.object(runner.sys, "platform", "linux"), \
                patch.object(runner, "installed_commit", return_value=latest), \
                patch.object(runner.subprocess, "run", return_value=Mock(
                    stdout=latest + "\trefs/heads/main\n")) as run:
            runner.update_calculator()
        self.assertEqual(run.call_count, 1)
        self.assertEqual(run.call_args.args[0][0:2], ["git", "ls-remote"])

    def test_installation_only_for_changed_missing_or_unidentified_commit(self):
        latest = "b" * 40
        for current in ("a" * 40, None, runner.PackageNotFoundError("plugin")):
            with self.subTest(current=current), \
                    patch.object(runner.sys, "platform", "linux"), \
                    patch.object(runner, "installed_commit") as installed, \
                    patch.object(runner.subprocess, "run", return_value=Mock(
                        stdout=latest + "\trefs/heads/main\n")) as run:
                if isinstance(current, Exception):
                    installed.side_effect = current
                else:
                    installed.return_value = current
                runner.update_calculator()
                self.assertEqual(run.call_count, 2)
                command = run.call_args.args[0]
                self.assertEqual(command[:4], [sys.executable, "-m", "pip", "install"])
                self.assertTrue(command[-1].endswith("@" + latest))

    def test_failed_remote_check_does_not_install(self):
        with patch.object(runner.sys, "platform", "linux"), \
                patch.object(runner.subprocess, "run", side_effect=runner.subprocess.TimeoutExpired(
                    "git", 120)) as run:
            with self.assertRaisesRegex(RuntimeError, "No se pudo actualizar"):
                runner.update_calculator()
        self.assertEqual(run.call_count, 1)

    def test_relative_import_without_plugin_initializer(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            package = root / "fair_eva/plugin/gbif"
            (package / "static").mkdir(parents=True)
            (package / "static/ne_110m_admin_0_countries.shp").touch()
            (package / "__init__.py").write_text("raise RuntimeError('FAIR EVA')")
            (package / "catalogue.py").write_text("VALUE = 42")
            (package / "quality.py").write_text(
                "from pathlib import Path\nfrom .catalogue import VALUE\n"
                "SHP_PATH = Path(__file__).parent / 'static/ne_110m_admin_0_countries.shp'\n")
            installed = Mock()
            installed.locate_file.side_effect = lambda name: root / name
            with patch.object(runner, "distribution", return_value=installed), \
                    patch.object(runner.sys, "platform", "linux"), patch.dict(sys.modules):
                self.assertEqual(runner.load_calculator().VALUE, 42)

    def test_calculator_commit_from_installation(self):
        installed = Mock(version="0.1.0")
        installed.read_text.return_value = json.dumps({
            "url": "https://github.com/ferag/fair-eva-plugin-gbif",
            "vcs_info": {"commit_id": "abc123"}})
        with patch.object(runner, "distribution", return_value=installed):
            self.assertEqual(runner.installed_commit(), "abc123")
            installed.read_text.return_value = None
            self.assertIsNone(runner.installed_commit())

    def test_download_and_catalogue_errors_propagate(self):
        response = Mock()
        response.__enter__ = Mock(return_value=response)
        response.__exit__ = Mock(return_value=False)
        response.iter_content.return_value = [b"archive"]
        calculator = Mock()
        with patch("requests.get", return_value=response):
            response.raise_for_status.side_effect = RuntimeError("Descarga fallida")
            with self.assertRaisesRegex(RuntimeError, "Descarga fallida"):
                runner.calculate(calculator, "https://data.example/archive")
            calculator.ICA.assert_not_called()
            response.raise_for_status.side_effect = None
            calculator.ICA.side_effect = RuntimeError("Catalogo no disponible")
            with self.assertRaisesRegex(RuntimeError, "Catalogo no disponible"):
                runner.calculate(calculator, "https://data.example/archive")

    def test_truncation(self):
        for value, expected in ((12.345678, 12.3456), (0.000012345, 0.00001),
                                (12.0000567, 12.00005), (-12.345678, -12.3456),
                                (-0.000012345, -0.00001), (0, 0), (12, 12),
                                (0.0001, 0.0001), (1e-12, 1e-12)):
            with self.subTest(value=value):
                self.assertEqual(runner.truncate_component(value), expected)
        for value in (math.nan, math.inf, -math.inf):
            with self.assertRaises(ValueError):
                runner.truncate_component(value)

    @unittest.skipUnless(sys.platform == "win32", "Solo Windows nativo")
    def test_windows_reports_upstream_requirement(self):
        with self.assertRaisesRegex(RuntimeError, "fcntl"):
            runner.load_calculator()

    def test_ipt_archive(self):
        self.assertEqual(runner.archive_url("https://ipt.example/ipt/resource.do?r=a&v=2"),
                         "https://ipt.example/ipt/archive.do?r=a&v=2")
        self.assertEqual(runner.archive_url("https://ipt.example/ipt/resource.do"),
                         "https://ipt.example/ipt/archive.do")

    def test_direct_endpoints_are_preserved(self):
        for url in ("https://data.example/archive.zip",
                    "https://data.example/download?token=a%2Fb&r=resource&v=2",
                    "https://data.example/resource.zip?r=resource",
                    "https://ipt.example/ipt/archive.do?r=a&v=2"):
            self.assertEqual(runner.archive_url(url), url)
        for url in ("file:///archive.zip", "ftp://data.example/archive.zip", "invalid"):
            with self.assertRaises(ValueError):
                runner.archive_url(url)

    def test_extensionless_ipt_resource(self):
        for page, archive in (("resource", "archive"), ("resource.do", "archive.do")):
            for prefix in ("", "/ipt"):
                for suffix in ("", "/"):
                    url = f"https://ipt.gbif.es{prefix}/{page}{suffix}?r=bc-lichen-navas"
                    self.assertEqual(runner.archive_url(url),
                        f"https://ipt.gbif.es{prefix}/{archive}{suffix}?r=bc-lichen-navas")

    def test_resource_endpoint_preserves_parameters(self):
        self.assertEqual(runner.archive_url(
            "https://resource.example/ipt/resource.do?r=a%2Fb&token=x#details"),
            "https://resource.example/ipt/archive.do?r=a%2Fb&token=x#details")
        self.assertEqual(runner.archive_url("https://ipt.example/download?r=resource"),
                         "https://ipt.example/download?r=resource")

    def test_direct_files_under_ipt_are_preserved(self):
        for url in (
            "https://ipt.example/ipt/files/my-resource.zip",
            "https://ipt.example/ipt/resource.zip",
            "https://ipt.example/ipt/resource.custom",
            "https://ipt.example/ipt/resource/files/archive.zip",
            "https://data.example/ipt/files/my-resource.zip?r=resource",
        ):
            with self.subTest(url=url):
                self.assertEqual(runner.archive_url(url), url)

    def test_direct_download_reaches_calculator(self):
        url = "https://data.example/download?token=a%2Fb"
        response = Mock()
        response.__enter__ = Mock(return_value=response)
        response.__exit__ = Mock(return_value=False)
        response.iter_content.return_value = [b"archive payload"]
        calculator = Mock()
        def calculate(path, catalogue_dir=None):
            self.assertEqual(Path(path).read_bytes(), b"archive payload")
            self.assertEqual(catalogue_dir, "/catalogue")
            return {"ICA": 70.123456, "Taxonomic": 35.123456, "Geographic": 0.0000123,
                    "Temporal": -0.0000567, "Catalogue": {"version": "2026-09-01"}}
        calculator.ICA.side_effect = calculate
        with patch("requests.get", return_value=response) as download, \
                patch.dict(os.environ, METAGES_ICA_CATALOGUE_DIR="/catalogue"):
            result = runner.calculate(calculator, url)
        download.assert_called_once_with(url, stream=True, timeout=(30, 120))
        response.raise_for_status.assert_called_once()
        self.assertEqual(result["ICA"], 70.1234)
        self.assertEqual(result["Icat"], 35.1234)
        self.assertEqual(result["Icag"], 0.00001)
        self.assertEqual(result["Icad"], -0.00005)
        self.assertEqual(set(result), {"ICA", "Icat", "Icag", "Icad", "fecha_validacion"})
        self.assertFalse(Path(calculator.ICA.call_args.args[0]).exists())

    @unittest.skipUnless(os.environ.get("METAGES_ICA_INTEGRATION") == "1",
                         "Requiere Linux, plugin y catalogo local; activar METAGES_ICA_INTEGRATION=1")
    def test_original_calculator(self):
        module = runner.load_calculator()
        fields = ["genus", "specificEpithet", "higherClassification", "kingdom",
                  "class", "order", "family", "identifiedBy", "decimalLatitude",
                  "decimalLongitude", "countryCode", "coordinateUncertaintyInMeters",
                  "eventDate", "verbatimEventDate", "year", "month", "day"]
        values = ["Quercus", "ilex", "Plantae", "Plantae", "Magnoliopsida", "Fagales",
                  "Fagaceae", "Tester", "40", "-3", "ES", "10", "2020-06-15", "",
                  "2020", "6", "15"]
        xml = '<archive xmlns="http://rs.tdwg.org/dwc/text/"><core encoding="UTF-8" fieldsTerminatedBy="\\t" linesTerminatedBy="\\n" ignoreHeaderLines="1" rowType="http://rs.tdwg.org/dwc/terms/Occurrence"><files><location>occurrence.txt</location></files><id index="0"/>'
        xml += ''.join(f'<field index="{i + 1}" term="http://rs.tdwg.org/dwc/terms/{name}"/>'
                       for i, name in enumerate(fields)) + '</core></archive>'
        with tempfile.TemporaryDirectory() as folder:
            archive = Path(folder) / "fixture.zip"
            with zipfile.ZipFile(archive, "w") as output:
                output.writestr("meta.xml", xml)
                output.writestr("occurrence.txt", "\t".join(["id"] + fields) + "\n" +
                                "\t".join(["1"] + values) + "\n")
            scores = module.ICA(str(archive), catalogue_dir=os.environ.get("METAGES_ICA_CATALOGUE_DIR"))
        self.assertTrue(all(math.isfinite(float(scores[k])) for k in
                            ("ICA", "Taxonomic", "Geographic", "Temporal")))
        self.assertAlmostEqual(scores["ICA"], scores["Taxonomic"] +
                               scores["Geographic"] + scores["Temporal"])


if __name__ == "__main__":
    unittest.main()
