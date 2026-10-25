export const pantryStarters = [
 { id: 'eggs-tomatoes', title: 'Eggs + tomatoes', ingredients: ['egg','tomato'], cookware: ['skillet'], dish: 'Tomato Scrambled Eggs', recipeId: 'tomato-scrambled-eggs', minutes: 10, missing: [], extras: 'Scallion and sugar are optional extras.', next: 'With rice and a wok, you can also explore egg fried rice.' },
 { id: 'pasta-tomatoes', title: 'Pasta + tomatoes', ingredients: ['pasta','tomato'], cookware: ['pot','saute_pan'], dish: 'Ten-Minute Tomato Pasta', recipeId: 'tomato-pasta', minutes: 20, missing: ['garlic'], extras: 'Basil, parmesan and chili flakes are optional extras.', next: 'Add garlic to complete the core ingredients for this dish.' },
 { id: 'chickpeas-coconut', title: 'Chickpeas + coconut milk', ingredients: ['chickpeas','coconut_milk'], cookware: ['saucepan'], dish: 'Chickpea Coconut Curry', recipeId: 'chickpea-curry', minutes: 30, missing: ['onion','curry_powder'], extras: 'Spinach, garlic, ginger, tomato, rice and cilantro are listed as extras.', next: 'Check onion and curry powder before choosing this dinner.' },
];
export const findPantryStarter = id => pantryStarters.find(item => item.id === id);
export const starterHref = id => '/?view=KITCHEN&starter=' + encodeURIComponent(id);
