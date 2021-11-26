class X2EventListener_TRMoreUpgrades extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateStrategyListener());	
    Templates.AddItem(CreateTacticalListener());

	return Templates;
}

static final function CHEventListenerTemplate CreateStrategyListener()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'X2EventListener_TRMoreUpgrades_Strategy');

	Template.RegisterInStrategy = true;

	Template.AddCHEvent('OverrideItemIsModified', OverrideItemIsModified, ELD_Immediate);
    Template.AddCHEvent('OverrideHasGrenadePocket', GiveGrenadePocket, ELD_Immediate);
    Template.AddCHEvent('OverrideHasAmmoPocket', GiveAmmoPocket, ELD_Immediate);
    Template.AddCHEvent('OnArmoryMainMenuUpdate', UpdateArmoryUpgradeEquipment, ELD_Immediate);
    Template.AddCHEvent('OverrideNumUpgradeSlots', GiveMoreUpgradeSlots, ELD_Immediate);
    Template.AddCHEvent('UIArmory_WeaponUpgrade_SlotsUpdated', RemoveUpgrades, ELD_OnStateSubmitted);

	return Template; 
}

static final function CHEventListenerTemplate CreateTacticalListener()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'X2EventListener_TRMoreUpgrades_Tactical');

	Template.RegisterInTactical = true;

	Template.AddCHEvent('StasisVestHeal', RestoreWill, ELD_OnStateSubmitted);

	return Template; 
}

static function EventListenerReturn OverrideItemIsModified(Object EventData, Object EventSource, XComGameState NewGameState, Name EventID, Object CallbackObject)
{
	local XComLWTuple OverrideTuple;
    local XComGameState_Item ItemState;
    local array<X2WeaponUpgradeTemplate> WeaponUpgradeTemplates;
    local X2WeaponUpgradeTemplate WeaponUpgradeTemplate;
    local X2ArmorUpgradeTemplate ArmorUpgradeTemplate;

    OverrideTuple = XComLWTuple(EventData);
    ItemState = XComGameState_Item(EventSource);

    if (ItemState == none) return ELR_NoInterrupt;    

    if (ItemState.GetMyWeaponUpgradeCount() > 0)
    {
        WeaponUpgradeTemplates = ItemState.GetMyWeaponUpgradeTemplates();
        foreach WeaponUpgradeTemplates(WeaponUpgradeTemplate)
        {
            ArmorUpgradeTemplate = X2ArmorUpgradeTemplate(WeaponUpgradeTemplate);
            if (ArmorUpgradeTemplate == none) continue;

            OverrideTuple.Data[0].b = true;
            OverrideTuple.Data[1].b = true;
            return ELR_NoInterrupt;            
        }
    }

    return ELR_NoInterrupt;
}

static function EventListenerReturn GiveGrenadePocket(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComLWTuple Tuple;
	local XComGameState_Unit UnitState;
    local name AbilityName;

	UnitState = XComGameState_Unit(EventSource);	
	Tuple = XComLWTuple(EventData);

    foreach class'X2AbilityTemplateManager'.default.AbilityUnlocksGrenadePocket(AbilityName)
    {
        if (class'X2DownloadableContentInfo_WOTC_TRMoreUpgrades'.static.HasAbilityFromUpgrade(UnitState, AbilityName))
        {
            Tuple.Data[0].b = true;
            return ELR_NoInterrupt;
        }
    }	
	
	return ELR_NoInterrupt;
}

static function EventListenerReturn GiveAmmoPocket(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComLWTuple Tuple;
	local XComGameState_Unit UnitState;
    local name AbilityName;

	UnitState = XComGameState_Unit(EventSource);	
	Tuple = XComLWTuple(EventData);

    foreach class'X2AbilityTemplateManager'.default.AbilityUnlocksAmmoPocket(AbilityName)
    {
        if (class'X2DownloadableContentInfo_WOTC_TRMoreUpgrades'.static.HasAbilityFromUpgrade(UnitState, AbilityName))
        {
            Tuple.Data[0].b = true;
            return ELR_NoInterrupt;
        }
    }	
	
	return ELR_NoInterrupt;
}

static function EventListenerReturn UpdateArmoryUpgradeEquipment(Object EventData, Object EventSource, XComGameState NewGameState, Name Event, Object CallbackData)
{
    local UIArmory_MainMenu ArmoryMainMenu;
    local XComGameState_Unit Unit;
    local StateObjectReference ItemRef;
    local XComGameStateHistory XCOMHISTORY;
    local XComGameState_Item Item;
    local X2ArmorTemplate ArmorTemplate;    
    local TWeaponUpgradeAvailabilityData WeaponUpgradeAvailabilityData;

    XCOMHISTORY = `XCOMHISTORY;
    ArmoryMainMenu = UIArmory_MainMenu(EventSource);
    Unit = XComGameState_Unit(XCOMHISTORY.GetGameStateForObjectID(ArmoryMainMenu.UnitReference.ObjectID));

    class'UIUtilities_Strategy'.static.GetWeaponUpgradeAvailability(Unit, WeaponUpgradeAvailabilityData);

    // This needs to be aligned with UIArmory_MainMenu::UpdateData
    // If button is disabled (which is why we need this listener), and game has determined that no weapons can be upgraded, and modular weapons has been researched
    if (ArmoryMainMenu.WeaponUpgradeButton.bDisabled && !WeaponUpgradeAvailabilityData.bCanWeaponBeUpgraded && WeaponUpgradeAvailabilityData.bHasModularWeapons)
    {
        // Go through inventory items
        foreach Unit.InventoryItems(ItemRef)
        {
            Item = XComGameState_Item(XCOMHISTORY.GetGameStateForObjectID(ItemRef.ObjectID));
            
            // Interested with armor
            ArmorTemplate = X2ArmorTemplate(Item.GetMyTemplate());
            if (ArmorTemplate == none) continue;

            // If armor has upgrade slots, we should enable the button
            if (Item.GetNumUpgradeSlots() > 0)
            {
                ArmoryMainMenu.WeaponUpgradeButton.SetDisabled(false);

                // If there is available upgrades, give it some attention
                if (WeaponUpgradeAvailabilityData.bHasWeaponUpgrades)
                {
                    ArmoryMainMenu.WeaponUpgradeButton.NeedsAttention(true);
                }
            } 
        }        
    }    

	return ELR_NoInterrupt;
}

static function EventListenerReturn GiveMoreUpgradeSlots(Object EventData, Object EventSource, XComGameState NewGameState, Name EventID, Object CallbackObject)
{
	local XComLWTuple OverrideTuple;
    local XComGameState_Item ItemState;
    local array<X2WeaponUpgradeTemplate> WeaponUpgradeTemplates;
    local X2WeaponUpgradeTemplate WeaponUpgradeTemplate;
    local X2ArmorUpgradeTemplate ArmorUpgradeTemplate;

    OverrideTuple = XComLWTuple(EventData);
    ItemState = XComGameState_Item(EventSource);

    if (ItemState == none) return ELR_NoInterrupt;    

    if (ItemState.GetMyWeaponUpgradeCount() > 0)
    {
        WeaponUpgradeTemplates = ItemState.GetMyWeaponUpgradeTemplates();
        foreach WeaponUpgradeTemplates(WeaponUpgradeTemplate)
        {
            ArmorUpgradeTemplate = X2ArmorUpgradeTemplate(WeaponUpgradeTemplate);
            if (ArmorUpgradeTemplate == none) continue;

            OverrideTuple.Data[0].i += ArmorUpgradeTemplate.NumOfAdditionalSlots;            
        }
    }

    return ELR_NoInterrupt;
}

static function EventListenerReturn RemoveUpgrades(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackObject)
{
    local UIArmory_WeaponUpgrade UpgradeScreen;
    local XComGameState_Item Armor, AUItem;
    local X2ArmorTemplate ArmorTemplate;
    local array<X2WeaponUpgradeTemplate> WUTemplates, WUTemplatesCheck;
    local X2WeaponUpgradeTemplate WUTemplate, WUTemplateCheck;
    local X2ArmorUpgradeTemplate AUTemplate;
    local XComGameState NewGameState;
    local XComGameState_HeadquartersXCom XComHQ;
    local bool bRemoveUpgrades, bNeedsRequiredUpgrade, bHasRequiredUpgrade;

    UpgradeScreen = UIArmory_WeaponUpgrade(EventSource);
    Armor = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(UpgradeScreen.WeaponRef.ObjectID));

    ArmorTemplate = X2ArmorTemplate(Armor.GetMyTemplate());
    
    // If not an armor template, we bail so we dont impact the usual weapon upgrades.
    if (ArmorTemplate == none) return ELR_NoInterrupt;

    // We need to check if there are conflicting types of upgrades
    WUTemplates = Armor.GetMyWeaponUpgradeTemplates();

    // If there is only one upgrade (or less), this is not an issue. Bail.
    // if (WUTemplates.Length <= 1) return ELR_NoInterrupt;
    if (WUTemplates.Length == 0) return ELR_NoInterrupt;

    // If one of the upgrades disables Mutual Exclusions, this is not an issue so we bail.
    if (class'X2Item_TRMoreUpgrades'.static.HasUpgradeToDisableME(Armor)) return ELR_NoInterrupt;

    // Go through the upgrades
    WUTemplatesCheck = WUTemplates;
    foreach WUTemplates(WUTemplate)
    {
        AUTemplate = X2ArmorUpgradeTemplate(WUTemplate);
        if (AUTemplate == none) continue;

        // Tag that our current scenario has an upgrade that requires another upgrade
        if (AUTemplate.RequiredUpgrade != '') bNeedsRequiredUpgrade = true;

        foreach WUTemplatesCheck(WUTemplateCheck)
        {
            if (WUTemplate.DataName == WUTemplateCheck.DataName) continue;            

            if (WUTemplate.MutuallyExclusiveUpgrades.Find(WUTemplateCheck.DataName) != INDEX_NONE)
            {                
                bRemoveUpgrades = true;
                break;
            }

            // If the scenarios requires another upgrade, then we do the check to see if we have the required upgrade
            if (AUTemplate.RequiredUpgrade != '' && AUTemplate.RequiredUpgrade == WUTemplateCheck.DataName) bHasRequiredUpgrade = true;
        }
        if (bRemoveUpgrades) break;        
    }

    // If one of the upgrades requires another upgrade and we don't have the required upgrade, clear the upgrades from armor
    if (bNeedsRequiredUpgrade && !bHasRequiredUpgrade) bRemoveUpgrades = true;

    // If we are not removing upgrades, we should bail.
    if (!bRemoveUpgrades) return ELR_NoInterrupt;
    
    // Wipe upgrade templates on the armor, and then putting them back into XCOM Inventory
    NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Remove Upgrades and Add to HQ (Armor Upgrade)");
    Armor = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', Armor.ObjectID));
    Armor.WipeUpgradeTemplates();

    XComHQ = `XCOMHQ;
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

    foreach WUTemplates(WUTemplate)
    {   
        AUItem = WUTemplate.CreateInstanceFromTemplate(NewGameState);
        XComHQ.PutItemInInventory(NewGameState, AUItem);
    }

    `GAMERULES.SubmitGameState(NewGameState);

	UpgradeScreen.UpdateSlots();
	UpgradeScreen.WeaponStats.PopulateData(Armor);

    return ELR_NoInterrupt;
}

static function EventListenerReturn RestoreWill(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackObject)
{
    local XComGameState_Unit Unit;
    local float WillRestore;
    local XComGameState NewGameState;
    
    Unit = XComGameState_Unit(EventData);
    if (Unit == none) return ELR_NoInterrupt;
    if (!class'X2DownloadableContentInfo_WOTC_TRMoreUpgrades'.static.HasArmorUpgradeName(Unit, 'TRArmorUpgrade_TRStasisComp')) return ELR_NoInterrupt;
    
    WillRestore = Unit.GetMaxStat(eStat_Will) * class'X2Ability_MoreUpgradesAbilitySet'.default.TRStasisComp_WillRestore; 
    if (Unit.GetCurrentStat(eStat_Will) + WillRestore > Unit.GetMaxStat(eStat_Will))
        WillRestore = Unit.GetMaxStat(eStat_Will) - Unit.GetCurrentStat(eStat_Will);

    NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Restore Will (Armor Upgrade)");
    Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));    
       
    Unit.ModifyCurrentStat(eStat_Will, WillRestore);
    Unit.ModifyCurrentStat(eStat_HP, class'X2Ability_MoreUpgradesAbilitySet'.default.TRStasisComp_HPRestore);

    `GAMERULES.SubmitGameState(NewGameState);    

    return ELR_NoInterrupt;
}
