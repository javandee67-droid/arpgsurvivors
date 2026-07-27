const fs = require("fs");
const data = JSON.parse(fs.readFileSync("data/passive_skill_tree.json","utf8"));
const rawTexts = new Set();
for (const node of (data.nodes||[])) {
  for (const mod of (node.modifiers||[])) rawTexts.add(mod.raw);
}
for (const node of (data.ascendancy_nodes||[])) {
  for (const mod of (node.modifiers||[])) rawTexts.add(mod.raw);
}
const sorted = Array.from(rawTexts).sort();
console.log("Total:", sorted.length);
fs.writeFileSync("data/raw_texts_output.txt", sorted.join("
"),"utf8");
console.log("Written");
