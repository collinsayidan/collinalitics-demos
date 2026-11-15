import assert from "node:assert/strict";
import {readFileSync} from "node:fs";
import path from "node:path";
const pages=["demos/index.html","demos/scotland-its/index.html","demos/scotland-its/executive.html","demos/scotland-its/explore.html","demos/scotland-its/methodology.html"];
const css=readFileSync("demos/editorial.css","utf8");
for(const value of ["#e8f1f0","#0e2240","#0b7e7c",".sr-only"])assert.ok(css.toLowerCase().includes(value),"Missing design token: "+value);
for(const file of pages){
  const html=readFileSync(file,"utf8");
  const rel=path.relative(path.dirname(file),"demos/editorial.css").replaceAll("\\","/");
  assert.ok(html.includes('href="'+rel+'"'),"Missing CSS: "+file);
  assert.match(html,/SYNTHETIC DATA \/ PORTFOLIO DEMONSTRATION/);
  assert.match(html,/LOGO\.png/);
  for(const script of html.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/g)){
    if(script[1].trim())new Function(script[1]);
  }
}
const explorer=readFileSync("demos/scotland-its/explore.html","utf8");
for(const value of ['id="resetFilters"','id="exportCsv"','const records = current()','csvValue(row[field])'])
  assert.ok(explorer.includes(value),"Missing exporter/reset feature: "+value);
const network=readFileSync("demos/scotland-its/executive.html","utf8");
assert.match(network,/id="resetNetworkFilters"/);
assert.match(network,/aria-live="polite"/);
const method=readFileSync("demos/scotland-its/methodology.html","utf8");
assert.match(method,/different model,/);
assert.match(method,/not Transport Scotland data/);
const data=readFileSync("demos/scotland-its/data.js","utf8");
assert.match(data,/conformance":95\.7/);
console.log("ITS source validation passed; actual browser and pipeline validation still required.");
