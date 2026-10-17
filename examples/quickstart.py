"""Offline example using the public implementation; see README for evidence scope."""
import sys
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "src"))
os.chdir(ROOT)

from matching import database,candidates
con=database()
con.execute("INSERT INTO usr.users VALUES(1,' A@EXAMPLE.INVALID ','A','B')")
con.execute("INSERT INTO cs.CustomerServiceRequests VALUES(2,'a@example.invalid','A','B',3)")
print({'rule_1_candidates':candidates(con,1)})
con.close()
