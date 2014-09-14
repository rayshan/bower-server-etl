module.exports = (sequelize, DataTypes) ->
  stats_env = sequelize.define 'stats_env', {
    date:
      type: 'DATE'
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
    # auto creates createdAt / updatedAt
  }, {
    underscored: true # updatedAt -> updated_at
    createdAt: false # only need updated_at
    tableName: 'stats_env'
    freezeTableName: true # don't transform model name to plural
  }

  stats_env.removeAttribute 'id'

  stats_env
