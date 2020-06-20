const path = require("path");
const fs = require("fs");
const pegjs = require("pegjs");

const table = require("./table.js");
const { kMaxLength } = require("buffer");

// Setup our parser
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

    define_replace(text) {
        // This evaluates defines in order of length (longest first)
        Object.keys(this._env.defines)
            .sort((a,b) => b.length - a.length)
            .forEach((key) => {
                const value = this._env.defines[key];
                while (text.indexOf(key) >= 0) text = text.replace(key, value);
            });
        
        return text;
    }

    *parse(fn, target) {
        let source = this._env.load(fn, 'utf-8', target);

        while (source) {
            /* Run DEFINE replacement on source excluding DEFINE/UNDEF directives directives */
            const DEFINE_MODIFY = /(?<=^\s*([_a-z]\w*\s*:)?\s*)(?<directive>\b(UNDEF|DEFINE)\b)\s*(?<identifier>[a-z_]\w*)/i;
            const keep_out_match = source.match(DEFINE_MODIFY);
            const eol = source.search(/[\r\n]|$/);

            let replace_line = source.substr(0, eol);

            if (keep_out_match) {
                const matched = keep_out_match[0];
                const lead = source.substring(0, keep_out_match.index);
                const tail = source.substring(keep_out_match.index + matched.length, eol);
                replace_line = this.define_replace(lead) + matched + this.define_replace(tail);
            } else {
                replace_line = this.define_replace(replace_line);
            }

            const line = parser.parse(source);
            source = line.remainder;

            // Convert labels to EQU directive
            if (line.label) {
                const location = line.label.location;
                yield {
                    type: 'EquDirective',
                    name: 'carp',
                    value: { type: 'LocationCounter', location },
                    location
                };
            }

            // Emit directive
            if (line.statement) {
                console.log(line)
                yield line.statement;
            }
        }
    }

    assemble(fn) {
        for (let statement of this.parse(fn, 'local')) {
            console.log(statement)
        }
    }
}

module.exports = {
    Assembler
};
