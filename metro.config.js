const {getDefaultConfig, mergeConfig} = require('@react-native/metro-config');

/**
 * Metro configuration
 * https://facebook.github.io/metro/docs/configuration
 *
 * @type {import('metro-config').MetroConfig}
 */

const config = {
  resolver: {
    assetExts: getDefaultConfig(__dirname).resolver.assetExts.concat(['wasm']),
  },
};

console.log('CONFIG:', mergeConfig(getDefaultConfig(__dirname), config));
module.exports = mergeConfig(getDefaultConfig(__dirname), config);
