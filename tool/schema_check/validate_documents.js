// Valida ogni documento .graphql di una cartella contro lo schema SDL del BE
// con il graphql-js del backend (nessuna dipendenza npm nel repo Flutter).
//
// Uso:
//   dart run tool/schema_check/dump_documents.dart <docs-dir>
//   NODE_PATH=/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/node_modules node tool/schema_check/validate_documents.js <path-to-BE>/src/schema.gql <docs-dir>
const fs = require('fs');
const path = require('path');
const { buildSchema, parse, validate } = require('graphql');

const [schemaPath, docsDir] = process.argv.slice(2);
const schema = buildSchema(fs.readFileSync(schemaPath, 'utf8'));

let failures = 0;
for (const file of fs.readdirSync(docsDir).filter((f) => f.endsWith('.graphql')).sort()) {
  const text = fs.readFileSync(path.join(docsDir, file), 'utf8');
  try {
    const errors = validate(schema, parse(text));
    if (errors.length === 0) {
      console.log(`OK ${file}`);
    } else {
      failures++;
      console.log(`FAIL ${file}: ${errors.map((e) => e.message).join('; ')}`);
    }
  } catch (e) {
    failures++;
    console.log(`FAIL ${file}: ${e.message}`);
  }
}
process.exit(failures ? 1 : 0);
