import unittest
from matching import database,candidates

class MatchingTests(unittest.TestCase):
    def setUp(self):self.db=database()
    def tearDown(self):self.db.close()
    def test_email_normalization(self):
        self.db.execute("INSERT INTO usr.users VALUES(1,' A@EXAMPLE.INVALID ','A','B')")
        self.db.execute("INSERT INTO cs.CustomerServiceRequests VALUES(2,'a@example.invalid','A','B',3)")
        self.assertEqual(len(candidates(self.db,1)),1)
    def test_blank_email_is_not_identity(self):
        self.db.execute("INSERT INTO usr.users VALUES(1,' ','A','B')")
        self.db.execute("INSERT INTO cs.CustomerServiceRequests VALUES(2,'','A','B',3)")
        self.assertEqual(candidates(self.db,1),[])
    def test_shared_email_retains_ambiguity(self):
        self.db.executemany("INSERT INTO usr.users VALUES(?, 'shared@example.invalid','A','B')",[(1,),(2,)])
        self.db.execute("INSERT INTO cs.CustomerServiceRequests VALUES(2,'shared@example.invalid','A','B',3)")
        self.assertEqual(len(candidates(self.db,1)),2)
    def test_name_fallback_requires_missing_email(self):
        self.db.execute("INSERT INTO usr.users VALUES(1,'a@example.invalid','A','B')")
        self.db.execute("INSERT INTO cs.CustomerServiceRequests VALUES(2,NULL,'A','B',3)")
        self.assertEqual(len(candidates(self.db,2)),1)
        self.db.execute("UPDATE cs.CustomerServiceRequests SET Email='different@example.invalid'")
        self.assertEqual(candidates(self.db,2),[])
    def test_attribute_candidates_and_temporal_boundary(self):
        self.db.execute("INSERT INTO im.Items VALUES(1,2,'Sample','10','Blue','New','2026-01-01','Running','U')")
        self.db.execute("INSERT INTO li.listings VALUES(3,2,'sample','10','blue','new','2026-02-15','Running','U')")
        self.assertEqual(len(candidates(self.db,3)),1)
        self.assertEqual(len(candidates(self.db,4)),1)
        self.db.execute("UPDATE li.listings SET ListingCreateDate='2026-02-16'")
        self.assertEqual(candidates(self.db,4),[])

if __name__=='__main__':unittest.main()
