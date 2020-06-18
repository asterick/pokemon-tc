const path = require("path");
const fs = require("fs");
const pegjs = require("pegjs");

const table = require("./table.js");
const { parse } = require("path");

const mnemonic = 
    Object.keys(table.INSTRUCTION_TABLE)
        .map((v) => `(x:"${v}"i WB {return x})`)
        .join(" / ");

const parseSource = fs.readFileSync(path.join(__dirname, "syntax.pegjs"), 'utf-8') +
    `Mnemonic = ${mnemonic}`;

const parser = pegjs.generate(parseSource, {
    cache: true
});

class Assembler {
    constructor(env) {
        this._env = env;
    }

    parse(fn, target) {
        const source = this._env.load(fn, 'utf-8', target);
        return parser.parse(source);
    }

    assemble(fn) {
        const lines = this.parse(fn, 'local');
        console.log(lines);
    }
}

module.exports = {
    Assembler
};
