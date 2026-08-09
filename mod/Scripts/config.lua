local Config = {}

-- The executor still refuses to run unless a Feed Box actor reports server
-- authority. Clients may keep the mod installed without submitting moves.
Config.ENABLE_TRANSFERS = true

-- Submit only one request per pass, then re-read replicated state. This avoids
-- building a batch from stale slot contents while remaining fast enough to
-- converge after a base is loaded.
Config.BALANCE_INTERVAL_MS = 5000
Config.MAX_ITEMS_PER_REQUEST = 500
Config.FULL_DISCOVERY_EVERY_PASSES = 12
Config.READINESS_PASSES = 8
Config.ROUTE_COOLDOWN_PASSES = 12

-- Include the refrigerated late-game Feed Box as another vanilla feed box.
Config.INCLUDE_COOLED_FEED_BOX = true

return Config
