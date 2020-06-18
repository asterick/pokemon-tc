const fs = require("fs");

const parser = require("./parser.js");
const args = require("./args.js");

if (args.assemble) {
    args.input.forEach((fn) => {
        const src = fs.readFileSync(fn, "utf-8");
       
        parser.parse(src);
    });
}
