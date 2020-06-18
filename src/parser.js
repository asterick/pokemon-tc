const path = require("path");
const fs = require("fs");
const pegjs = require("pegjs");

const table = require("./table.js");

const mnemonic = 
    Object.keys(table.INSTRUCTION_TABLE)
        .map((v) => `(x:"${v}"i WB {return x})`)
        .join(" / ");

const parseSource = fs.readFileSync(path.join(__dirname, "syntax.pegjs"), 'utf-8') +
    `Mnemonic = ${mnemonic}`;

const parser = pegjs.generate(parseSource, {
    cache: true
});

function parse(source) {
    try {
        const body = parser.parse(source);
        console.log(JSON.stringify(body,null,4))
    } catch(e) {
        console.log(source);
        throw e;
    }
}

module.exports = {
    parse
};
