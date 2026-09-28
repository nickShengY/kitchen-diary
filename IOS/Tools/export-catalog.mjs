import { build } from 'esbuild';
import { writeFileSync, mkdirSync } from 'node:fs';
const out = await build({stdin: {contents: `import * as k from './data/kitchenData'; import * as p from './data/pantryRecipes'; import {matchRecipes, buildMenu} from './services/pantryMatch'; export {k,p,matchRecipes,buildMenu};`, resolveDir: process.cwd()}, bundle:true, platform:'node', format:'esm', write:false});
const {k,p,matchRecipes,buildMenu} = await import('data:text/javascript;base64,'+Buffer.from(out.outputFiles[0].text).toString('base64'));
mkdirSync('IOS/Resources',{recursive:true});
const catalog={ingredients:k.INGREDIENTS, tools:k.TOOLS.map(({icon,...t})=>t), actions:k.ACTIONS, cuisines:k.CUISINE_CATEGORIES, recipes:p.PANTRY_RECIPES, convertedRecipes:p.PANTRY_RECIPES.map(p.pantryRecipeToRecipe), staples:p.STAPLE_INGREDIENT_IDS, assumedTools:p.ASSUMED_TOOL_IDS, cookware:p.COOKWARE_IDS, temperatures:k.TEMPERATURES,times:k.TIMES, waterLevels:k.WATER_LEVELS, cutShapes:k.CUT_SHAPES,cookMethods:k.COOK_METHODS,details:k.DETAIL_CHIPS};
writeFileSync('IOS/Resources/catalog.json',JSON.stringify(catalog,null,2));
const fixtures=[];
for(const pantry of [[],['egg','tomato','onion','rice','chicken'],k.INGREDIENTS.map(i=>i.id)]) for(const mode of ['flexible','exact','survival']) for(const hour of [8,12,18,23]) {
 const input={pantry,mode,cookware:[],favorites:[],recentlyCooked:[],now:new Date(2026,8,27,hour),dishCount:3,seed:2};
 fixtures.push({...input,now:undefined,hour,ranking:matchRecipes(input).map(m=>({id:m.recipe.id,score:m.score})),menu:buildMenu(input).map(m=>m.recipe.id)});
}
writeFileSync('IOS/Resources/parity-fixtures.json',JSON.stringify(fixtures));
console.log(`Exported ${catalog.ingredients.length} ingredients, ${catalog.tools.length} tools, ${catalog.actions.length} actions, ${catalog.recipes.length} recipes, ${catalog.cuisines.length} cuisines; ${fixtures.length} parity fixtures.`);
