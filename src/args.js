const path = require('path');
const fs = require('fs');

const { Const, ArgumentParser } = require('argparse');

const package = JSON.parse(fs.readFileSync(path.join(__dirname, "../package.json")));
const parser = new ArgumentParser({
    version: package.version,
    description: package.description,
    addHelp: true
});

parser.addArgument('objects', {
    help: "Object files",
    nargs: Const.ZERO_OR_MORE
});

parser.addArgument(["-a", "--assemble"], {
    help: "Assemble file",
    defaultValue: [],
    action: "append"
});

parser.addArgument(["-e", "--export"], {
    help: "Export binary"
});

parser.addArgument(["-O", "--optimize"], {
    action: "storeTrue"
});

parser.addArgument(["-M"], {
    help: "Set memory model"
});

parser.addArgument(["-I", '--includePath'], {
    help: "Add include search path",
    defaultValue: [],
    action: "append"
});

parser.addArgument(["-L", '--libraryPath'], {
    help: "Add library search path",
    defaultValue: [],
    action: "append"
});

parser.addArgument(['-D', "--define"], {
    help: "Define expression",
    defaultValue: [],
    action: "append"
});

parser.addArgument(['-o', '--output'], {
    help: "Target filename",
    argumentDefault: "a.out"
});

module.exports = parser.parseArgs();
