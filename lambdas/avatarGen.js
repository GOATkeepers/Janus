const sharp = require('sharp');
const bytes32 = require('bytes32');

// client calls this function with either an Urbit ID (star / planet holders) or an Eth address (non holders)
function selectAttributes(holderAddress) {
    const avatarConvert = bytes32(holderAddress);
    const avatarSeed = avatarConvert.slice(2, 9);
    const field = avatarSeed.slice(0);
    const ornament = avatarSeed.slice(6,7);
}
