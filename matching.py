"""Execute candidate rules against in-memory, synthetic source-system tables."""
import sqlite3
from pathlib import Path

def database():
    con=sqlite3.connect(':memory:')
    for schema in ['usr','cs','li','im']:
        con.execute(f"ATTACH DATABASE ':memory:' AS {schema}")
    con.executescript("""
      CREATE TABLE usr.users(UserID INTEGER,Email TEXT,FirstName TEXT,LastName TEXT);
      CREATE TABLE cs.CustomerServiceRequests(ID INTEGER,Email TEXT,FirstName TEXT,LastName TEXT,OrderID INTEGER);
      CREATE TABLE li.listings(ListingID INTEGER,SellerID INTEGER,Brand TEXT,Size TEXT,Color TEXT,Condition TEXT,ListingCreateDate TEXT,ShoeType TEXT,Gender TEXT);
      CREATE TABLE im.Items(ItemID INTEGER,SellerID INTEGER,BrandName TEXT,Size TEXT,Color TEXT,Condition TEXT,ArrivalDate TEXT,Type TEXT,Sex TEXT);
    """)
    return con

def candidates(con,rule):
    sql=(Path(__file__).parent/'sql/sqlite_matching.sql').read_text().split(';')
    if type(rule) is not int or not 1<=rule<=4:raise ValueError('Rule must be 1..4')
    return con.execute(sql[rule-1]).fetchall()
