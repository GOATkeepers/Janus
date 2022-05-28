const gl = require('geolib');
const f = require('fs');

let tiles = [];

// start point - 2.5 km N of Brandenburg Gate

function startPoint() {
    const nwCorner = gl.computeDestinationPoint(
        { latitude: 52.5173151, longitude: 13.3779994 },
    2500,
    0
    )
    return nwCorner;
}

// create the First Tile

function createFirstTile() {
    const nwCorner = startPoint();
    console.log('nwCorner', nwCorner);
    const ne = gl.computeDestinationPoint(
        nwCorner,
        250,
        90
    )
    const sw = gl.computeDestinationPoint(
        nwCorner,
        250,
        180
    )
    const se = gl.computeDestinationPoint(
        sw,
        250,
        90
    )
    tiles.push([nwCorner, ne, se, sw]);    
    return [ nwCorner, ne, se, sw ];
}

// create one tile to the east of the pre

function createEastTile() {
    if (tiles.length === 0) {
        createFirstTile();
    }
    const nw = tiles[tiles.length - 1][1];
    // const nw = adjacentNorthCorner[1];
    const ne = gl.computeDestinationPoint(
        nw,
        250,
        90
    )
    const sw = gl.computeDestinationPoint(
        nw,
        250,
        180
    )
    const se = gl.computeDestinationPoint(
        sw,
        250,
        90
    )
    tiles.push([nw, ne, se, sw]);    
    return [ nw, ne, se, sw ];
}

function createNewRowTile() {
    const nw = tiles[tiles.length - 21][3];
    const ne = gl.computeDestinationPoint(
        nw,
        250,
        90
    )
    const sw = gl.computeDestinationPoint(
        nw,
        250,
        180
    )
    const se = gl.computeDestinationPoint(
        sw,
        250,
        90
    )
    tiles.push([nw, ne, se, sw]);    
    return [ nw, ne, se, sw ];
}

function walkMap() {
    let x = 0; // First tile creates 0,0
    let y = 0;
    while (tiles.length < 358) {           
        while (y < 20) {
            while (x < 20) {
                createEastTile();
                x += 1;
            }
            x = 0; // reset x
            createNewRowTile();
            y += 1;
        }
    }
}
    
function checkLengthOfSides() {
    const nw = tiles[0][0];
    const ne = tiles[20][1];
    const sw = tiles[380][2];
    const se = tiles[400][3];
    const lengthNorth = gl.getDistance(nw, ne);
    const lengthEast = gl.getDistance(ne, se);
    const lengthSouth = gl.getDistance(se, sw);
    const lengthWest = gl.getDistance(nw, sw);
    console.log(['total length: N ' + lengthNorth,'E ' + lengthEast,'S ' + lengthSouth,'W ' + lengthWest]);
}

function checkArea() {
    const nw = tiles[0][0];
    const ne = tiles[19][1];
    const sw = tiles[379][2];
    const se = tiles[399][3];
    console.log([nw, ne, se, sw]);
    const area = gl.getAreaOfPolygon([nw, ne, se, sw]);
    console.log('area', area);
}

function checktile(tile) {
    const nw = tiles[tile][0];
    const ne = tiles[tile][1];
    const sw = tiles[tile][2];
    const se = tiles[tile][3];
    const lengthNorth = gl.getDistance(nw, ne);
    const lengthEast = gl.getDistance(se, ne);
    const lengthSouth = gl.getDistance(se, sw);
    const lengthWest = gl.getDistance(sw, nw);
    console.log(['vertices :', nw, ne, se, sw]);
    console.log(['tile legnth: N ' + lengthNorth,'E ' + lengthEast,'S ' + lengthSouth,'W ' + lengthWest]);
    const area = gl.getAreaOfPolygon([nw, ne, se, sw]);
    console.log('tile area:', area);
}

walkMap();
// console.log(tiles);
checkLengthOfSides();
checkArea();
checktile(369);
console.log(tiles[245][3]);
console.log(tiles.length);
f.writeFile('tiles.json', JSON.stringify(tiles), (err) => {
    if (err) throw err;
    console.log('The file has been saved!');
    }
)
