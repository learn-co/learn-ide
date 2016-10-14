const spawnSync = require('./spawn-sync')

module.exports = function (packagedAppPath) {
  var certificates = spawnSync('security', ['find-identity', '-p', 'codesigning', '-v']).stdout.toString();
  var hasFlatironCert = certificates.match('Developer ID Application: Flatiron School, Inc');

  if (!hasFlatironCert) {
    console.log('Skipping code signing because the Flatiron School dev certificate is missing'.gray)
    return
  }

  console.log(`Code-signing application at ${packagedAppPath}`)
  spawnSync('codesign', [
    '--deep', '--force', '--verbose',
    '--sign', 'Developer ID Application: Flatiron School, Inc', packagedAppPath
  ], {stdio: 'inherit'})
}
