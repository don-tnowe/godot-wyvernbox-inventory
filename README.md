# Wyvernbox

An addon for versatile inventory systems.

- `InventoryView`s provide user interaction with an `Inventory`;
- an `Inventory` holds `ItemStack`s;
- an `ItemStack` is created from an `ItemType`.
- the ItemType stores default data, and is used in crafting recipes and item generators.

## Features:

- A variety of inventories, such as:
  - Basic
  - Grid (items take up a rectangle of tiles)
  - Restricted (can only put items with certain flags, like Equipment or Ammo)
  - Currency (infinite max count, but only specified items)

- Crafting and shops:
  - Vending is a built-in feature of inventories, but for more configuration, use the `InventoryVendor` class!
  - Crafting recipes are defined through an `ItemConversion` - can give you pre-determined results, randomized counts, or a fresh new from an `ItemGenerator`!
  - Use `ItemPattern`s to match one of several items in filters or recipes, like different fuel types with different efficiency!
