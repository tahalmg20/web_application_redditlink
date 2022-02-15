const { open } = require('sqlite')

module.exports = {
  openDb: async () => { 
    return open({
      filename: 'main.db',
      driver: sqlite3.Database
    })
  }
}