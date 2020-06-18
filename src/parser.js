const path = require("path");
const fs = require("fs");
const pegjs = require("pegjs");

const table = require("./table.js");

const mnemonic = 
    Object.keys(table.INSTRUCTION_TABLE)
        .sort((a, b) => b.length - a.length)
        .map((v) => `"${v}"i`)
        .join(" / ");

const parseSource = fs.readFileSync(path.join(__dirname, "syntax.pegjs"), 'utf-8') +
    `Mnemonic = ${mnemonic}`;

const parser = pegjs.generate(parseSource, {
    cache: true
});

function parse(source) {
    while (source) {
        try {
            const row = parser.parse(source);
            const statement = row.body.statement
            console.log(statement)
            source = row.remainder;
        } catch(e) {
            console.log(source)
            throw e;
            break ;
        }
    }
}

module.exports = {
    parse
};
