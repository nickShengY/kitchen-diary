import { describe, it, expect } from 'vitest';
import {
  INGREDIENTS,
  TOOLS,
  ACTIONS,
  TEMPERATURES,
  TIMES,
  WATER_LEVELS,
} from '../../data/kitchenData';
import { Category, PhysicalProperty } from '../../types';

describe('kitchenData', () => {
  describe('INGREDIENTS', () => {
    it('should have ingredients array', () => {
      expect(Array.isArray(INGREDIENTS)).toBe(true);
      expect(INGREDIENTS.length).toBeGreaterThan(0);
    });

    it('should have at least 25 ingredients', () => {
      expect(INGREDIENTS.length).toBeGreaterThanOrEqual(25);
    });

    describe('ingredient structure', () => {
      it('all ingredients should have required properties', () => {
        INGREDIENTS.forEach((ingredient) => {
          expect(ingredient).toHaveProperty('id');
          expect(ingredient).toHaveProperty('name');
          expect(ingredient).toHaveProperty('emoji');
          expect(ingredient).toHaveProperty('category');
          expect(ingredient).toHaveProperty('defaultUnit');
          expect(ingredient).toHaveProperty('physicalProperties');
        });
      });

      it('all ingredients should have non-empty id', () => {
        INGREDIENTS.forEach((ingredient) => {
          expect(ingredient.id).toBeTruthy();
          expect(typeof ingredient.id).toBe('string');
        });
      });

      it('all ingredients should have non-empty name', () => {
        INGREDIENTS.forEach((ingredient) => {
          expect(ingredient.name).toBeTruthy();
          expect(typeof ingredient.name).toBe('string');
        });
      });

      it('all ingredients should have an emoji', () => {
        INGREDIENTS.forEach((ingredient) => {
          expect(ingredient.emoji).toBeTruthy();
          expect(typeof ingredient.emoji).toBe('string');
        });
      });

      it('all ingredients should have physical properties array', () => {
        INGREDIENTS.forEach((ingredient) => {
          expect(Array.isArray(ingredient.physicalProperties)).toBe(true);
        });
      });

      it('all ingredients should have at least one physical property', () => {
        INGREDIENTS.forEach((ingredient) => {
          expect(ingredient.physicalProperties.length).toBeGreaterThan(0);
        });
      });
    });

    describe('ingredient IDs', () => {
      it('all ingredient IDs should be unique', () => {
        const ids = INGREDIENTS.map((i) => i.id);
        const uniqueIds = new Set(ids);
        expect(ids.length).toBe(uniqueIds.size);
      });

      it('all ingredient IDs should be lowercase', () => {
        INGREDIENTS.forEach((ingredient) => {
          expect(ingredient.id).toBe(ingredient.id.toLowerCase());
        });
      });
    });

    describe('ingredient categories', () => {
      const validCategories: Category[] = [
        'vegetable',
        'meat',
        'dairy',
        'spice',
        'grain',
        'fruit',
        'liquid',
        'seafood',
        'condiment',
        'herb',
      ];

      it('all ingredients should have valid categories', () => {
        INGREDIENTS.forEach((ingredient) => {
          expect(validCategories).toContain(ingredient.category);
        });
      });

      it('should have ingredients in vegetable category', () => {
        const vegetables = INGREDIENTS.filter((i) => i.category === 'vegetable');
        expect(vegetables.length).toBeGreaterThan(0);
      });

      it('should have ingredients in meat category', () => {
        const meats = INGREDIENTS.filter((i) => i.category === 'meat');
        expect(meats.length).toBeGreaterThan(0);
      });

      it('should have ingredients in dairy category', () => {
        const dairy = INGREDIENTS.filter((i) => i.category === 'dairy');
        expect(dairy.length).toBeGreaterThan(0);
      });

      it('should have ingredients in grain category', () => {
        const grains = INGREDIENTS.filter((i) => i.category === 'grain');
        expect(grains.length).toBeGreaterThan(0);
      });

      it('should have ingredients in fruit category', () => {
        const fruits = INGREDIENTS.filter((i) => i.category === 'fruit');
        expect(fruits.length).toBeGreaterThan(0);
      });

      it('should have ingredients in spice category', () => {
        const spices = INGREDIENTS.filter((i) => i.category === 'spice');
        expect(spices.length).toBeGreaterThan(0);
      });

      it('should have ingredients in liquid category', () => {
        const liquids = INGREDIENTS.filter((i) => i.category === 'liquid');
        expect(liquids.length).toBeGreaterThan(0);
      });

      it('should have ingredients in seafood category', () => {
        const seafood = INGREDIENTS.filter((i) => i.category === 'seafood');
        expect(seafood.length).toBeGreaterThan(0);
      });
    });

    describe('ingredient physical properties', () => {
      const validProperties: PhysicalProperty[] = [
        'peelable',
        'choppable',
        'liquid',
        'solid',
        'mixable',
        'cookable',
        'grateable',
        'meat',
        'vegetable',
      ];

      it('all physical properties should be valid', () => {
        INGREDIENTS.forEach((ingredient) => {
          ingredient.physicalProperties.forEach((prop) => {
            expect(validProperties).toContain(prop);
          });
        });
      });

      it('should have choppable ingredients', () => {
        const choppable = INGREDIENTS.filter((i) =>
          i.physicalProperties.includes('choppable')
        );
        expect(choppable.length).toBeGreaterThan(0);
      });

      it('should have peelable ingredients', () => {
        const peelable = INGREDIENTS.filter((i) =>
          i.physicalProperties.includes('peelable')
        );
        expect(peelable.length).toBeGreaterThan(0);
      });

      it('should have cookable ingredients', () => {
        const cookable = INGREDIENTS.filter((i) =>
          i.physicalProperties.includes('cookable')
        );
        expect(cookable.length).toBeGreaterThan(0);
      });

      it('should have liquid ingredients', () => {
        const liquids = INGREDIENTS.filter((i) =>
          i.physicalProperties.includes('liquid')
        );
        expect(liquids.length).toBeGreaterThan(0);
      });

      it('should have grateable ingredients', () => {
        const grateable = INGREDIENTS.filter((i) =>
          i.physicalProperties.includes('grateable')
        );
        expect(grateable.length).toBeGreaterThan(0);
      });
    });

    describe('specific ingredients', () => {
      it('should have tomato', () => {
        const tomato = INGREDIENTS.find((i) => i.id === 'tomato');
        expect(tomato).toBeDefined();
        expect(tomato?.name).toBe('Tomato');
        expect(tomato?.emoji).toBe('🍅');
        expect(tomato?.category).toBe('vegetable');
      });

      it('should have chicken', () => {
        const chicken = INGREDIENTS.find((i) => i.id === 'chicken');
        expect(chicken).toBeDefined();
        expect(chicken?.name).toBe('Chicken');
        expect(chicken?.physicalProperties).toContain('meat');
        expect(chicken?.physicalProperties).toContain('cookable');
      });

      it('should have egg', () => {
        const egg = INGREDIENTS.find((i) => i.id === 'egg');
        expect(egg).toBeDefined();
        expect(egg?.name).toBe('Egg');
        expect(egg?.physicalProperties).toContain('cookable');
      });

      it('should have milk', () => {
        const milk = INGREDIENTS.find((i) => i.id === 'milk');
        expect(milk).toBeDefined();
        expect(milk?.physicalProperties).toContain('liquid');
      });

      it('should have cheese', () => {
        const cheese = INGREDIENTS.find((i) => i.id === 'cheese');
        expect(cheese).toBeDefined();
        expect(cheese?.physicalProperties).toContain('grateable');
      });

      it('should have carrot', () => {
        const carrot = INGREDIENTS.find((i) => i.id === 'carrot');
        expect(carrot).toBeDefined();
        expect(carrot?.physicalProperties).toContain('peelable');
        expect(carrot?.physicalProperties).toContain('choppable');
      });
    });

    describe('ingredient default units', () => {
      it('all ingredients should have default units', () => {
        INGREDIENTS.forEach((ingredient) => {
          expect(ingredient.defaultUnit).toBeTruthy();
          expect(typeof ingredient.defaultUnit).toBe('string');
        });
      });

      it('should have appropriate units for different categories', () => {
        const milk = INGREDIENTS.find((i) => i.id === 'milk');
        expect(milk?.defaultUnit).toBe('cup');

        const egg = INGREDIENTS.find((i) => i.id === 'egg');
        expect(egg?.defaultUnit).toBe('pcs');

        const beef = INGREDIENTS.find((i) => i.id === 'beef');
        expect(beef?.defaultUnit).toBe('lb');

        const salt = INGREDIENTS.find((i) => i.id === 'salt');
        expect(salt?.defaultUnit).toBe('tsp');
      });
    });
  });

  describe('TOOLS', () => {
    it('should have tools array', () => {
      expect(Array.isArray(TOOLS)).toBe(true);
      expect(TOOLS.length).toBeGreaterThan(0);
    });

    it('should have at least 5 tools', () => {
      expect(TOOLS.length).toBeGreaterThanOrEqual(5);
    });

    describe('tool structure', () => {
      it('all tools should have required properties', () => {
        TOOLS.forEach((tool) => {
          expect(tool).toHaveProperty('id');
          expect(tool).toHaveProperty('name');
          expect(tool).toHaveProperty('icon');
          expect(tool).toHaveProperty('type');
        });
      });

      it('all tools should have non-empty id', () => {
        TOOLS.forEach((tool) => {
          expect(tool.id).toBeTruthy();
          expect(typeof tool.id).toBe('string');
        });
      });

      it('all tools should have non-empty name', () => {
        TOOLS.forEach((tool) => {
          expect(tool.name).toBeTruthy();
          expect(typeof tool.name).toBe('string');
        });
      });
    });

    describe('tool IDs', () => {
      it('all tool IDs should be unique', () => {
        const ids = TOOLS.map((t) => t.id);
        const uniqueIds = new Set(ids);
        expect(ids.length).toBe(uniqueIds.size);
      });

      it('all tool IDs should be lowercase', () => {
        TOOLS.forEach((tool) => {
          expect(tool.id).toBe(tool.id.toLowerCase());
        });
      });
    });

    describe('tool types', () => {
      const validTypes = ['prep', 'cook', 'appliance'];

      it('all tools should have valid types', () => {
        TOOLS.forEach((tool) => {
          expect(validTypes).toContain(tool.type);
        });
      });

      it('should have prep tools', () => {
        const prepTools = TOOLS.filter((t) => t.type === 'prep');
        expect(prepTools.length).toBeGreaterThan(0);
      });

      it('should have cook tools', () => {
        const cookTools = TOOLS.filter((t) => t.type === 'cook');
        expect(cookTools.length).toBeGreaterThan(0);
      });

      it('should have appliance tools', () => {
        const applianceTools = TOOLS.filter((t) => t.type === 'appliance');
        expect(applianceTools.length).toBeGreaterThan(0);
      });
    });

    describe('specific tools', () => {
      it('should have knife', () => {
        const knife = TOOLS.find((t) => t.id === 'knife');
        expect(knife).toBeDefined();
        expect(knife?.name).toBe('Chef Knife');
        expect(knife?.type).toBe('prep');
      });

      it('should have pan', () => {
        const pan = TOOLS.find((t) => t.id === 'pan');
        expect(pan).toBeDefined();
        expect(pan?.name).toBe('Frying Pan');
        expect(pan?.type).toBe('cook');
      });

      it('should have pot', () => {
        const pot = TOOLS.find((t) => t.id === 'pot');
        expect(pot).toBeDefined();
        expect(pot?.name).toBe('Stock Pot');
        expect(pot?.type).toBe('cook');
      });

      it('should have oven', () => {
        const oven = TOOLS.find((t) => t.id === 'oven');
        expect(oven).toBeDefined();
        expect(oven?.type).toBe('appliance');
      });

      it('should have blender', () => {
        const blender = TOOLS.find((t) => t.id === 'blender');
        expect(blender).toBeDefined();
        expect(blender?.type).toBe('appliance');
      });

      it('should have bowl', () => {
        const bowl = TOOLS.find((t) => t.id === 'bowl');
        expect(bowl).toBeDefined();
        expect(bowl?.type).toBe('prep');
      });

      it('should have peeler', () => {
        const peeler = TOOLS.find((t) => t.id === 'peeler');
        expect(peeler).toBeDefined();
        expect(peeler?.type).toBe('prep');
      });

      it('should have grill', () => {
        const grill = TOOLS.find((t) => t.id === 'grill');
        expect(grill).toBeDefined();
        expect(grill?.type).toBe('cook');
      });
    });
  });

  describe('ACTIONS', () => {
    it('should have actions array', () => {
      expect(Array.isArray(ACTIONS)).toBe(true);
      expect(ACTIONS.length).toBeGreaterThan(0);
    });

    it('should have at least 10 actions', () => {
      expect(ACTIONS.length).toBeGreaterThanOrEqual(10);
    });

    describe('action structure', () => {
      it('all actions should have required properties', () => {
        ACTIONS.forEach((action) => {
          expect(action).toHaveProperty('id');
          expect(action).toHaveProperty('name');
          expect(action).toHaveProperty('verb');
          expect(action).toHaveProperty('icon');
        });
      });

      it('all actions should have non-empty id', () => {
        ACTIONS.forEach((action) => {
          expect(action.id).toBeTruthy();
          expect(typeof action.id).toBe('string');
        });
      });

      it('all actions should have non-empty name', () => {
        ACTIONS.forEach((action) => {
          expect(action.name).toBeTruthy();
          expect(typeof action.name).toBe('string');
        });
      });

      it('all actions should have non-empty verb', () => {
        ACTIONS.forEach((action) => {
          expect(action.verb).toBeTruthy();
          expect(typeof action.verb).toBe('string');
        });
      });

      it('all actions should have icon (emoji)', () => {
        ACTIONS.forEach((action) => {
          expect(action.icon).toBeTruthy();
          expect(typeof action.icon).toBe('string');
        });
      });
    });

    describe('action IDs', () => {
      it('all action IDs should be unique', () => {
        const ids = ACTIONS.map((a) => a.id);
        const uniqueIds = new Set(ids);
        expect(ids.length).toBe(uniqueIds.size);
      });

      it('all action IDs should be lowercase', () => {
        ACTIONS.forEach((action) => {
          expect(action.id).toBe(action.id.toLowerCase());
        });
      });
    });

    describe('action tool requirements', () => {
      it('chop action should require knife', () => {
        const chop = ACTIONS.find((a) => a.id === 'chop');
        expect(chop?.requiresToolId).toBe('knife');
      });

      it('dice action should require knife', () => {
        const dice = ACTIONS.find((a) => a.id === 'dice');
        expect(dice?.requiresToolId).toBe('knife');
      });

      it('peel action should require peeler', () => {
        const peel = ACTIONS.find((a) => a.id === 'peel');
        expect(peel?.requiresToolId).toBe('peeler');
      });

      it('mix action should require bowl', () => {
        const mix = ACTIONS.find((a) => a.id === 'mix');
        expect(mix?.requiresToolId).toBe('bowl');
      });

      it('fry action should require pan', () => {
        const fry = ACTIONS.find((a) => a.id === 'fry');
        expect(fry?.requiresToolId).toBe('pan');
      });

      it('boil action should require pot', () => {
        const boil = ACTIONS.find((a) => a.id === 'boil');
        expect(boil?.requiresToolId).toBe('pot');
      });

      it('bake action should require oven', () => {
        const bake = ACTIONS.find((a) => a.id === 'bake');
        expect(bake?.requiresToolId).toBe('oven');
      });

      it('blend action should require blender', () => {
        const blend = ACTIONS.find((a) => a.id === 'blend');
        expect(blend?.requiresToolId).toBe('blender');
      });

      it('grill action should require grill', () => {
        const grill = ACTIONS.find((a) => a.id === 'grill');
        expect(grill?.requiresToolId).toBe('grill');
      });
    });

    describe('action heat requirements', () => {
      it('fry action should require heat', () => {
        const fry = ACTIONS.find((a) => a.id === 'fry');
        expect(fry?.requiresHeat).toBe(true);
      });

      it('boil action should require heat', () => {
        const boil = ACTIONS.find((a) => a.id === 'boil');
        expect(boil?.requiresHeat).toBe(true);
      });

      it('bake action should require heat', () => {
        const bake = ACTIONS.find((a) => a.id === 'bake');
        expect(bake?.requiresHeat).toBe(true);
      });

      it('sear action should require heat', () => {
        const sear = ACTIONS.find((a) => a.id === 'sear');
        expect(sear?.requiresHeat).toBe(true);
      });

      it('simmer action should require heat', () => {
        const simmer = ACTIONS.find((a) => a.id === 'simmer');
        expect(simmer?.requiresHeat).toBe(true);
      });

      it('roast action should require heat', () => {
        const roast = ACTIONS.find((a) => a.id === 'roast');
        expect(roast?.requiresHeat).toBe(true);
      });

      it('grill action should require heat', () => {
        const grill = ACTIONS.find((a) => a.id === 'grill');
        expect(grill?.requiresHeat).toBe(true);
      });

      it('chop action should not require heat', () => {
        const chop = ACTIONS.find((a) => a.id === 'chop');
        expect(chop?.requiresHeat).toBeFalsy();
      });

      it('mix action should not require heat', () => {
        const mix = ACTIONS.find((a) => a.id === 'mix');
        expect(mix?.requiresHeat).toBeFalsy();
      });
    });

    describe('action valid properties', () => {
      it('chop action should be valid for choppable', () => {
        const chop = ACTIONS.find((a) => a.id === 'chop');
        expect(chop?.validProperties).toContain('choppable');
      });

      it('peel action should be valid for peelable', () => {
        const peel = ACTIONS.find((a) => a.id === 'peel');
        expect(peel?.validProperties).toContain('peelable');
      });

      it('sear action should be valid for meat', () => {
        const sear = ACTIONS.find((a) => a.id === 'sear');
        expect(sear?.validProperties).toContain('meat');
      });

      it('simmer action should be valid for liquid', () => {
        const simmer = ACTIONS.find((a) => a.id === 'simmer');
        expect(simmer?.validProperties).toContain('liquid');
      });

      it('blend action should be valid for solid and liquid', () => {
        const blend = ACTIONS.find((a) => a.id === 'blend');
        expect(blend?.validProperties).toContain('solid');
        expect(blend?.validProperties).toContain('liquid');
      });

      it('plate action should have no property requirements', () => {
        const plate = ACTIONS.find((a) => a.id === 'plate');
        expect(plate?.validProperties).toBeUndefined();
      });

      it('garnish action should have no property requirements', () => {
        const garnish = ACTIONS.find((a) => a.id === 'garnish');
        expect(garnish?.validProperties).toBeUndefined();
      });
    });

    describe('specific actions', () => {
      const expectedActions = [
        'chop',
        'dice',
        'slice',
        'mince',
        'peel',
        'mix',
        'whisk',
        'fry',
        'sear',
        'boil',
        'simmer',
        'bake',
        'roast',
        'blend',
        'grill',
        'plate',
        'garnish',
      ];

      expectedActions.forEach((actionId) => {
        it(`should have ${actionId} action`, () => {
          const action = ACTIONS.find((a) => a.id === actionId);
          expect(action).toBeDefined();
        });
      });
    });
  });

  describe('TEMPERATURES', () => {
    it('should have temperatures array', () => {
      expect(Array.isArray(TEMPERATURES)).toBe(true);
      expect(TEMPERATURES.length).toBeGreaterThan(0);
    });

    it('should have at least 5 temperature options', () => {
      expect(TEMPERATURES.length).toBeGreaterThanOrEqual(5);
    });

    it('should include common heat levels', () => {
      expect(TEMPERATURES).toContain('Low');
      expect(TEMPERATURES).toContain('Medium');
      expect(TEMPERATURES).toContain('High');
    });

    it('should include specific temperatures', () => {
      expect(TEMPERATURES).toContain('300°F');
      expect(TEMPERATURES).toContain('350°F');
      expect(TEMPERATURES).toContain('400°F');
      expect(TEMPERATURES).toContain('450°F');
    });

    it('all temperatures should be non-empty strings', () => {
      TEMPERATURES.forEach((temp) => {
        expect(typeof temp).toBe('string');
        expect(temp.length).toBeGreaterThan(0);
      });
    });
  });

  describe('TIMES', () => {
    it('should have times array', () => {
      expect(Array.isArray(TIMES)).toBe(true);
      expect(TIMES.length).toBeGreaterThan(0);
    });

    it('should have at least 5 time options', () => {
      expect(TIMES.length).toBeGreaterThanOrEqual(5);
    });

    it('should include short times', () => {
      expect(TIMES).toContain('1 min');
      expect(TIMES).toContain('5 mins');
    });

    it('should include medium times', () => {
      expect(TIMES).toContain('10 mins');
      expect(TIMES).toContain('15 mins');
      expect(TIMES).toContain('30 mins');
    });

    it('should include longer times', () => {
      expect(TIMES).toContain('45 mins');
      expect(TIMES).toContain('1 hr');
      expect(TIMES).toContain('2 hrs');
    });

    it('all times should be non-empty strings', () => {
      TIMES.forEach((time) => {
        expect(typeof time).toBe('string');
        expect(time.length).toBeGreaterThan(0);
      });
    });
  });

  describe('WATER_LEVELS', () => {
    it('should have water levels array', () => {
      expect(Array.isArray(WATER_LEVELS)).toBe(true);
      expect(WATER_LEVELS.length).toBeGreaterThan(0);
    });

    it('should have at least 4 water level options', () => {
      expect(WATER_LEVELS.length).toBeGreaterThanOrEqual(4);
    });

    it('should include expected water levels', () => {
      expect(WATER_LEVELS).toContain('Splash');
      expect(WATER_LEVELS).toContain('1/4 cup');
      expect(WATER_LEVELS).toContain('1 cup');
      expect(WATER_LEVELS).toContain('2 cups');
      expect(WATER_LEVELS).toContain('Covered');
    });

    it('all water levels should be non-empty strings', () => {
      WATER_LEVELS.forEach((level) => {
        expect(typeof level).toBe('string');
        expect(level.length).toBeGreaterThan(0);
      });
    });
  });

  describe('data consistency', () => {
    it('all action tool requirements should reference existing tools', () => {
      const toolIds = new Set(TOOLS.map((t) => t.id));
      ACTIONS.forEach((action) => {
        if (action.requiresToolId) {
          expect(toolIds.has(action.requiresToolId)).toBe(true);
        }
      });
    });

    it('all action valid properties should be valid physical properties', () => {
      const validProperties: PhysicalProperty[] = [
        'peelable',
        'choppable',
        'liquid',
        'solid',
        'mixable',
        'cookable',
        'grateable',
        'meat',
        'vegetable',
      ];
      ACTIONS.forEach((action) => {
        if (action.validProperties) {
          action.validProperties.forEach((prop) => {
            expect(validProperties).toContain(prop);
          });
        }
      });
    });

    it('ingredients with meat property should be in meat or seafood category', () => {
      const meats = INGREDIENTS.filter((i) =>
        i.physicalProperties.includes('meat')
      );
      meats.forEach((ingredient) => {
        expect(['meat', 'seafood']).toContain(ingredient.category);
      });
    });

    it('ingredients in liquid category should have liquid property', () => {
      const liquids = INGREDIENTS.filter((i) => i.category === 'liquid');
      liquids.forEach((ingredient) => {
        expect(ingredient.physicalProperties).toContain('liquid');
      });
    });
  });

  describe('business logic validation', () => {
    it('choppable ingredients can be used with chop action', () => {
      const chopAction = ACTIONS.find((a) => a.id === 'chop');
      const choppableIngredients = INGREDIENTS.filter((i) =>
        i.physicalProperties.includes('choppable')
      );

      expect(choppableIngredients.length).toBeGreaterThan(0);
      choppableIngredients.forEach((ingredient) => {
        const canChop = chopAction?.validProperties?.some((prop) =>
          ingredient.physicalProperties.includes(prop)
        );
        expect(canChop).toBe(true);
      });
    });

    it('peelable ingredients can be used with peel action', () => {
      const peelAction = ACTIONS.find((a) => a.id === 'peel');
      const peelableIngredients = INGREDIENTS.filter((i) =>
        i.physicalProperties.includes('peelable')
      );

      expect(peelableIngredients.length).toBeGreaterThan(0);
      peelableIngredients.forEach((ingredient) => {
        const canPeel = peelAction?.validProperties?.some((prop) =>
          ingredient.physicalProperties.includes(prop)
        );
        expect(canPeel).toBe(true);
      });
    });

    it('meat ingredients can be used with sear action', () => {
      const searAction = ACTIONS.find((a) => a.id === 'sear');
      const meatIngredients = INGREDIENTS.filter((i) =>
        i.physicalProperties.includes('meat')
      );

      expect(meatIngredients.length).toBeGreaterThan(0);
      meatIngredients.forEach((ingredient) => {
        const canSear = searAction?.validProperties?.some((prop) =>
          ingredient.physicalProperties.includes(prop)
        );
        expect(canSear).toBe(true);
      });
    });

    it('grateable ingredients can be found', () => {
      const grateableIngredients = INGREDIENTS.filter((i) =>
        i.physicalProperties.includes('grateable')
      );
      expect(grateableIngredients.length).toBeGreaterThan(0);
    });
  });
});
