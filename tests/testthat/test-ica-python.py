"""Offline adapter tests; run with the configured ICA Python environment."""
import importlib.util
import io
import json
import math
import tempfile
import unittest
import zipfile
from pathlib import Path
from unittest.mock import patch

path = Path(__file__).resolve().parents[2] / "inst/python/ica_runner.py"
spec = importlib.util.spec_from_file_location("ica_runner", path)
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)


class AdapterTests(unittest.TestCase):
    def test_ipt_archive(self):
        self.assertEqual(runner.archive_url("https://ipt.example/ipt/resource.do?r=a&v=2"),
                         "https://ipt.example/ipt/archive.do?r=a")
        with self.assertRaises(ValueError):
            runner.archive_url("https://ipt.example/")

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
