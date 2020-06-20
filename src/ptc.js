const { Environment } = require("./environment.js");
const { Assembler } = require("./assembler.js");

const args = require("./args.js");

args.assemble.forEach((fn) => {
    const environment = new Environment(args);
    const assembler = new Assembler(environment);

    assembler.assemble(fn);
});
