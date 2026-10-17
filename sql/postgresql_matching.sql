-- ============================================================
-- SneakerPark MDM Hub — Matching Rules SQL Scripts
-- Retail marketplace matching design
-- Author: Feras Elghandour
-- Description: Deterministic matching rules to link records
--              across source systems and generate Golden Records
-- ============================================================

-- ============================================================
-- CUSTOMER MATCHING RULES
-- Systems: usr.users <-> cs.CustomerServiceRequests
-- ============================================================

-- ------------------------------------------------------------
-- Rule 1: Exact Email Match (HIGH Confidence)
-- Normalized email identifies candidate links; shared or reassigned
-- addresses require review. Empty addresses are never candidates.
-- ------------------------------------------------------------
SELECT
    u.UserID          AS master_user_id,
    c.ID              AS csr_ticket_id,
    u.Email           AS matched_email,
    u.FirstName       AS first_name,
    u.LastName        AS last_name,
    'EXACT_EMAIL'     AS match_rule,
    'HIGH'            AS confidence
FROM usr.users u
INNER JOIN cs.CustomerServiceRequests c
    ON NULLIF(LOWER(TRIM(u.Email)), '') = NULLIF(LOWER(TRIM(c.Email)), '');


-- ------------------------------------------------------------
-- Rule 2: Exact Full Name Match (MEDIUM Confidence)
-- Rationale: Used as a fallback when email is NULL or empty in
-- the Customer Service Request. Matches on both FirstName AND
-- LastName (case-insensitive). Note: In production, combine
-- with ZipCode or OrderID to reduce false positives from
-- common names.
-- ------------------------------------------------------------
SELECT
    u.UserID          AS master_user_id,
    c.ID              AS csr_ticket_id,
    u.FirstName       AS matched_first_name,
    u.LastName        AS matched_last_name,
    c.OrderID         AS related_order_id,
    'EXACT_NAME'      AS match_rule,
    'MEDIUM'          AS confidence
FROM usr.users u
INNER JOIN cs.CustomerServiceRequests c
    ON  LOWER(TRIM(u.FirstName)) = LOWER(TRIM(c.FirstName))
    AND LOWER(TRIM(u.LastName))  = LOWER(TRIM(c.LastName))
WHERE c.Email IS NULL
   OR TRIM(c.Email) = '';


-- ============================================================
-- ITEM MATCHING RULES
-- Systems: li.listings <-> im.Items
-- ============================================================

-- ------------------------------------------------------------
-- Rule 3: Exact Seller + Physical Attributes Match (HIGH Confidence)
-- Rationale: A pair of sneakers in the warehouse (im.Items) and
-- a listing (li.listings) may match on seller and attributes.
-- Identical pairs can exist, so these are candidates, not unique
-- physical identities or permission to merge records automatically.
-- Note: This rule bridges the attribute naming inconsistency
-- between the two systems (Brand vs BrandName, Gender vs Sex).
-- ------------------------------------------------------------
SELECT
    l.ListingID             AS listing_id,
    i.ItemID                AS item_id,
    l.SellerID              AS seller_id,
    l.Brand                 AS brand,
    l.Size                  AS size,
    l.Color                 AS color,
    l.Condition             AS condition,
    l.ListingCreateDate     AS listing_create_date,
    i.ArrivalDate           AS item_arrival_date,
    'EXACT_ATTRIBUTES'      AS match_rule,
    'HIGH'                  AS confidence
FROM li.listings l
INNER JOIN im.Items i
    ON  l.SellerID               = i.SellerID
    AND LOWER(TRIM(l.Brand))     = LOWER(TRIM(i.BrandName))
    AND LOWER(TRIM(l.Size))      = LOWER(TRIM(i.Size))
    AND LOWER(TRIM(l.Color))     = LOWER(TRIM(i.Color))
    AND LOWER(TRIM(l.Condition)) = LOWER(TRIM(i.Condition));


-- ------------------------------------------------------------
-- Rule 4: Seller + Shoe Type + Gender + Temporal Proximity (MEDIUM Confidence)
-- Rationale: A Listing created within the 45-day window after
-- a warehouse Item's arrival, from the same Seller, with
-- matching Shoe Type and Gender, is very likely the same item.
-- The 45-day window aligns with SneakerPark's policy: items
-- not listed within 45 days are returned to the seller.
-- This rule catches cases where Color or Condition was entered
-- differently across the two systems.
-- ------------------------------------------------------------
SELECT
    l.ListingID             AS listing_id,
    i.ItemID                AS item_id,
    l.SellerID              AS seller_id,
    l.ShoeType              AS shoe_type,
    l.Gender                AS gender,
    i.ArrivalDate           AS arrival_date,
    l.ListingCreateDate     AS listing_create_date,
    (l.ListingCreateDate - i.ArrivalDate) AS days_after_arrival,
    'TEMPORAL_TYPE'         AS match_rule,
    'MEDIUM'                AS confidence
FROM li.listings l
INNER JOIN im.Items i
    ON  l.SellerID                 = i.SellerID
    AND LOWER(TRIM(l.ShoeType))    = LOWER(TRIM(i.Type))
    AND LOWER(TRIM(l.Gender))      = LOWER(TRIM(i.Sex))
    AND l.ListingCreateDate       >= i.ArrivalDate
    AND l.ListingCreateDate       <= i.ArrivalDate + INTERVAL '45 days';


-- ============================================================
-- COMBINED MATCH VIEW: All matches with confidence ranking
-- Use this view to populate the MDM Hub's match candidate table
-- ============================================================
CREATE OR REPLACE VIEW mdm.customer_match_candidates AS
    -- Rule 1
    SELECT u.UserID AS master_user_id, c.ID AS csr_ticket_id,
           'EXACT_EMAIL' AS match_rule, 1 AS priority
    FROM usr.users u
    INNER JOIN cs.CustomerServiceRequests c
        ON NULLIF(LOWER(TRIM(u.Email)), '') = NULLIF(LOWER(TRIM(c.Email)), '')
    UNION ALL
    -- Rule 2
    SELECT u.UserID, c.ID,
           'EXACT_NAME', 2
    FROM usr.users u
    INNER JOIN cs.CustomerServiceRequests c
        ON  LOWER(TRIM(u.FirstName)) = LOWER(TRIM(c.FirstName))
        AND LOWER(TRIM(u.LastName))  = LOWER(TRIM(c.LastName))
    WHERE c.Email IS NULL OR TRIM(c.Email) = '';

CREATE OR REPLACE VIEW mdm.item_match_candidates AS
    -- Rule 3
    SELECT l.ListingID, i.ItemID,
           'EXACT_ATTRIBUTES' AS match_rule, 1 AS priority
    FROM li.listings l
    INNER JOIN im.Items i
        ON  l.SellerID               = i.SellerID
        AND LOWER(TRIM(l.Brand))     = LOWER(TRIM(i.BrandName))
        AND LOWER(TRIM(l.Size))      = LOWER(TRIM(i.Size))
        AND LOWER(TRIM(l.Color))     = LOWER(TRIM(i.Color))
        AND LOWER(TRIM(l.Condition)) = LOWER(TRIM(i.Condition))
    UNION ALL
    -- Rule 4
    SELECT l.ListingID, i.ItemID,
           'TEMPORAL_TYPE', 2
    FROM li.listings l
    INNER JOIN im.Items i
        ON  l.SellerID              = i.SellerID
        AND LOWER(TRIM(l.ShoeType)) = LOWER(TRIM(i.Type))
        AND LOWER(TRIM(l.Gender))   = LOWER(TRIM(i.Sex))
        AND l.ListingCreateDate    >= i.ArrivalDate
        AND l.ListingCreateDate    <= i.ArrivalDate + INTERVAL '45 days';
