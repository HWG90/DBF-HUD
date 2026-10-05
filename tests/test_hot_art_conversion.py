from pathlib import Path
import importlib.util,tempfile,unittest
from PIL import Image
spec=importlib.util.spec_from_file_location('conversion',Path(__file__).resolve().parents[1]/'tools/convert_hot_panel_art.py')
conversion=importlib.util.module_from_spec(spec);spec.loader.exec_module(conversion)

class ConversionTests(unittest.TestCase):
 def test_immutable_publication_and_reuse(self):
  with tempfile.TemporaryDirectory() as temp:
   root=Path(temp)
   conversion.publish(root,[('art',1,1,b'abcd')]);old=(root/'manifest.tsv').read_bytes();first=old.decode().split('\t')[-1].strip()
   conversion.publish(root,[('art',1,1,b'efgh')]);second=(root/'manifest.tsv').read_text().split('\t')[-1].strip()
   self.assertNotEqual(first,second);self.assertEqual((root/first).read_bytes(),b'abcd')
   conversion.publish(root,[('art',1,1,b'abcd')]);self.assertEqual((root/'manifest.tsv').read_bytes(),old)
   self.assertEqual(len(list(root.glob('*.rgba'))),2)
 def test_bad_dimensions_leave_selection_unchanged(self):
  with tempfile.TemporaryDirectory() as temp:
   root=Path(temp);(root/'manifest.tsv').write_text('art\t1\t1\n');Image.new('RGBA',(2,1)).save(root/'art.png')
   old=(root/'manifest.tsv').read_bytes()
   with self.assertRaises(ValueError):conversion.convert(root)
   self.assertEqual((root/'manifest.tsv').read_bytes(),old)
 def test_partial_publish_does_not_switch_manifest(self):
  with tempfile.TemporaryDirectory() as temp:
   root=Path(temp);conversion.publish(root,[('art',1,1,b'abcd')]);old=(root/'manifest.tsv').read_bytes()
   atomic=conversion.atomic
   def fail_manifest(path,data):
    if path.name=='manifest.tsv':raise OSError('injected publish failure')
    atomic(path,data)
   conversion.atomic=fail_manifest
   try:
    with self.assertRaises(OSError):conversion.publish(root,[('art',1,1,b'efgh')])
   finally:conversion.atomic=atomic
   self.assertEqual((root/'manifest.tsv').read_bytes(),old)
 def test_legacy_and_versioned_inputs_preserve_alpha(self):
  with tempfile.TemporaryDirectory() as temp:
   root=Path(temp);(root/'manifest.tsv').write_text('art\t1\t1\n');Image.new('RGBA',(1,1),(2,3,4,125)).save(root/'art.png')
   conversion.convert(root);conversion.convert(root)
   filename=(root/'manifest.tsv').read_text().split('\t')[-1].strip()
   self.assertEqual((root/filename).read_bytes(),bytes([2,3,4,125]))

if __name__=='__main__':unittest.main()
