-- All Palworld-facing names live here. VERIFIED names were confirmed from the
-- 2026-07-30 game manifest and live runtime discovery. CANDIDATE names
-- must be confirmed by the F8 runtime diagnostic before mutation is enabled.

local Defs = {}

-- VERIFIED asset paths in the Palworld 1.0-era 2026-07-30 manifest.
Defs.FEED_BOX_CLASSES = {
    {
        class = "BP_BuildObject_PalFoodBox_C",
        path = "/Game/Pal/Blueprint/MapObject/BuildObject/BP_BuildObject_PalFoodBox.BP_BuildObject_PalFoodBox_C",
        cooled = false,
    },
    {
        class = "BP_BuildObject_PalFoodBoxCool_C",
        path = "/Game/Pal/Blueprint/MapObject/BuildObject/BP_BuildObject_PalFoodBoxCool.BP_BuildObject_PalFoodBoxCool_C",
        cooled = true,
    },
}

-- VERIFIED by the sibling Pin Pal mod on Palworld 0.7.x.
Defs.BASE_CAMP_CLASS = "PalBaseCampModel"
Defs.CONCRETE_MODEL_BASE_CLASS = "PalMapObjectConcreteModelBase"

-- CANDIDATE access paths. Discovery tries each without assuming one succeeds.
Defs.MODEL_FUNCTIONS = { "TryGetConcreteModel", "GetConcreteModel" }
Defs.MODEL_PROPERTIES = { "ConcreteModel", "Model", "MapObjectModel" }
Defs.OWNER_MODEL_FUNCTIONS = { "GetOwnerModel", "GetMapObjectModel", "GetModel" }
Defs.OWNER_MODEL_PROPERTIES = { "OwnerModel", "MapObjectModel", "Model" }
Defs.CONTAINER_MODULE_FUNCTIONS = { "GetItemContainerModule" }
Defs.CONTAINER_MODULE_PROPERTIES = { "ItemContainerModule" }
Defs.CONTAINER_FUNCTIONS = { "GetContainer" }
Defs.CONTAINER_PROPERTIES = { "Container" }
Defs.CONTAINER_ACCESS_FUNCTIONS = { "GetItemContainerAccess", "GetItemChestContainerAccess" }
Defs.CONTAINER_MANAGER_CLASSES = { "BP_PalItemContainerManager_C", "PalItemContainerManager" }
Defs.NETWORK_TRANSMITTER_CLASSES = { "BP_PalNetworkTransmitter_C", "PalNetworkTransmitter" }
Defs.KISMET_GUID_LIBRARY = "/Script/Engine.Default__KismetGuidLibrary"
Defs.BASE_FUNCTIONS = { "GetBaseCampModelBelongTo", "GetBaseCampModel" }
Defs.BASE_PROPERTIES = { "BaseCampModel", "BelongToBaseCampModel" }
Defs.GUILD_FUNCTIONS = { "GetGroupIdBelongTo", "GetOwnerGroupId", "GetGroupId", "GetGuildId" }
Defs.GUILD_PROPERTIES = { "OwnerGroupId", "GroupId", "GuildId", "OwnerGuildId" }

Defs.SLOT_ARRAY_PROPERTIES = { "ItemSlotArray", "Slots", "ItemSlots" }

-- VERIFIED from Pal_enums.hpp and the live Feed Box filter probe.
Defs.RAW_FOOD_TYPE_B = { [47] = true, [48] = true, [49] = true }
Defs.PREPARED_FOOD_TYPE_B = { [50] = true, [51] = true, [52] = true, [53] = true }
Defs.RAW_FOOD_FILTER_ID = "Food"
-- `Meal` is emitted by the current Feed Box UI for prepared food. The aliases
-- cover older naming variants seen in Palworld data and modding dumps.
Defs.PREPARED_FOOD_FILTER_IDS = {
    Meal = true,
    Dish = true,
    DishFood = true,
    CookedFood = true,
    ProcessedFood = true,
}

return Defs
