const fs = require('fs');

// Read a secret from the file named by `${name}_FILE` (Docker secrets),
// falling back to the plain `${name}` environment variable.
function readSecret(name) {
    const filePath = process.env[`${name}_FILE`];

    if (filePath) {
        try {
            return fs.readFileSync(filePath, 'utf8').trim();
        } catch (err) {
            throw new Error(`Failed to read ${name}_FILE (${filePath}): ${err.code || 'unknown error'}`);
        }
    }

    return process.env[name];
}

module.exports = { readSecret };
