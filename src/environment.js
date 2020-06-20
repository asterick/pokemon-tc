const fs = require('fs');
const path = require('path');

class Environment {
    constructor(args) {
        this.defines = {};

        args.define.forEach((d) => {
            const match = /^([a-z_]\w*)=(.*)$/i.exec(d);
            if (!match) {
                throw new Error(`Illegal define: ${d}`);
            }
            
            const [ _, key, value ] = match;
            this.defines[key] = value;
        })

        this.includePaths = args.includePath;
        this.libraryPaths = args.libraryPath;
    }

    load (name, format, zone) {
        let paths = [];

        if (zone != 'global') {
            paths.push(name)
        }

        if (zone != 'local') {
            paths.push(... this.includePaths.map((p) => path.join(p, name)))
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
