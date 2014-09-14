tableName = 'stats_env'

module.exports =
  up: (migration, DataTypes, done) ->
    migrationPromise = migration.createTable tableName, {
      date:
        type: 'DATE'
        # hack due to no date-only field support in sequelize
        # https://github.com/sequelize/sequelize/issues/1514#issuecomment-37959854
        allowNull: false
      version_cli:
        type: DataTypes.TEXT
      version_node:
        type: DataTypes.TEXT
      os:
        type: DataTypes.TEXT
      users:
        type: DataTypes.INTEGER
        allowNull: false
      updated_at:
        type: DataTypes.DATE # TIMESTAMP WITH TIME ZONE for postgres
        allowNull: false
    }, {
      comment: "Stats on Bower CLI users' environment." # table comment; PG / MySQL only
    }

    migrationPromise.then ->
      migration.showAllTables().then console.log
      migration.describeTable(tableName)
        .then (data) ->
          console.log data
          return
        .then done
      return
    return

  down: (migration, DataTypes, done) ->
    migration.dropTable(tableName).then ->
      migration.showAllTables()
        .then console.log
        .then done
      return
    return
