class X2Effect_TRPsiShield extends X2Effect_ModifyStats;

var array<StatChange> m_aStatChanges;
var int PsiDivisor; // Will only work if eStat_ShieldHP is one of the persistent stat changes

simulated function AddPersistentStatChange(ECharStatType StatType, float StatAmount, optional EStatModOp InModOp=MODOP_Addition )
{
	local StatChange NewChange;
	
	NewChange.StatType = StatType;
	NewChange.StatAmount = StatAmount;
	NewChange.ModOp = InModOp;

	m_aStatChanges.AddItem(NewChange);
}

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local int idx;
	local StatChange Change;
    local XComGameState_Unit Unit;

	NewEffectState.StatChanges = m_aStatChanges;
    Unit = XComGameState_Unit(kNewTargetState);
    
    if (Unit != none)
    {    
        for (idx = 0; idx < NewEffectState.StatChanges.Length; ++idx)
        {
            Change = NewEffectState.StatChanges[ idx ];     

            if (Change.StatType == eStat_ShieldHP && Change.ModOp == MODOP_Addition)
            {                
                NewEffectState.StatChanges[ idx ].StatAmount += Unit.GetMaxStat(eStat_PsiOffense) / PsiDivisor;
            }
        }
    }

	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}