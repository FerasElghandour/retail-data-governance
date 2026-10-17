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

SELECT
    l.ListingID             AS listing_id,
    i.ItemID                AS item_id,
    l.SellerID              AS seller_id,
    l.ShoeType              AS shoe_type,
    l.Gender                AS gender,
    i.ArrivalDate           AS arrival_date,
    l.ListingCreateDate     AS listing_create_date,
    (julianday(l.ListingCreateDate) - julianday(i.ArrivalDate)) AS days_after_arrival,
    'TEMPORAL_TYPE'         AS match_rule,
    'MEDIUM'                AS confidence
FROM li.listings l
INNER JOIN im.Items i
    ON  l.SellerID                 = i.SellerID
    AND LOWER(TRIM(l.ShoeType))    = LOWER(TRIM(i.Type))
    AND LOWER(TRIM(l.Gender))      = LOWER(TRIM(i.Sex))
    AND l.ListingCreateDate       >= i.ArrivalDate
    AND l.ListingCreateDate       <= date(i.ArrivalDate, '+45 days');
