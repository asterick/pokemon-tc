const fs = require('fs');
const path = require('path');

class Environment {
    constructor(args) {
        this._defines = Object.create(process.env);

        args.define.forEach((d) => {
            const [ _, key, value ] = /^(.*?)=(.*)$/.exec(d);
            this._defines[key] = value;
        })

        this._includePaths = args.includePath;
        this._libraryPaths = args.libraryPath;
    }

    load (name, format, zone) {
        let paths = [];

        if (zone != 'global') {
            paths.push(name)
        }

        if (zone != 'local') {
            paths.push(... this._includePaths.map((p) => path.join(p, name)))
        }

        for (let fn of paths) {
            if (fs.existsSync(fn)) {
                return fs.readFileSync(name, format);
            }
        }

        throw new Error(`Could not locate file "${s}"`, name);
    }
}

module.exports = {
    Environment
}
