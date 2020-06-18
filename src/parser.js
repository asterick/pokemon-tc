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
        const row = parser.parse(source);
        const statement = row.body.statement
        source = row.remainder;
        
        if (!statement) continue ;
        console.log(statement.type);
    }
}

module.exports = {
    parse
};
