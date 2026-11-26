import unittest

from text import slugify


class T(unittest.TestCase):
    def test_basic(self): self.assertEqual(slugify("Hello, World!"), "hello-world")
    def test_runs(self): self.assertEqual(slugify("a  --  b"), "a-b")
    def test_edges(self): self.assertEqual(slugify("--Fortran 2023--"), "fortran-2023")
    def test_unicode(self): self.assertEqual(slugify("perché sì"), "perch-s")
    def test_empty(self): self.assertEqual(slugify("!!!"), "")


if __name__ == "__main__":
    unittest.main()
