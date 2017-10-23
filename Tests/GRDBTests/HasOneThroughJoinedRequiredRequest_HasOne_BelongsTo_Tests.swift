import XCTest
#if GRDBCIPHER
    import GRDBCipher
#elseif GRDBCUSTOMSQLITE
    import GRDBCustomSQLite
#else
    import GRDB
#endif

private typealias Country = HasOneThrough_HasOne_BelongsTo_Fixture.Country
private typealias CountryProfile = HasOneThrough_HasOne_BelongsTo_Fixture.CountryProfile
private typealias Continent = HasOneThrough_HasOne_BelongsTo_Fixture.Continent

class HasOneThroughJoinedRequiredRequest_HasOne_BelongsTo_Tests: GRDBTestCase {
    
    func testSimplestRequest() throws {
        let dbQueue = try makeDatabaseQueue()
        try HasOneThrough_HasOne_BelongsTo_Fixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            let graph = try Country
                .joining(required: Country.continent)
                .fetchAll(db)
            
            assertEqualSQL(lastSQLQuery, """
                SELECT "countries".* \
                FROM "countries" \
                JOIN "countryProfiles" ON ("countryProfiles"."countryCode" = "countries"."code") \
                JOIN "continents" ON ("continents"."id" = "countryProfiles"."continentId")
                """)
            
            assertMatch(graph, [
                ["code": "FR", "name": "France"],
                ["code": "DE", "name": "Germany"],
                ["code": "US", "name": "United States"],
                ])
        }
    }
    
    func testLeftRequestDerivation() throws {
        let dbQueue = try makeDatabaseQueue()
        try HasOneThrough_HasOne_BelongsTo_Fixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                // filter before
                let graph = try Country
                    .filter(Column("code") != "DE")
                    .joining(required: Country.continent)
                    .fetchAll(db)
                
                assertEqualSQL(lastSQLQuery, """
                    SELECT "countries".* \
                    FROM "countries" \
                    JOIN "countryProfiles" ON ("countryProfiles"."countryCode" = "countries"."code") \
                    JOIN "continents" ON ("continents"."id" = "countryProfiles"."continentId") \
                    WHERE ("countries"."code" <> 'DE')
                    """)
                
                assertMatch(graph, [
                    ["code": "FR", "name": "France"],
                    ["code": "US", "name": "United States"],
                    ])
            }
            
            do {
                // filter after
                let graph = try Country
                    .joining(required: Country.continent)
                    .filter(Column("code") != "DE")
                    .fetchAll(db)
                
                assertEqualSQL(lastSQLQuery, """
                    SELECT "countries".* \
                    FROM "countries" \
                    JOIN "countryProfiles" ON ("countryProfiles"."countryCode" = "countries"."code") \
                    JOIN "continents" ON ("continents"."id" = "countryProfiles"."continentId") \
                    WHERE ("countries"."code" <> 'DE')
                    """)
                
                assertMatch(graph, [
                    ["code": "FR", "name": "France"],
                    ["code": "US", "name": "United States"],
                    ])
            }
            
            do {
                // order before
                let graph = try Country
                    .order(Column("name").desc)
                    .joining(required: Country.continent)
                    .fetchAll(db)
                
                assertEqualSQL(lastSQLQuery, """
                    SELECT "countries".* \
                    FROM "countries" \
                    JOIN "countryProfiles" ON ("countryProfiles"."countryCode" = "countries"."code") \
                    JOIN "continents" ON ("continents"."id" = "countryProfiles"."continentId") \
                    ORDER BY "countries"."name" DESC
                    """)
                
                assertMatch(graph, [
                    ["code": "US", "name": "United States"],
                    ["code": "DE", "name": "Germany"],
                    ["code": "FR", "name": "France"],
                    ])
            }
            
            do {
                // order after
                let graph = try Country
                    .joining(required: Country.continent)
                    .order(Column("name").desc)
                    .fetchAll(db)
                
                assertEqualSQL(lastSQLQuery, """
                    SELECT "countries".* \
                    FROM "countries" \
                    JOIN "countryProfiles" ON ("countryProfiles"."countryCode" = "countries"."code") \
                    JOIN "continents" ON ("continents"."id" = "countryProfiles"."continentId") \
                    ORDER BY "countries"."name" DESC
                    """)
                
                assertMatch(graph, [
                    ["code": "US", "name": "United States"],
                    ["code": "DE", "name": "Germany"],
                    ["code": "FR", "name": "France"],
                    ])
            }
        }
    }
    
    func testMiddleRequestDerivation() throws {
        let dbQueue = try makeDatabaseQueue()
        try HasOneThrough_HasOne_BelongsTo_Fixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                let middleAssociation = Country.profile.filter(Column("currency") != "EUR")
                let association = Country.hasOne(CountryProfile.continent, through: middleAssociation)
                let graph = try Country
                    .joining(required: association)
                    .fetchAll(db)
                
                assertEqualSQL(lastSQLQuery, """
                    SELECT "countries".* \
                    FROM "countries" \
                    JOIN "countryProfiles" ON (("countryProfiles"."countryCode" = "countries"."code") AND ("countryProfiles"."currency" <> 'EUR')) \
                    JOIN "continents" ON ("continents"."id" = "countryProfiles"."continentId")
                    """)
                
                // TODO: is it expected to have countries whose currency is Euro here?
                // TODO: how to get countries whose currency is not Euro?
                assertMatch(graph, [
                    ["code": "US", "name": "United States"],
                    ])
            }
            
            do {
                // TODO: is it expected that order is not respected here?
                // Possible answer: ordering should be forbidden on associations, and always performed at the end of the full query.
                let middleAssociation = Country.profile.order(Column("currency").desc)
                let association = Country.hasOne(CountryProfile.continent, through: middleAssociation)
                let graph = try Country
                    .joining(required: association)
                    .fetchAll(db)
                
                assertEqualSQL(lastSQLQuery, """
                    SELECT "countries".* \
                    FROM "countries" \
                    JOIN "countryProfiles" ON ("countryProfiles"."countryCode" = "countries"."code") \
                    JOIN "continents" ON ("continents"."id" = "countryProfiles"."continentId")
                    """)
                
                assertMatch(graph, [
                    ["code": "FR", "name": "France"],
                    ["code": "DE", "name": "Germany"],
                    ["code": "US", "name": "United States"],
                    ])
            }
        }
    }
    
    func testRightRequestDerivation() throws {
        let dbQueue = try makeDatabaseQueue()
        try HasOneThrough_HasOne_BelongsTo_Fixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                let graph = try Country
                    .joining(required: Country.continent.filter(Column("name") != "America"))
                    .fetchAll(db)
                
                assertEqualSQL(lastSQLQuery, """
                    SELECT "countries".* \
                    FROM "countries" \
                    JOIN "countryProfiles" ON ("countryProfiles"."countryCode" = "countries"."code") \
                    JOIN "continents" ON (("continents"."id" = "countryProfiles"."continentId") AND ("continents"."name" <> 'America'))
                    """)
                
                // TODO: is it expected to have countries whose continent is America here?
                // TODO: how to get countries whose continent is not America?
                assertMatch(graph, [
                    ["code": "FR", "name": "France"],
                    ["code": "DE", "name": "Germany"],
                    ])
            }
            
            do {
                let graph = try Country
                    .joining(required: Country.continent.order(Column("name")))
                    .fetchAll(db)
                
                assertEqualSQL(lastSQLQuery, """
                    SELECT "countries".* \
                    FROM "countries" \
                    JOIN "countryProfiles" ON ("countryProfiles"."countryCode" = "countries"."code") \
                    JOIN "continents" ON ("continents"."id" = "countryProfiles"."continentId")
                    """)
                
                assertMatch(graph, [
                    ["code": "FR", "name": "France"],
                    ["code": "DE", "name": "Germany"],
                    ["code": "US", "name": "United States"],
                    ])
            }
        }
    }
    
    func testRecursion() throws {
        struct Person : TableMapping {
            static let databaseTableName = "persons"
        }
        
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            try db.create(table: "persons") { t in
                t.column("id", .integer).primaryKey()
                t.column("parentId", .integer).references("persons")
                t.column("childId", .integer).references("persons")
            }
        }
        
        try dbQueue.inDatabase { db in
            do {
                let middleAssociation = Person.hasOne(Person.self, using: ForeignKey([Column("childId")]))
                let rightAssociation = Person.belongsTo(Person.self, using: ForeignKey([Column("parentId")]))
                let association = Person.hasOne(rightAssociation, through: middleAssociation)
                let request = Person.joining(required: association)
                try assertEqualSQL(db, request, """
                    SELECT "persons1".* \
                    FROM "persons" "persons1" \
                    JOIN "persons" "persons2" ON ("persons2"."childId" = "persons1"."id") \
                    JOIN "persons" "persons3" ON ("persons3"."id" = "persons2"."parentId")
                    """)
            }
        }
    }
    
    func testLeftAlias() throws {
        let dbQueue = try makeDatabaseQueue()
        try HasOneThrough_HasOne_BelongsTo_Fixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                // alias first
                let countryRef = TableReference(alias: "c")
                let request = Country.all()
                    .referenced(by: countryRef)
                    .filter(Column("code") != "DE")
                    .joining(required: Country.continent)
                try assertEqualSQL(db, request, """
                    SELECT "c".* \
                    FROM "countries" "c" \
                    JOIN "countryProfiles" ON ("countryProfiles"."countryCode" = "c"."code") \
                    JOIN "continents" ON ("continents"."id" = "countryProfiles"."continentId") \
                    WHERE ("c"."code" <> 'DE')
                    """)
            }
            
            do {
                // alias last
                let countryRef = TableReference(alias: "c")
                let request = Country
                    .filter(Column("code") != "DE")
                    .joining(required: Country.continent)
                    .referenced(by: countryRef)
                try assertEqualSQL(db, request, """
                    SELECT "c".* \
                    FROM "countries" "c" \
                    JOIN "countryProfiles" ON ("countryProfiles"."countryCode" = "c"."code") \
                    JOIN "continents" ON ("continents"."id" = "countryProfiles"."continentId") \
                    WHERE ("c"."code" <> 'DE')
                    """)
            }
            
            do {
                // alias with table name (TODO: port this test to all testLeftAlias() tests)
                let countryRef = TableReference(alias: "countries")
                let request = Country.all()
                    .referenced(by: countryRef)
                    .joining(required: Country.continent)
                try assertEqualSQL(db, request, """
                    SELECT "countries".* \
                    FROM "countries" \
                    JOIN "countryProfiles" ON ("countryProfiles"."countryCode" = "countries"."code") \
                    JOIN "continents" ON ("continents"."id" = "countryProfiles"."continentId")
                    """)
            }
        }
    }
    
    func testMiddleAlias() throws {
        let dbQueue = try makeDatabaseQueue()
        try HasOneThrough_HasOne_BelongsTo_Fixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                let profileRef = TableReference(alias: "a")
                let association = Country.hasOne(CountryProfile.continent, through: Country.profile.referenced(by: profileRef))
                let request = Country.joining(required: association)
                try assertEqualSQL(db, request, """
                    SELECT "countries".* \
                    FROM "countries" \
                    JOIN "countryProfiles" "a" ON ("a"."countryCode" = "countries"."code") \
                    JOIN "continents" ON ("continents"."id" = "a"."continentId")
                    """)
            }
            do {
                // alias with table name
                let profileRef = TableReference(alias: "countryProfiles")
                let association = Country.hasOne(CountryProfile.continent, through: Country.profile.referenced(by: profileRef))
                let request = Country.joining(required: association)
                try assertEqualSQL(db, request, """
                    SELECT "countries".* \
                    FROM "countries" \
                    JOIN "countryProfiles" ON ("countryProfiles"."countryCode" = "countries"."code") \
                    JOIN "continents" ON ("continents"."id" = "countryProfiles"."continentId")
                    """)
            }
        }
    }
    
    func testRightAlias() throws {
        let dbQueue = try makeDatabaseQueue()
        try HasOneThrough_HasOne_BelongsTo_Fixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                // alias first
                let continentRef = TableReference(alias: "a")
                let request = Country
                    .joining(required: Country.continent
                        .referenced(by: continentRef)
                        .filter(Column("name") != "America"))
                    .order(continentRef[Column("name")])
                try assertEqualSQL(db, request, """
                    SELECT "countries".* \
                    FROM "countries" \
                    JOIN "countryProfiles" ON ("countryProfiles"."countryCode" = "countries"."code") \
                    JOIN "continents" "a" ON (("a"."id" = "countryProfiles"."continentId") AND ("a"."name" <> 'America')) \
                    ORDER BY "a"."name"
                    """)
            }
            
            do {
                // alias last
                let continentRef = TableReference(alias: "a")
                let request = Country
                    .joining(required: Country.continent
                        .order(Column("name"))
                        .referenced(by: continentRef))
                    .filter(continentRef[Column("name")] != "America")
                try assertEqualSQL(db, request, """
                    SELECT "countries".* \
                    FROM "countries" \
                    JOIN "countryProfiles" ON ("countryProfiles"."countryCode" = "countries"."code") \
                    JOIN "continents" "a" ON ("a"."id" = "countryProfiles"."continentId") \
                    WHERE ("a"."name" <> 'America')
                    """)
            }
            
            do {
                // alias with table name (TODO: port this test to all testRightAlias() tests)
                let continentRef = TableReference(alias: "continents")
                let request = Country.joining(required: Country.continent.referenced(by: continentRef))
                try assertEqualSQL(db, request, """
                    SELECT "countries".* \
                    FROM "countries" \
                    JOIN "countryProfiles" ON ("countryProfiles"."countryCode" = "countries"."code") \
                    JOIN "continents" ON ("continents"."id" = "countryProfiles"."continentId")
                    """)
            }
            
        }
    }
    
    func testLockedAlias() throws {
        let dbQueue = try makeDatabaseQueue()
        try HasOneThrough_HasOne_BelongsTo_Fixture().migrator.migrate(dbQueue)
        
        try dbQueue.inDatabase { db in
            do {
                // alias left
                let countryRef = TableReference(alias: "CONTINENTS") // Create name conflict
                let request = Country.joining(required: Country.continent).referenced(by: countryRef)
                try assertEqualSQL(db, request, """
                    SELECT "CONTINENTS".* \
                    FROM "countries" "CONTINENTS" \
                    JOIN "countryProfiles" ON ("countryProfiles"."countryCode" = "CONTINENTS"."code") \
                    JOIN "continents" "continents1" ON ("continents1"."id" = "countryProfiles"."continentId")
                    """)
            }
            
            do {
                // alias right
                let continentRef = TableReference(alias: "COUNTRIES") // Create name conflict
                let request = Country.joining(required: Country.continent.referenced(by: continentRef))
                try assertEqualSQL(db, request, """
                    SELECT "countries1".* \
                    FROM "countries" "countries1" \
                    JOIN "countryProfiles" ON ("countryProfiles"."countryCode" = "countries1"."code") \
                    JOIN "continents" "COUNTRIES" ON ("COUNTRIES"."id" = "countryProfiles"."continentId")
                    """)
            }
        }
    }
}