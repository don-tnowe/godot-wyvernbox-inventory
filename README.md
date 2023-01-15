# Wyvernbox

An addon for versatile inventory systems.

Scenes you may need are located inside `addons/wyvernbox_prefabs`. Just drag and drop!

The `example/wyvernbox` folder contains some items and equipment stats to start. Be sure to check the example scenes, too!

## All you need:

- One of the `InventoryView` objects,
- An `InventoryTooltip` to inspect items (*maybe with a few `TooltipProperty` scripts attached*),
- A `GrabbedItemStackView` to move things around with a mouse,
- And a couple `ItemType` resources to define item types.

## How it works:

- `InventoryView`s provide user interaction with an `Inventory` of the matching type;
- an Inventory holds `ItemStack`s;
- an ItemStack is created from an `ItemType`.
- the ItemType stores default data, and is used in crafting recipes and item generators.

## Features:

- A variety of inventories, such as:
  - Basic
  - Grid (items take up a rectangle of tiles)
  - Restricted (can only put items with certain flags, like Equipment or Ammo)
  - Currency (custom max stack size, but only specified items)

- Crafting and shops:
  - Vending is a built-in feature of inventories, but for more configuration, use the `InventoryVendor` class!
  - Crafting recipes are defined through an `ItemConversion` - can give you pre-determined results, randomized counts, or a fresh new from an `ItemGenerator`!
  - Use `ItemPattern`s to match one of several items in filters or recipes, like different fuel types with different efficiency!

- Filter ground and inventory items via the versatile `ItemPattern` classes!
- Tooltips extensible with the `TooltipProperty` class!

#
Made by Don Tnowe in 2022.

[My Website](https://redbladegames.netlify.app)

[Itch](https://don-tnowe.itch.io)

[Twitter](https://twitter.com/don_tnowe)

Copying and Modification is allowed in accordance to the MIT license, unless otherwise specified. License text is included.

Font in example is [Abaddon, Licensed under Creative Commons Attribution 3.0.](https://caffinate.itch.io/abaddon)
