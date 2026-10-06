"""Offline adapter tests; run with the configured ICA Python environment."""
import importlib.util
import io
import json
import math
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

    def test_resource_replacement_preserves_suffix_and_parameters(self):
        self.assertEqual(runner.archive_url(
            "https://resource.example/ipt/resource.custom?r=a%2Fb&token=x#details"),
            "https://resource.example/ipt/archive.custom?r=a%2Fb&token=x#details")
        self.assertEqual(runner.archive_url("https://ipt.example/download?r=resource"),
                         "https://ipt.example/download?r=resource")

    def test_direct_download_reaches_calculator(self):
        url = "https://data.example/download?token=a%2Fb"
        response = Mock()
        response.__enter__ = Mock(return_value=response)
        response.__exit__ = Mock(return_value=False)
        response.iter_content.return_value = [b"archive payload"]
        calculator = Mock()
        def calculate(path):
            self.assertEqual(Path(path).read_bytes(), b"archive payload")
            return {"ICA": 70, "Taxonomic": 35, "Geographic": 25, "Temporal": 10}
        calculator.ICA.side_effect = calculate
        with patch("requests.get", return_value=response) as download:
            result = runner.calculate(calculator, url)
        download.assert_called_once_with(url, stream=True, timeout=(30, 120))
        response.raise_for_status.assert_called_once()
        self.assertEqual(result["ICA"], 70)
        self.assertEqual(result["Icad"], 10)
        self.assertFalse(Path(calculator.ICA.call_args.args[0]).exists())

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
            class Response:
                def json(self):
                    return {"type": "EXACT"}
            with patch.object(module.requests, "get", return_value=Response()):
                scores = module.ICA(str(archive))
        self.assertTrue(all(math.isfinite(float(scores[k])) for k in
                            ("ICA", "Taxonomic", "Geographic", "Temporal")))
        self.assertAlmostEqual(scores["ICA"], scores["Taxonomic"] +
                               scores["Geographic"] + scores["Temporal"])


if __name__ == "__main__":
    unittest.main()
