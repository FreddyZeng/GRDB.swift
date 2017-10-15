public struct HasManyAssociation<Left, Right> : Association where
    Left: TableMapping,
    Right: TableMapping
{
    // Association
    public typealias LeftAssociated = Left
    public typealias RightAssociated = Right
    
    let joinMappingRequest: JoinMappingRequest
    public let rightRequest: WrappedRequest
    
    public func mapping(_ db: Database) throws -> [(left: String, right: String)] {
        return try joinMappingRequest
            .fetchMapping(db)
            .map { (left: $0.destination, right: $0.origin) }
    }
}

extension HasManyAssociation : RequestDerivableWrapper {
    public typealias WrappedRequest = QueryInterfaceRequest<Right>
    
    public func mapRequest(_ transform: (WrappedRequest) -> WrappedRequest) -> HasManyAssociation {
        return HasManyAssociation(
            joinMappingRequest: joinMappingRequest,
            rightRequest: transform(self.rightRequest))
    }
}

extension TableMapping {
    public static func hasMany<Right>(
        _ right: Right.Type)
        -> HasManyAssociation<Self, Right>
        where Right: TableMapping
    {
        let joinMappingRequest = JoinMappingRequest(
            originTable: Right.databaseTableName,
            destinationTable: databaseTableName)
        return HasManyAssociation(joinMappingRequest: joinMappingRequest, rightRequest: Right.all())
    }
    
    public static func hasMany<Right>(
        _ right: Right.Type,
        foreignKey originColumns: [Column])
        -> HasManyAssociation<Self, Right>
        where Right: TableMapping
    {
        let joinMappingRequest = JoinMappingRequest(
            originTable: Right.databaseTableName,
            destinationTable: databaseTableName,
            originColumns: originColumns.map { $0.name })
        return HasManyAssociation(joinMappingRequest: joinMappingRequest, rightRequest: Right.all())
    }
    
    public static func hasMany<Right>(
        _ right: Right.Type,
        foreignKey originColumns: [Column],
        to destinationColumns: [Column])
        -> HasManyAssociation<Self, Right>
        where Right: TableMapping
    {
        let joinMappingRequest = JoinMappingRequest(
            originTable: Right.databaseTableName,
            destinationTable: databaseTableName,
            originColumns: originColumns.map { $0.name },
            destinationColumns: destinationColumns.map { $0.name })
        return HasManyAssociation(joinMappingRequest: joinMappingRequest, rightRequest: Right.all())
    }
}