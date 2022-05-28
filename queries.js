const Pool = require('pg').Pool
const dotenv = require('dotenv');
const format = require('pg-format');
const tiles = require('./tiles.json');
dotenv.config();

const getAllTiles = (request, response) => {
    pool.query('SELECT * FROM janus_polygons ORDER BY id ASC', (error, results) => {
      if (error) {
        throw error
      }
      response.status(200).json(results.rows)
    })
}

const getTileId = (request, response) => {
    const { lat, lon } = request.body

    pool.query('SELECT janus_polygons.id FROM janus_polygons WHERE ST_CONTAINS(janus_polygons.geom, \'POINT([$1], [$2])\')', [lat,lon], (error, results) => {
        if (error) {
            throw error
        }
        response.status(200).json(results.rows)
    })
}
const seedTiles = (request, response) => {
    for (let i = 0; i < tiles.length; i++) {
    pool.query('INSERT INTO janus_polygons (geom) VALUES ([$1] [$2], [$3] [$4], [$5] [$6], [$7] [$8])'), [
        tiles[i][0].latitude, tiles[i][0].longitude, 
        tiles[i][1].latitude, tiles[i][1].longitude, 
        tiles[i][2].latitude, tiles[i][2].longitude, 
        tiles[i][3].latitude, tiles[i][3].longitude, 
    ], (err, result)=>{
        if (err) {
            throw err
        }
        response.status(200).json(result)
    };
    }
}

const pool = new Pool({
  user: 'postgres',
  host: 'strapi-global.coveycrhh5xo.us-west-2.rds.amazonaws.com',
  database: 'janus',
  password: '',
  port: 5432,
})

module.exports = {
    getAllTiles,
    getTileId,
    seedTiles
}
