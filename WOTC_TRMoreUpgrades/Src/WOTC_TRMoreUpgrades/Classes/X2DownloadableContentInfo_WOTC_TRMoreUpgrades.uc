class X2DownloadableContentInfo_WOTC_TRMoreUpgrades extends X2DownloadableContentInfo;

struct VestConversionData
{
	var name VestTemplateName;
    var array<name> GrantingTechs;
    var array<name> Schematics;
    var bool ForceDefaultIcon;
    var array<name> Abilities;    
    var bool bAllowOnSpark;
    var array<name> DisallowedArmors;
    var name bForceUpgradeType;
    var bool bDisablesMutualExclusiveRule;
    var int NumOfAdditionalSlots;
    var name RequiredUpgrade;
    var array<name> MutuallyExclusives;
};

struct AbilityConversionData
{
	var name AbilityName;
    var string strImg;
    var bool AddToSoldierEarnedAbilities;
    var bool ForceDefaultIcon;    
    var bool bAllowOnSpark;
    var array<name> DisallowedArmors;
    var name bForceUpgradeType;
    var bool bDisablesMutualExclusiveRule;
    var int NumOfAdditionalSlots;
    var name RequiredUpgrade;
    var array<name> MutuallyExclusives;
};

struct SlotToKillData
{
    var name DLC;
    var name SlotName;
};

struct BuildableItemAndRequiredTechData
{
    var name ItemName;
    var array<name> RequiredTechs;
};

var config array<name> VestTypes;
var config array<name> UtilityTypes;
var config (ArmorUpgrades) array<SlotToKillData> arrSlotsToKill;
var config (ArmorUpgrades) array<name> arrNotStartingItems;
var config (ArmorUpgrades) array<name> arrTechsWithVestCosts;
var config (ArmorUpgrades) bool bMakeExperimentalArmorAvailable;
var config (ArmorUpgrades) array<BuildableItemAndRequiredTechData> arrBuildableItemAndRequiredTechs;
var config (ArmorUpgrades) float ExperimentalArmorDurationScalar;

var localized string VestTinySummary;
var localized string UtilityTinySummary;
var localized string GoodColor;
var localized string BadColor;
var localized string strModule;
var localized string strModules;

// --------------------------------------------------
// DLC HOOKS
// --------------------------------------------------
static event OnPostTemplatesCreated()
{
    `LOG("Start of OPTC of Armor Upgrades", true, 'ArmorUpgrades');
    UpdateGhostTemplates();
    AdjustItems();
    KillSlots();  
    PatchAbilities();
    ApplyAbilityToArmors();
    BalanceChanges();
    `LOG("End of OPTC of Armor Upgrades", true, 'ArmorUpgrades');
}

static function bool CanWeaponApplyUpgrade(XComGameState_Item WeaponState, X2WeaponUpgradeTemplate UpgradeTemplate)
{
    local X2ArmorUpgradeTemplate ArmorUpgradeTemplate;
    local X2ArmorTemplate ArmorTemplate;
    local X2WeaponTemplate WeaponTemplate;
    
    // This way we make it so that any other weapon upgrades from other mods cannot be applied to armors
    ArmorTemplate = X2ArmorTemplate(WeaponState.GetMyTemplate());
    if (ArmorTemplate != none)
    {
        ArmorUpgradeTemplate = X2ArmorUpgradeTemplate(UpgradeTemplate);
        if (ArmorUpgradeTemplate == none)
        {
            return false;
        }              
    }

    WeaponTemplate = X2WeaponTemplate(WeaponState.GetMyTemplate());
    if (WeaponTemplate != none)
    {
        ArmorUpgradeTemplate = X2ArmorUpgradeTemplate(UpgradeTemplate);
        if (ArmorUpgradeTemplate != none)
        {
            return false;
        }  
    }
    
    return true;
}

/// <summary>
/// Called from XComGameState_Unit:GetEarnedSoldierAbilities
/// Allows DLC/Mods to add to and modify a unit's EarnedSoldierAbilities
/// Has no return value, just modify the EarnedAbilities out variable array
/// </summary>
/// HL-Docs: feature:ModifyEarnedSoldierAbilities; issue:409; tags:
/// This allows mods to add to or otherwise modify earned abilities for units.
/// For example, the Officer Pack can use this to attach learned officer abilities to the unit.
///
/// Note: abilities added this way will **not** be picked up by `XComGameState_Unit::HasSoldierAbility()`
///
/// Elements of the `EarnedAbilities` array are structs of type `SoldierClassAbilityType`.
/// Each element has the following parameters:
///  * AbilityName - template name of the ability that should be added to the unit.
///  * ApplyToWeaponSlot - inventory slot of the item that this ability should be attached to.
/// Being attached to the correct item is critical for abilities that rely on the source item, 
/// for example abilities that deal damage of the weapon they are attached to.
/// * UtilityCat - used only if `ApplyToWeaponSlot = eInvSlot_Utility`. Optional. 
/// If specified, the ability will be initialized for the unit when they enter tactical combat 
/// only if they have a weapon with the specified weapon category in one of their utility slots.
///
///```unrealscript
/// local SoldierClassAbilityType NewAbility;
///
/// NewAbility.AbilityName = 'PrimaryWeapon_AbilityTemplateName';
/// NewAbility.ApplyToWeaponSlot = eInvSlot_Primary;
///
/// EarnedAbilities.AddItem(NewAbility);
///
/// NewAbility.AbilityName = 'UtilityItem_AbilityTemplateName';
/// NewAbility.ApplyToWeaponSlot = eInvSlot_Utility;
/// NewAbility.UtilityCat = 'UtilityItemWeaponCategory';
///
/// EarnedAbilities.AddItem(NewAbility);
///```
static function ModifyEarnedSoldierAbilities(out array<SoldierClassAbilityType> EarnedAbilities, XComGameState_Unit UnitState)
{
	local XComGameState_Item InventoryItem;	
	local array<XComGameState_Item> CurrentInventory;
    local X2ArmorTemplate ArmorTemplate;
    local array<X2WeaponUpgradeTemplate> WeaponUpgradeTemplates;
    local X2WeaponUpgradeTemplate WeaponUpgradeTemplate;
    local X2ArmorUpgradeTemplate ArmorUpgradeTemplate;
    local SoldierClassAbilityType NewSoldierClassAbilityType;
    
	CurrentInventory = UnitState.GetAllInventoryItems();
    
	foreach CurrentInventory(InventoryItem)
	{
        ArmorTemplate = X2ArmorTemplate(InventoryItem.GetMyTemplate());    
        if (ArmorTemplate != none)
        {
            WeaponUpgradeTemplates = InventoryItem.GetMyWeaponUpgradeTemplates();
            foreach WeaponUpgradeTemplates(WeaponUpgradeTemplate)
            {
                ArmorUpgradeTemplate = X2ArmorUpgradeTemplate(WeaponUpgradeTemplate);            
                if (ArmorUpgradeTemplate == none) continue;                
                if (EarnedAbilities.Find('AbilityName', ArmorUpgradeTemplate.AbilityName) == INDEX_NONE && ArmorUpgradeTemplate.AddToSoldierEarnedAbilities)
                {
                    NewSoldierClassAbilityType.AbilityName = ArmorUpgradeTemplate.AbilityName;
                    EarnedAbilities.AddItem(NewSoldierClassAbilityType);
                }
            }
        }        
	}
}

static function FinalizeUnitAbilitiesForInit(XComGameState_Unit UnitState, out array<AbilitySetupData> SetupData, optional XComGameState StartState, optional XComGameState_Player PlayerState, optional bool bMultiplayerDisplay)
{
    local AbilitySetupData AbilitySetup;
    local X2AbilityTemplateManager AbilityMan;
    local X2AbilityTemplate AbilityTemplate;
    local XComGameState_HeadquartersXCom XCOMHQ;
    local array<XComGameState_Tech> CompletedTechs;
    local XComGameState_Tech Tech;
    local bool HasUpgradeType;

    XCOMHQ = `XCOMHQ;
    AbilityMan = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
    HasUpgradeType = HasArmorUpgradeByType(UnitState, 'vest');

    if (XCOMHQ.bReinforcedUnderlay && HasUpgradeType)
    {        
        AbilityTemplate = AbilityMan.FindAbilityTemplate('PurifierAutopsyVestBonus');

        if (AbilityTemplate != none)
        {
            AbilitySetup.TemplateName = AbilityTemplate.DataName;
            AbilitySetup.Template = AbilityTemplate;
            SetupData.AddItem(AbilitySetup);
        }

        AbilityTemplate = AbilityMan.FindAbilityTemplate('RustyUnderlayPassive');

        if (IsModLoaded('WOTCRustyUnderlay') && AbilityTemplate != none)
        {
            AbilitySetup.TemplateName = AbilityTemplate.DataName;
            AbilitySetup.Template = AbilityTemplate;
            SetupData.AddItem(AbilitySetup);
        }        
    }

    CompletedTechs = XCOMHQ.GetAllCompletedTechStates();

    foreach CompletedTechs(Tech)
    {
        if (Tech.GetMyTemplateName() != 'AutopsyAdventSynthoid') continue;
        
        AbilityTemplate = AbilityMan.FindAbilityTemplate('SynthoidAutopsyBonus');

        if (IsModLoaded('EnemyKnownSynthoid') && AbilityTemplate != none && HasUpgradeType)
        {
            AbilitySetup.TemplateName = AbilityTemplate.DataName;
            AbilitySetup.Template = AbilityTemplate;
            SetupData.AddItem(AbilitySetup);
            break;
        }  
    }
}

// --------------------------------------------------
// HELPERS
// --------------------------------------------------

// Changes to ghost templates should only be done here and nowhere else or your PC will blow up
static function UpdateGhostTemplates()
{
    local X2ItemTemplateManager ItemTemplateMgr;    
    local X2EquipmentTemplate VestTemplate;
    local X2ArmorUpgradeTemplate ArmorUpgradeTemplate;          
    local string AUTemplateName;
    local VestConversionData VestsToConvert;
    local AbilityConversionData AbilitiesToConvert;

    ItemTemplateMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();    
    
    foreach class'X2Item_TRMoreUpgrades'.default.arrVestsToConvert(VestsToConvert)
    {
        AUTemplateName = 'TRArmorUpgrade_' $VestsToConvert.VestTemplateName;
        ArmorUpgradeTemplate = X2ArmorUpgradeTemplate(ItemTemplateMgr.FindItemTemplate(name(AUTemplateName)));
        VestTemplate = X2EquipmentTemplate(ItemTemplateMgr.FindItemTemplate(VestsToConvert.VestTemplateName));      

        if (VestTemplate == none) continue;
        if (ArmorUpgradeTemplate == none) continue;

        // Copy data from vest
        CopyDataFromVestTemplate(ArmorUpgradeTemplate, VestTemplate);

        // Append manually configured abilities
        AppendAbilities(ArmorUpgradeTemplate);

        // Update localization
        UpdateLocalization(ArmorUpgradeTemplate, VestTemplate);        

        // Sets up upgrade image by getting the icons from the abilities
        UpgradeIcons(ArmorUpgradeTemplate);

        // Override the upgrade type to something else
        OverrideUpgradeType(ArmorUpgradeTemplate);

        // Sets up the delegate for required upgrade
        SetUpDelegateForRequiredUpgrade(ArmorUpgradeTemplate);

        // Sometimes, we cannot have everything via config
        UpdateTemplate(ArmorUpgradeTemplate);
	}
    
    foreach class'X2Item_TRMoreUpgrades'.default.arrAbilitiesToConvert(AbilitiesToConvert)
    {
        AUTemplateName = 'TRArmorUpgrade_' $AbilitiesToConvert.AbilityName;
        ArmorUpgradeTemplate = X2ArmorUpgradeTemplate(ItemTemplateMgr.FindItemTemplate(name(AUTemplateName)));

        if (ArmorUpgradeTemplate == none) continue;

        // Update localization
        UpdateLocalization(ArmorUpgradeTemplate);   

        // Sets up upgrade image by getting the icons from the abilities
        UpgradeIcons(ArmorUpgradeTemplate);

        // Override the upgrade type to something else
        OverrideUpgradeType(ArmorUpgradeTemplate);

        // Sets up the delegate for required upgrade
        SetUpDelegateForRequiredUpgrade(ArmorUpgradeTemplate);

        // Sometimes, we cannot have everything via config
        UpdateTemplate(ArmorUpgradeTemplate);
    }

    // These had to be separated out from the 2 loops above because of OverrideUpgradeType() that messes with VestTypes and UtilityTypes
    foreach class'X2Item_TRMoreUpgrades'.default.arrVestsToConvert(VestsToConvert)
    {
        AUTemplateName = 'TRArmorUpgrade_' $VestsToConvert.VestTemplateName;
        ArmorUpgradeTemplate = X2ArmorUpgradeTemplate(ItemTemplateMgr.FindItemTemplate(name(AUTemplateName)));
        if (ArmorUpgradeTemplate == none) continue;
        SetUpMutualExclusives(ArmorUpgradeTemplate);
    }

    foreach class'X2Item_TRMoreUpgrades'.default.arrAbilitiesToConvert(AbilitiesToConvert)
    {
        AUTemplateName = 'TRArmorUpgrade_' $AbilitiesToConvert.AbilityName;
        ArmorUpgradeTemplate = X2ArmorUpgradeTemplate(ItemTemplateMgr.FindItemTemplate(name(AUTemplateName)));
        if (ArmorUpgradeTemplate == none) continue;
        SetUpMutualExclusives(ArmorUpgradeTemplate);
    }
}

static function UpdateLocalization(out X2ArmorUpgradeTemplate ArmorUpgradeTemplate, optional X2EquipmentTemplate VestTemplate)
{
    local UIStatMarkup StatMarkUp;
    local UIAbilityStatMarkup AbilityStatMarkUp;
    local X2AbilityTemplateManager AbilityTemplateMan;
    local X2AbilityTemplate AbilityTemplate;

    if (ArmorUpgradeTemplate.Type == 'vest' && VestTemplate != none) 
    {
        ArmorUpgradeTemplate.FriendlyName = VestTemplate.FriendlyName @default.strModule;
        ArmorUpgradeTemplate.FriendlyNamePlural = VestTemplate.FriendlyName @default.strModules;
        ArmorUpgradeTemplate.TacticalText = VestTemplate.TacticalText;

        if(ArmorUpgradeTemplate.TinySummary == "")
            ArmorUpgradeTemplate.TinySummary = default.VestTinySummary;

        foreach VestTemplate.UIStatMarkups(StatMarkUp)
        {            
            if (StatMarkUp.StatModifier > 0)
                ArmorUpgradeTemplate.BriefSummary $= "<Bullet/> " $StatMarkUp.StatLabel $": <font color='" $default.GoodColor $"'>" $StatMarkUp.StatModifier $"</font>\n";
            else
                ArmorUpgradeTemplate.BriefSummary $= "<Bullet/> " $StatMarkUp.StatLabel $": <font color='" $default.BadColor  $"'>" $StatMarkUp.StatModifier $"</font>\n";

            ArmorUpgradeTemplate.SetUIStatMarkup(StatMarkUp.StatLabel, StatMarkup.StatType, StatMarkup.StatModifier);        
        }

        ArmorUpgradeTemplate.BriefSummary $= VestTemplate.TacticalText;  
        if (ArmorUpgradeTemplate.BriefSummary == "") ArmorUpgradeTemplate.BriefSummary = VestTemplate.BriefSummary;
    }    
    else if (ArmorUpgradeTemplate.Type == 'utility')
    {   
        if (ArmorUpgradeTemplate.TinySummary == "")
            ArmorUpgradeTemplate.TinySummary = default.UtilityTinySummary;

        AbilityTemplateMan = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
        AbilityTemplate = AbilityTemplateMan.FindAbilityTemplate(ArmorUpgradeTemplate.AbilityName);
        
        if (AbilityTemplate == none)
        {
            ArmorUpgradeTemplate.RewardDecks.Length = 0; // We hide the item from being obtained
            return;
        }

        foreach AbilityTemplate.UIStatMarkups(AbilityStatMarkUp)
        {
            ArmorUpgradeTemplate.SetUIStatMarkup(AbilityStatMarkUp.StatLabel, AbilityStatMarkUp.StatType, AbilityStatMarkUp.StatModifier);
        }
    }  
}

// For adjusting items/abilities the armor upgrades were converted from. Do it nowhere else!
static function AdjustItems()
{
    local X2ItemTemplateManager ItemTemplateMgr;
    local VestConversionData VestToConvert;
    local X2EquipmentTemplate VestTemplate;
    local name TechTemplateName, SchematicName, NotStartingItem;
    local X2StrategyElementTemplateManager StrategyTemplateMgr;
    local X2TechTemplate TechTemplate;
    local X2SchematicTemplate SchematicTemplate;
    local StrategyRequirement BlankRequirement;
    local string Temp;
    local array<X2DataTemplate> DataTemplates;
    local X2DataTemplate DataTemplate;
    local array<X2DataTemplate> DataTemplates_Inner;
    local X2DataTemplate DataTemplate_Inner;
    local X2ItemTemplate ItemTemplate;
    local int CostIndex, ConfigIndex;
    
    ItemTemplateMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
    StrategyTemplateMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager(); 
    
    foreach class'X2Item_TRMoreUpgrades'.default.arrVestsToConvert(VestToConvert)
    {       
        ItemTemplateMgr.FindDataTemplateAllDifficulties(VestToConvert.VestTemplateName, DataTemplates);

        foreach DataTemplates(DataTemplate)
        {
            VestTemplate = X2EquipmentTemplate(DataTemplate);            
            if (VestTemplate == none) continue;

            // Kills vest templates from buildable
            VestTemplate.Requirements = BlankRequirement;
            VestTemplate.Requirements.RequiredScienceScore = 99999;
            VestTemplate.RewardDecks.Length = 0;
            VestTemplate.CanBeBuilt = false;
            VestTemplate.StartingItem = false;        

            // Since we are killing vest slot let's assign all vests to eInvSlot_Utility
            // Just in case there are vests that were missed out
            VestTemplate.InventorySlot = eInvSlot_Utility;

            // Replaces vest granted from techs
            foreach VestToConvert.GrantingTechs(TechTemplateName)
            {                
                StrategyTemplateMgr.FindDataTemplateAllDifficulties(TechTemplateName, DataTemplates_Inner);

                foreach DataTemplates_Inner(DataTemplate_Inner)
                {
                    TechTemplate = X2TechTemplate(DataTemplate_Inner);            
                    if (TechTemplate == none) continue;

                    TechTemplate.ItemRewards.Length = 0;
                    Temp = "TRArmorUpgrade_" $VestTemplate.DataName;                    
                    TechTemplate.ItemRewards.AddItem(name(Temp));
                }
            }

            // Replaces vest granted from schematics
            foreach VestToConvert.Schematics(SchematicName)
            {
                ItemTemplateMgr.FindDataTemplateAllDifficulties(SchematicName, DataTemplates_Inner);

                foreach DataTemplates_Inner(DataTemplate_Inner)
                {
                    SchematicTemplate = X2SchematicTemplate(DataTemplate_Inner);
                    if (SchematicTemplate == none) continue;

                    SchematicTemplate.ItemRewards.Length = 0;
                    Temp = "TRArmorUpgrade_" $VestTemplate.DataName;
                    SchematicTemplate.ItemRewards.AddItem(name(Temp));
                    SchematicTemplate.ReferenceItemTemplate = name(Temp);
                }

            }
        }
    }
    
    // Sets items as non starting items if configured
    // Not needed for items converted to armor upgrades
    foreach default.arrNotStartingItems(NotStartingItem)
    {
        ItemTemplateMgr.FindDataTemplateAllDifficulties(NotStartingItem, DataTemplates);

        foreach DataTemplates(DataTemplate)
        {
            ItemTemplate = X2ItemTemplate(DataTemplate);
            if (ItemTemplate == none) continue;
            ItemTemplate.StartingItem = false;
        }
    }

    // There are mods that uses vests as costs, so we need to replace them with its equivalent armor upgrade
    foreach default.arrTechsWithVestCosts(TechTemplateName)
    {
        StrategyTemplateMgr.FindDataTemplateAllDifficulties(TechTemplateName, DataTemplates);

        foreach DataTemplates(DataTemplate)
        {
            TechTemplate = X2TechTemplate(DataTemplate);            
            if (TechTemplate == none) continue;
                    
            for (CostIndex = 0; CostIndex < TechTemplate.Cost.ResourceCosts.Length; CostIndex++)
            {                        
                ConfigIndex = class'X2Item_TRMoreUpgrades'.default.arrVestsToConvert.Find('VestTemplateName', TechTemplate.Cost.ResourceCosts[CostIndex].ItemTemplateName);
                if (ConfigIndex != INDEX_NONE)
                {
                    Temp = "TRArmorUpgrade_" $class'X2Item_TRMoreUpgrades'.default.arrVestsToConvert[ConfigIndex].VestTemplateName;
                    TechTemplate.Cost.ResourceCosts[CostIndex].ItemTemplateName = name(Temp);
                }
            }
        }
    }
}

static function UpgradeIcons(out X2ArmorUpgradeTemplate ArmorUpgradeTemplate)
{
    local name AbilityName;    
    local X2AbilityTemplateManager AbilityTemplateManager;
    local X2AbilityTemplate AbilityTemplate;
    local UpgradeSlotHelper NonWeaponUpgradeSlot;

    AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

    if (IsForceDefaultIcon(ArmorUpgradeTemplate))
    {
        foreach class'CHHelpers'.default.NonWeaponUpgradeSlots(NonWeaponUpgradeSlot)
        {
            ArmorUpgradeTemplate.AddUpgradeAttachment('', '', "", "", NonWeaponUpgradeSlot.TemplateName, , "", ArmorUpgradeTemplate.strImage, "img:///UILibrary_PerkIcons.UIPerk_item_nanofibervest");            
        }
        return;
    }

    foreach ArmorUpgradeTemplate.BonusAbilities(AbilityName)
    {
        AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityName);

        if (AbilityTemplate == none) continue;
        if (AbilityTemplate.IconImage == "" && ArmorUpgradeTemplate.BonusAbilities.Length > 1) continue; // If there is more than one abilities, we will try to grab icon from the next one
        // if (AbilityTemplate.IconImage == "") AbilityTemplate.IconImage = "img:///UILibrary_PerkIcons.UIPerk_item_nanofibervest"; // No icon eh, give it a default

        if (AbilityTemplate.IconImage == "")
        {
            if (ArmorUpgradeTemplate.Type == 'vest') AbilityTemplate.IconImage = "img:///UILibrary_PerkIcons.UIPerk_item_nanofibervest";
            else if (ArmorUpgradeTemplate.Type == 'utility') AbilityTemplate.IconImage = "img:///TRMoreUpgrades_Package.Item_TeleportDisc";
            else AbilityTemplate.IconImage = "img:///UILibrary_PerkIcons.UIPerk_item_nanofibervest";
        }

        foreach class'CHHelpers'.default.NonWeaponUpgradeSlots(NonWeaponUpgradeSlot)
        {
            ArmorUpgradeTemplate.AddUpgradeAttachment('', '', "", "", NonWeaponUpgradeSlot.TemplateName, , "", ArmorUpgradeTemplate.strImage, AbilityTemplate.IconImage);            
        }

        break; // Only need one of the abilities as the icon
    }
}

static function bool IsForceDefaultIcon(X2ArmorUpgradeTemplate ArmorUpgradeTemplate)
{
    local array<VestConversionData> arrVestsToConvertCopy;
    local array<AbilityConversionData> arrAbilitiesToConvertCopy;
    local int ConfigIndex;

    arrVestsToConvertCopy = class'X2Item_TRMoreUpgrades'.default.arrVestsToConvert;
    if (arrVestsToConvertCopy.Find('VestTemplateName', ArmorUpgradeTemplate.VestTemplateName) != INDEX_NONE)
    {
        ConfigIndex = arrVestsToConvertCopy.Find('VestTemplateName', ArmorUpgradeTemplate.VestTemplateName);
        if (arrVestsToConvertCopy[ConfigIndex].ForceDefaultIcon)
        {
            return true;
        }
    }

    arrAbilitiesToConvertCopy = class'X2Item_TRMoreUpgrades'.default.arrAbilitiesToConvert;
    if (arrAbilitiesToConvertCopy.Find('AbilityName', ArmorUpgradeTemplate.AbilityName) != INDEX_NONE)
    {
        ConfigIndex = arrAbilitiesToConvertCopy.Find('AbilityName', ArmorUpgradeTemplate.AbilityName);
        if (arrAbilitiesToConvertCopy[ConfigIndex].ForceDefaultIcon)
        {
            return true;
        }
    }

    return false;
}

static function CopyDataFromVestTemplate(out X2ArmorUpgradeTemplate ArmorUpgradeTemplate, X2EquipmentTemplate VestTemplate)
{
    local name AbilityName, RequiredTech;
    local int CostIndex, ConfigIndex;
    local string Temp;
    local array<name> RequiredTechs;

    foreach VestTemplate.Abilities(AbilityName)
    {
        ArmorUpgradeTemplate.BonusAbilities.AddItem(AbilityName);            
    }
    
    ArmorUpgradeTemplate.strImage = VestTemplate.strImage;

    // If the upgrade already has a cost associated, it means it was done via StrategyTuning config and
    // should not overwrite here
    if (ArmorUpgradeTemplate.Cost.ResourceCosts.Length == 0 && ArmorUpgradeTemplate.Cost.ArtifactCosts.Length == 0)
    {
        ArmorUpgradeTemplate.Cost = VestTemplate.Cost;
    }

    // Solving bug: PGOv2 configs are overwritten by blank required techs. The way this is done is very "patchy" and requires the least effort
    // Save tech requirements
    RequiredTechs = ArmorUpgradeTemplate.Requirements.RequiredTechs;
    ArmorUpgradeTemplate.Requirements = VestTemplate.Requirements;  

    // Afterwards we put them back without overwriting what we got from the vest template
    foreach RequiredTechs(RequiredTech)
    {
        ArmorUpgradeTemplate.Requirements.RequiredTechs.AddItem(RequiredTech);
    }

    ArmorUpgradeTemplate.RewardDecks = VestTemplate.RewardDecks;
    ArmorUpgradeTemplate.CanBeBuilt = VestTemplate.CanBeBuilt;

    // If our upgrade has a required tech, we have to assume that its actually buildable
    if (ArmorUpgradeTemplate.Requirements.RequiredTechs.Length > 0 && !ArmorUpgradeTemplate.CanBeBuilt)
        ArmorUpgradeTemplate.CanBeBuilt = true;

    ArmorUpgradeTemplate.TradingPostValue = VestTemplate.TradingPostValue;    
    ArmorUpgradeTemplate.StartingItem = VestTemplate.StartingItem;
    ArmorUpgradeTemplate.bInfiniteItem = VestTemplate.bInfiniteItem;

    // LeadHazmatVest has HazmatVest as cost so we need to adjust that
    for (CostIndex = 0; CostIndex < ArmorUpgradeTemplate.Cost.ResourceCosts.Length; CostIndex++)
    {
        ConfigIndex = class'X2Item_TRMoreUpgrades'.default.arrVestsToConvert.Find('VestTemplateName', ArmorUpgradeTemplate.Cost.ResourceCosts[CostIndex].ItemTemplateName);

        if (ConfigIndex != INDEX_NONE)
        {
            Temp = "TRArmorUpgrade_" $class'X2Item_TRMoreUpgrades'.default.arrVestsToConvert[ConfigIndex].VestTemplateName;
            ArmorUpgradeTemplate.Cost.ResourceCosts[CostIndex].ItemTemplateName = name(Temp);
        }
    }
}

static function KillSlots()
{
    local CHItemSlotStore ItemSlotManager;
    local CHItemSlot SlotTemplate;
    local array<X2DataTemplate> DataTemplates;
    local int i;
    local SlotToKillData SlotToKill;

    foreach default.arrSlotsToKill(SlotToKill)
    {
        if (!IsModLoaded(SlotToKill.DLC)) continue; // Technically this is not needed, but I have done it, so...

        ItemSlotManager = class'CHItemSlotStore'.static.GetStore();
        ItemSlotManager.FindDataTemplateAllDifficulties(SlotToKill.SlotName, DataTemplates);

        for (i = 0; i < DataTemplates.Length; i++)
        {
            SlotTemplate = CHItemSlot(DataTemplates[i]);            
            if (SlotTemplate == none) continue;
            SlotTemplate.UnitHasSlotFn = NeverGetThisSlot;
        }        
    }
}

static function bool HasAbilityFromUpgrade(XComGameState_Unit UnitState, name AbilityName)
{    
	local XComGameState_Item InventoryItem;	
	local array<XComGameState_Item> CurrentInventory;
    local X2ArmorTemplate ArmorTemplate;
    local array<X2WeaponUpgradeTemplate> WeaponUpgradeTemplates;
    local X2WeaponUpgradeTemplate WeaponUpgradeTemplate;
    local X2ArmorUpgradeTemplate ArmorUpgradeTemplate;
    
	CurrentInventory = UnitState.GetAllInventoryItems();
    
	foreach CurrentInventory(InventoryItem)
	{
        ArmorTemplate = X2ArmorTemplate(InventoryItem.GetMyTemplate());    
        if (ArmorTemplate != none)
        {
            WeaponUpgradeTemplates = InventoryItem.GetMyWeaponUpgradeTemplates();
            foreach WeaponUpgradeTemplates(WeaponUpgradeTemplate)
            {
                ArmorUpgradeTemplate = X2ArmorUpgradeTemplate(WeaponUpgradeTemplate);            
                if (ArmorUpgradeTemplate == none) continue;
                if (ArmorUpgradeTemplate.AbilityName == AbilityName) return true;
            }
        }        
	}	

    return false;
}

static function bool IsModLoaded(name DLCName)
{
    local XComOnlineEventMgr    EventManager;
    local int                   Index;

    EventManager = `ONLINEEVENTMGR;

    for(Index = EventManager.GetNumDLC() - 1; Index >= 0; Index--)  
    {
        if(EventManager.GetDLCNames(Index) == DLCName)  
        {
            return true;
        }
    }
    return false;
}

static function SetUpMutualExclusives(out X2ArmorUpgradeTemplate Template)
{
    local int ConfigIndex;
    local name AUTemplateName;
    local array<VestConversionData> VestsToConvert;
    local array<AbilityConversionData> AbilitiesToConvert;

    if (Template.bDisablesMutualExclusiveRule) return;
    
    if (Template.Type == 'vest')
        Template.MutuallyExclusiveUpgrades = default.VestTypes;
    else if (Template.Type == 'utility')
        Template.MutuallyExclusiveUpgrades = default.UtilityTypes;

    VestsToConvert = class'X2Item_TRMoreUpgrades'.default.arrVestsToConvert;
    AbilitiesToConvert = class'X2Item_TRMoreUpgrades'.default.arrAbilitiesToConvert;

    ConfigIndex = VestsToConvert.Find('VestTemplateName', Template.VestTemplateName);

    if (ConfigIndex != INDEX_NONE
        && VestsToConvert[ConfigIndex].MutuallyExclusives.Length > 0)
    {
        foreach VestsToConvert[ConfigIndex].MutuallyExclusives(AUTemplateName)
        {
            Template.MutuallyExclusiveUpgrades.AddItem(AUTemplateName);
        }
    }

    ConfigIndex = INDEX_NONE; //Reset
    ConfigIndex = AbilitiesToConvert.Find('AbilityName', Template.AbilityName);

    if (ConfigIndex != INDEX_NONE
        && AbilitiesToConvert[ConfigIndex].MutuallyExclusives.Length > 0)
    {
        foreach AbilitiesToConvert[ConfigIndex].MutuallyExclusives(AUTemplateName)
        {
            Template.MutuallyExclusiveUpgrades.AddItem(AUTemplateName);
        }
    }
}

static function UpdateTemplate(out X2ArmorUpgradeTemplate AUTemplate)
{    

}

static function SetUpDelegateForRequiredUpgrade(out X2ArmorUpgradeTemplate AUTemplate)
{              
    if (AUTemplate.RequiredUpgrade == '') return;    

    switch (AUTemplate.RequiredUpgrade)
    {
        case 'TRArmorUpgrade_PlatedVest': AUTemplate.Requirements.SpecialRequirementsFn = IsPlatedVestAvailable; break;
        case 'TRArmorUpgrade_HazmatVest': AUTemplate.Requirements.SpecialRequirementsFn = IsHazmatVestAvailable; break;
        case 'TRArmorUpgrade_StasisVest': AUTemplate.Requirements.SpecialRequirementsFn = IsStasisVestAvailable; break;
    }
}

static function PatchAbilities()
{
    local X2AbilityTemplateManager AbilityTemplateManager;
    local X2AbilityTemplate AbilityTemplate;
    local X2Condition_AbilitySourceArmor WeaponCondition;

    AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
    AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate('StasisVestBonus');

    PatchStasisVestBonus(AbilityTemplate);    

    if (!IsModLoaded('WOTC_LW2_Plating')) return;
    
    AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate('LW2WOTC_CeramicPlating_Ability');

    if (AbilityTemplate == none) return;    
    
    WeaponCondition = new class'X2Condition_AbilitySourceArmor';    
    AbilityTemplate.AbilityShooterConditions.AddItem(WeaponCondition);
    AbilityTemplate.bDisplayInUITacticalText = true;
    AbilityTemplate.IconImage = "img:///UILibrary_PerkIcons.UIPerk_item_nanofibervest";
}

static function PatchStasisVestBonus(X2AbilityTemplate AbilityTemplate)
{
    local X2Effect Effect;
    local X2Effect_Regeneration RegenEffect;

    foreach AbilityTemplate.AbilityTargetEffects(Effect)
    {
        RegenEffect = X2Effect_Regeneration(Effect);
        if (RegenEffect == none) continue;

        RegenEffect.EventToTriggerOnHeal = 'StasisVestHeal';
    }
}

static function ApplyAbilityToArmors()
{
    local X2ItemTemplateManager ItemTemplateMan;    
    local X2ArmorTemplate ArmorTemplate;
    local array<X2DataTemplate> DataTemplates;
    local X2DataTemplate DataTemplate;
    local array<X2EquipmentTemplate> EqTemplates;
    local X2EquipmentTemplate EqTemplate;
    
    if (!IsModLoaded('WOTC_LW2_Plating')) return;

    ItemTemplateMan = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
    EqTemplates = ItemTemplateMan.GetAllArmorTemplates();

    foreach EqTemplates(EqTemplate)
    {
        ItemTemplateMan.FindDataTemplateAllDifficulties(EqTemplate.DataName, DataTemplates);
        foreach DataTemplates(DataTemplate)
        {
            ArmorTemplate = X2ArmorTemplate(DataTemplate);
            if (ArmorTemplate == none) continue;

            ArmorTemplate.Abilities.AddItem('LW2WOTC_CeramicPlating_Ability');
        }    
    }    
}

static function AppendAbilities(out X2ArmorUpgradeTemplate ArmorUpgradeTemplate)
{
    local name AbilityName;
    local int ConfigIndex;
    local array<VestConversionData> arrVestsToConvertCopy;
    local X2AbilityTemplateManager AbilityTemplateMan;
    
    // There are instances when the abilities have to be manually added to the upgrade template.
    // For example: Iridar's IRI_CritImmunityPassive from [WOTC] Iridar's Vest and Plating Overhaul.
    // This ability is added via WSR, and WSR does it via UISL. In this mod's OPTC, this ability
    // will not be picked up hence the need to have a manual way to append abilities to upgrade template.
    
    AbilityTemplateMan = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
    arrVestsToConvertCopy = class'X2Item_TRMoreUpgrades'.default.arrVestsToConvert;
    ConfigIndex = arrVestsToConvertCopy.Find('VestTemplateName', ArmorUpgradeTemplate.VestTemplateName);

    if (ConfigIndex == INDEX_NONE) return;
    if (arrVestsToConvertCopy[ConfigIndex].Abilities.Length == 0) return;

    foreach arrVestsToConvertCopy[ConfigIndex].Abilities(AbilityName)    
    {
        // If ability is invalid continue the loop
        if (AbilityTemplateMan.FindAbilityTemplate(AbilityName) == none) continue;

        ArmorUpgradeTemplate.BonusAbilities.AddItem(AbilityName);
    }    
}

static function bool HasArmorUpgradeName(XComGameState_Unit Unit, name ArmorUpgradeTemplateName)
{
    local StateObjectReference ItemRef;
    local XComGameState_Item Item;
    local XComGameStateHistory History;
    local X2ArmorTemplate ArmorTemplate;
    local array<name> AUTemplateNames;

    History = `XCOMHISTORY;

    foreach Unit.InventoryItems(ItemRef)
    {
        Item = XComGameState_Item(History.GetGameStateForObjectID(ItemRef.ObjectID));
        ArmorTemplate = X2ArmorTemplate(Item.GetMyTemplate());
        if (ArmorTemplate == none) continue;

        AUTemplateNames = Item.GetMyWeaponUpgradeTemplateNames();
        if (AUTemplateNames.Find(ArmorUpgradeTemplateName) != INDEX_NONE)
            return true;
        
    }
    return false;
}

static function bool HasArmorUpgradeByType(XComGameState_Unit Unit, name Type)
{
    local StateObjectReference ItemRef;
    local XComGameState_Item Item;
    local XComGameStateHistory History;
    local X2ArmorTemplate ArmorTemplate;
    local array<X2WeaponUpgradeTemplate> WUTemplates;
    local X2WeaponUpgradeTemplate WUTemplate;    
    local X2ArmorUpgradeTemplate AUTemplate;      

    History = `XCOMHISTORY;

    foreach Unit.InventoryItems(ItemRef)
    {
        Item = XComGameState_Item(History.GetGameStateForObjectID(ItemRef.ObjectID));
        ArmorTemplate = X2ArmorTemplate(Item.GetMyTemplate());
        if (ArmorTemplate == none) continue;

        WUTemplates = Item.GetMyWeaponUpgradeTemplates();
        foreach WUTemplates(WUTemplate)
        {
            AUTemplate = X2ArmorUpgradeTemplate(WUTemplate);
            if (AUTemplate == none) continue;
            if (AUTemplate.Type == Type)
            {
                return true;                
            }
        }
    }
    return false;
}

// This is currently unused as its giving slots to armors that should not get any in the first place e.g. Civillian Disguise
static function GiveDefaultSlots()
{
    local X2ItemTemplateManager ItemTemplateMgr;
    local X2DataTemplate Template;
    local X2ArmorTemplate ArmorTemplate;
    local array<UpgradeSlotHelper> ArmorUpgradeSlots;
    local UpgradeSlotHelper ArmorUpgradeSlot;
    local int ConfigIndex;    

    ItemTemplateMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

    foreach ItemTemplateMgr.IterateTemplates(Template)
    {
        ArmorTemplate = X2ArmorTemplate(Template);

        if (ArmorTemplate == none) continue;
        if (ArmorTemplate.ItemCat != 'armor') continue;

        ArmorUpgradeSlots = class'CHHelpers'.default.NonWeaponUpgradeSlots;
        ConfigIndex = ArmorUpgradeSlots.Find('TemplateName', ArmorTemplate.DataName);

        if (ConfigIndex == INDEX_NONE)
        {            
            ArmorUpgradeSlot.TemplateName = ArmorTemplate.DataName;            
            ArmorUpgradeSlot.NumUpgradeSlots = 1;
            class'CHHelpers'.default.NonWeaponUpgradeSlots.AddItem(ArmorUpgradeSlot);
        }
    }    
}

static function OverrideUpgradeType(out X2ArmorUpgradeTemplate AUTemplate)
{
    local name Type;

    Type = GetTypeOverride(AUTemplate);
    
    if (Type != '') AUTemplate.Type = Type;
    else return;

    // This bit is important so that mutual exclusive rule remains intact
    if (Type == 'vest')
    {
        default.UtilityTypes.RemoveItem(AUTemplate.DataName);
        default.VestTypes.AddItem(AUTemplate.DataName);
    }
    else if (Type == 'utility')
    {
        default.VestTypes.RemoveItem(AUTemplate.DataName);
        default.UtilityTypes.AddItem(AUTemplate.DataName);
    }
}

static function name GetTypeOverride(X2ArmorUpgradeTemplate AUTemplate)
{
    local array<VestConversionData> VestsToConvert;
    local array<AbilityConversionData> AbilitiesToConvert;
    local int CfgIdx;

    VestsToConvert = class'X2Item_TRMoreUpgrades'.default.arrVestsToConvert;
    AbilitiesToConvert = class'X2Item_TRMoreUpgrades'.default.arrAbilitiesToConvert;

    if (AUTemplate.Type == 'vest')
    {
        CfgIdx = VestsToConvert.Find('VestTemplateName', AUTemplate.VestTemplateName);

        if (CfgIdx != INDEX_NONE && VestsToConvert[CfgIdx].bForceUpgradeType != '')
        {
            return VestsToConvert[CfgIdx].bForceUpgradeType;
        }
    }
    else if (AUTemplate.Type == 'utility')
    {
        CfgIdx = AbilitiesToConvert.Find('AbilityName', AUTemplate.AbilityName);

        if (CfgIdx != INDEX_NONE && AbilitiesToConvert[CfgIdx].bForceUpgradeType != '')
        {
            return AbilitiesToConvert[CfgIdx].bForceUpgradeType;
        }
    }

    return '';
}

static function BalanceChanges()
{
    local BuildableItemAndRequiredTechData BuildableItemAndRequiredTechs;
    local X2TechTemplate TechTemplate;
    local X2StrategyElementTemplateManager StratMan;
    local array<X2DataTemplate> DataTemplates;
    local X2DataTemplate DataTemplate;

    if (default.bMakeExperimentalArmorAvailable) ClearRequiredTechsFromTech('ExperimentalArmor');

    foreach default.arrBuildableItemAndRequiredTechs(BuildableItemAndRequiredTechs)    
    {
        MakeItemBuildableAndAssignRequiredTech(BuildableItemAndRequiredTechs.ItemName, BuildableItemAndRequiredTechs.RequiredTechs);
    }

    StratMan = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
    StratMan.FindDataTemplateAllDifficulties('ExperimentalArmor', DataTemplates);

    foreach DataTemplates(DataTemplate)
    {
        TechTemplate = X2TechTemplate(DataTemplate);
        if (TechTemplate == none) continue;

        TechTemplate.PointsToComplete = int(TechTemplate.PointsToComplete * default.ExperimentalArmorDurationScalar);
    }
}

static function ClearRequiredTechsFromTech(name TechName)
{
    local X2StrategyElementTemplateManager StratTemplateMan;
    local array<X2DataTemplate> DataTemplates;
    local X2DataTemplate DataTemplate;
    local X2TechTemplate TechTemplate;

    StratTemplateMan = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
    StratTemplateMan.FindDataTemplateAllDifficulties(TechName, DataTemplates);

    foreach DataTemplates(DataTemplate)
    {
        TechTemplate = X2TechTemplate(DataTemplate);
        if (TechTemplate == none) continue;

        TechTemplate.Requirements.RequiredTechs.Length = 0;
    }
}

static function MakeItemBuildableAndAssignRequiredTech(name ItemName, array<name> RequiredTechs)
{
    local X2ItemTemplateManager ItemTemplateMan;
    local array<X2DataTemplate> DataTemplates;
    local X2DataTemplate DataTemplate;
    local X2ItemTemplate ItemTemplate;

    ItemTemplateMan = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
    ItemTemplateMan.FindDataTemplateAllDifficulties(ItemName, DataTemplates);

    foreach DataTemplates(DataTemplate)
    {
        ItemTemplate = X2ItemTemplate(DataTemplate);
        if (ItemTemplate == none) continue;
        
        ItemTemplate.CanBeBuilt = true;
        ItemTemplate.RewardDecks.Length = 0;
        ItemTemplate.Requirements.RequiredTechs.Length = 0;
        ItemTemplate.Requirements.RequiredTechs = RequiredTechs;
    }
}

// --------------------------------------------------
// DELEGATES
// --------------------------------------------------
static function bool NeverGetThisSlot(CHItemSlot Slot, XComGameState_Unit UnitState, out string LockedReason, optional XComGameState CheckGameState)
{
    return false;
}

// Sadly this delegate does not pass ItemTemplate so we need to have one delegate per item with RequiredUpgrade
static function bool IsPlatedVestAvailable()
{      
    local XComGameState_HeadquartersXCom XCOMHQ;
    local StateObjectReference UnitRef;
    local XComGameState_Unit Unit;
    local XComGameStateHistory History;
    local name AUTemplateName;
    
    XCOMHQ = `XCOMHQ;
    History = `XCOMHISTORY;
    AUTemplateName = 'TRArmorUpgrade_PlatedVest';

    if (XCOMHQ.HasItemByName(AUTemplateName)) return true;

    foreach XCOMHQ.Crew(UnitRef)
    {
        Unit = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
        if (Unit == none || !Unit.IsSoldier()) continue;

        if (HasArmorUpgradeName(Unit, AUTemplateName)) return true;
    }
}

static function bool IsHazmatVestAvailable()
{      
    local XComGameState_HeadquartersXCom XCOMHQ;
    local StateObjectReference UnitRef;
    local XComGameState_Unit Unit;
    local XComGameStateHistory History;
    local name AUTemplateName;
    
    XCOMHQ = `XCOMHQ;
    History = `XCOMHISTORY;
    AUTemplateName = 'TRArmorUpgrade_HazmatVest';

    if (XCOMHQ.HasItemByName(AUTemplateName)) return true;

    foreach XCOMHQ.Crew(UnitRef)
    {
        Unit = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
        if (Unit == none || !Unit.IsSoldier()) continue;

        if (HasArmorUpgradeName(Unit, AUTemplateName)) return true;
    }
}

static function bool IsStasisVestAvailable()
{      
    local XComGameState_HeadquartersXCom XCOMHQ;
    local StateObjectReference UnitRef;
    local XComGameState_Unit Unit;
    local XComGameStateHistory History;
    local name AUTemplateName;
    
    XCOMHQ = `XCOMHQ;
    History = `XCOMHISTORY;
    AUTemplateName = 'TRArmorUpgrade_StasisVest';

    if (XCOMHQ.HasItemByName(AUTemplateName)) return true;

    foreach XCOMHQ.Crew(UnitRef)
    {
        Unit = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
        if (Unit == none || !Unit.IsSoldier()) continue;

        if (HasArmorUpgradeName(Unit, AUTemplateName)) return true;
    }
}

// --------------------------------------------------
// CONSOLE COMMANDS
// --------------------------------------------------
exec function LogVestTemplateNames()
{
    local X2ItemTemplateManager ItemTemplateMgr;
    local X2DataTemplate Template;
    local X2EquipmentTemplate EqTemplate;
    local X2ItemTemplate AUTemplate;
    local name RequiredTech;
    local string strRequiredTechs;
    local string AUTemplateName;
    local bool bConverted;

    ItemTemplateMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

    foreach ItemTemplateMgr.IterateTemplates(Template)
    {
        EqTemplate = X2EquipmentTemplate(Template);

        if (EqTemplate == none) continue;
        if (EqTemplate.ItemCat != 'defense') continue;

        AUTemplateName = "TRArmorUpgrade_" $EqTemplate.DataName;
        AUTemplate = ItemTemplateMgr.FindItemTemplate(name(AUTemplateName));
        if (AUTemplate != none) bConverted = true;
        else bConverted = false;

        if (AUTemplate != none)
        {            
            foreach AUTemplate.Requirements.RequiredTechs(RequiredTech)
            {
                strRequiredTechs $= RequiredTech $"-";
            }
        }

        `LOG(EqTemplate.DataName $" :: " $EqTemplate.GetItemFriendlyNameNoStats() $" Converted: " $bConverted $" RequiredTechs: " $strRequiredTechs, true, 'ArmorUpgrades');
        class'Helpers'.static.OutputMsg(EqTemplate.DataName $" :: " $EqTemplate.GetItemFriendlyNameNoStats() $" :: Converted: " $bConverted $" RequiredTechs: " $strRequiredTechs, 'ArmorUpgrades');

        strRequiredTechs = "";
    }
}

exec function LogArmorTemplateNames()
{
    local X2ItemTemplateManager ItemTemplateMgr;
    local X2DataTemplate Template;
    local X2ArmorTemplate ArmorTemplate;
    local array<UpgradeSlotHelper> ArmorUpgradeSlots;
    local int ConfigIndex, NoOfSlots;

    ItemTemplateMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

    foreach ItemTemplateMgr.IterateTemplates(Template)
    {
        ArmorTemplate = X2ArmorTemplate(Template);

        if (ArmorTemplate == none) continue;
        if (ArmorTemplate.ItemCat != 'armor') continue;

        ArmorUpgradeSlots = class'CHHelpers'.default.NonWeaponUpgradeSlots;
        ConfigIndex = ArmorUpgradeSlots.Find('TemplateName', ArmorTemplate.DataName);

        if (ConfigIndex == INDEX_NONE)
        {
            NoOfSlots = 0;
        }
        else
        {
            NoOfSlots = ArmorUpgradeSlots[ConfigIndex].NumUpgradeSlots;
        }

        `LOG(ArmorTemplate.DataName $" :: " $ArmorTemplate.GetItemFriendlyNameNoStats() $" :: NumUpgradeSlots: " $NoOfSlots, true, 'ArmorUpgrades');
        class'Helpers'.static.OutputMsg(ArmorTemplate.DataName $" :: " $ArmorTemplate.GetItemFriendlyNameNoStats(), 'ArmorUpgrades');
    }
}

exec function LogArmorUpgradeTemplateNames()
{
    local X2ItemTemplateManager ItemTemplateMgr;
    local X2DataTemplate Template;
    local X2ArmorUpgradeTemplate ArmorUpgradeTemplate;

    ItemTemplateMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

    foreach ItemTemplateMgr.IterateTemplates(Template)
    {
        ArmorUpgradeTemplate = X2ArmorUpgradeTemplate(Template);

        if (ArmorUpgradeTemplate == none) continue;        

        `LOG(ArmorUpgradeTemplate.DataName $" :: " $ArmorUpgradeTemplate.GetItemFriendlyNameNoStats() $" Buildable: " $ArmorUpgradeTemplate.CanBeBuilt, true, 'ArmorUpgrades');
        class'Helpers'.static.OutputMsg(ArmorUpgradeTemplate.DataName $" :: " $ArmorUpgradeTemplate.GetItemFriendlyNameNoStats() $" Buildable: " $ArmorUpgradeTemplate.CanBeBuilt, 'ArmorUpgrades');
    }
}

exec function ConvertAllRelevantItemsToUpgrades(bool bTestMode)
{
    local int i;
    local array<StateObjectReference> HQInventory;
    local XComGameState_Item ItemState, AUState;
    local X2ArmorUpgradeTemplate AUTemplate;
    local XComGameState NewGameState;
    local XComGameState_HeadquartersXCom XCOMHQ;
    local X2ItemTemplateManager ItemTemplateMan;
    local name AUTemplateName;
    local bool bUpdated;
    
    XCOMHQ = `XCOMHQ;
    HQInventory = `XCOMHQ.Inventory;
    ItemTemplateMan = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
    NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Adding Converted Armor Upgrade Item");

    for (i = 0; i < HQInventory.Length; i++)
    {
        ItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(HQInventory[i].ObjectID));
        if (ItemState == none) continue;

        if (class'X2Item_TRMoreUpgrades'.default.arrVestsToConvert.Find('VestTemplateName', ItemState.GetMyTemplateName()) == INDEX_NONE) continue;

        AUTemplateName = name("TRArmorUpgrade_" $ItemState.GetMyTemplateName());
        AUTemplate = X2ArmorUpgradeTemplate(ItemTemplateMan.FindItemTemplate(AUTemplateName));
        if (AUTemplate == none) continue;

        class'Helpers'.static.OutputMsg("Current Item in HQ : " $ItemState.GetMyTemplateName() $" x " $ItemState.Quantity, 'ArmorUpgrades');
        class'Helpers'.static.OutputMsg("To be replaced with: " $AUTemplate.DataName, 'ArmorUpgrades');

        if (bTestMode) continue;

        AUState = AUTemplate.CreateInstanceFromTemplate(NewGameState);
        if (AUState == none) continue;
        
        AUState.Quantity = ItemState.Quantity;

        XCOMHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XCOMHQ.ObjectID));
        ItemState = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', ItemState.ObjectID));

        XCOMHQ.Inventory.RemoveItem(ItemState.GetReference());
        NewGameState.RemoveStateObject(ItemState.ObjectID);
        XCOMHQ.PutItemInInventory(NewGameState, AUState);

        bUpdated = true;        
    }

    if (bUpdated)
        `GAMERULES.SubmitGameState(NewGameState);
    else
        `XCOMHISTORY.CleanupPendingGameState(NewGameState);
}

exec function LogMutualExclusiveArrays()
{
    local name GenericName;

    `LOG("Vest Array:-----------------------------", true, 'ArmorUpgrades');
    class'Helpers'.static.OutputMsg("Vest Array:-----------------------------", 'ArmorUpgrades');

    foreach default.VestTypes(GenericName)
    {
        `LOG(GenericName, true, 'ArmorUpgrades');
        class'Helpers'.static.OutputMsg(string(GenericName), 'ArmorUpgrades');
    }

    `LOG("Utility Array:-----------------------------", true, 'ArmorUpgrades');
    class'Helpers'.static.OutputMsg("Utility Array:-----------------------------", 'ArmorUpgrades');

    foreach default.UtilityTypes(GenericName)
    {
        `LOG(GenericName, true, 'ArmorUpgrades');
        class'Helpers'.static.OutputMsg(string(GenericName), 'ArmorUpgrades');
    }
}

exec function TR_RemoveItem (name TemplateName, optional int Quantity = 1)
{
    local XComGameState_HeadquartersXCom XCOMHQ, NewXCOMHQ;
    local StateObjectReference ItemRef;
    local XComGameStateHistory History;
    local XComGameState_Item ItemState, NewItemState;
    local XComGameState NewGameState;
    local bool bRemoveItem;

    XCOMHQ = `XCOMHQ;
    History = `XCOMHISTORY;

    if (XCOMHQ == none || History == none)
    {
        return;
    }

    foreach XCOMHQ.Inventory(ItemRef)
    {
        ItemState = XComGameState_Item(History.GetGameStateForObjectID(ItemRef.ObjectID));
        if (ItemState == none) continue;

        if (ItemState.GetMyTemplateName() == TemplateName)
        {
            if (ItemState.GetMyTemplate().bInfiniteItem)
            {
                class'Helpers'.static.OutputMsg("Item " $TemplateName @"is an infinite item. Aborting.", 'ArmorUpgrades');
                return;
            }

            bRemoveItem = true;
            break;
        }
    }

    if (bRemoveItem)
    {
        NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Armor Upgrade: Removing Item from HQ");
        NewItemState = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', ItemState.ObjectID));        

        if (NewItemState.Quantity <= Quantity)
        {
            NewXCOMHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XCOMHQ.ObjectID));
            NewXCOMHQ.Inventory.RemoveItem(NewItemState.GetReference());
            NewGameState.RemoveStateObject(NewItemState.ObjectID);
            class'Helpers'.static.OutputMsg("Item " $NewItemState.GetMyTemplateName() @"completely removed from XCOM HQ", 'ArmorUpgrades');
        }
        else
        {
            NewItemState.Quantity -= Quantity;
            class'Helpers'.static.OutputMsg("Item " $NewItemState.GetMyTemplateName() @"new quantity is" @NewItemState.Quantity, 'ArmorUpgrades');
        }

        `GAMERULES.SubmitGameState(NewGameState);
    }
    else
    {
        class'Helpers'.static.OutputMsg("Item " $TemplateName @"not found in XCOM HQ", 'ArmorUpgrades');
    }
    
}