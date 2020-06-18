const path = require('path');
const fs = require('fs');

const { Const, ArgumentParser } = require('argparse');

const package = JSON.parse(fs.readFileSync(path.join(__dirname, "../package.json")));
const parser = new ArgumentParser({
    version: package.version,
    description: package.description,
    addHelp: true
});

parser.addArgument('input', {
    help: "Source and object files",
    nargs: Const.ONE_OR_MORE
});

let kind = parser.addMutuallyExclusiveGroup()
kind.addArgument(["-a", "--assemble"], {
    action: "storeTrue"
});

kind.addArgument(["-l", "--link"], {
    action: "storeTrue"
});

parser.addArgument(["-O", "--optimize"], {
    action: "storeTrue"
});

parser.addArgument(["-M"], {
    help: "Set memory model"
});

parser.addArgument(["-I"], {
    help: "Add include search path",
    action: "append"
});

parser.addArgument(["-L"], {
    help: "Add library search path",
    action: "append"
});

parser.addArgument(
    ['-D', "--define"], {
        help: "Define expression",
        action: "append"
    }
)

parser.addArgument(['-o', '--output'], {
    help: "Target filename",
    argumentDefault: "a.out"
})

module.exports = parser.parseArgs();
