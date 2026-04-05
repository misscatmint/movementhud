static Handle HudSync;

MHudBoolPreference IndicatorsMode;
MHudRGBPreference IndicatorsColor;
MHudRGBPreference IndicatorsJBColor;
MHudRGBPreference IndicatorsPBColor;
MHudXYPreference IndicatorsPosition;

MHudBoolPreference IndicatorsJBEnabled;
MHudBoolPreference IndicatorsCJEnabled;
MHudBoolPreference IndicatorsPBEnabled;
MHudBoolPreference IndicatorsEBEnabled;

MHudBoolPreference IndicatorsAbbreviations;

MHudBoolPreference IndicatorsFTGEnabled;
MHudBoolPreference IndicatorsCrouchEnabled;

void OnPluginStart_Elements_Mode_Indicators()
{
    IndicatorsMode = new MHudBoolPreference("indicators_mode", "Indicators - Mode", true);
    SetPreferenceNamePhraseKey(IndicatorsMode, "pref.indicators_mode");

    IndicatorsPosition = new MHudXYPreference("indicators_position", "Indicators - Position", 550, 725);
    SetPreferenceNamePhraseKey(IndicatorsPosition, "pref.indicators_position");
}

void OnPluginStart_Elements_Other_Indicators()
{
    HudSync = CreateHudSynchronizer();

    IndicatorsColor = new MHudRGBPreference("indicators_color", "Indicators - Color", 0, 255, 0);
    SetPreferenceNamePhraseKey(IndicatorsColor, "pref.indicators_color");

    IndicatorsJBColor = new MHudRGBPreference("indicators_jb_color", "Indicators - Jump Bug Color", 0, 255, 0);
    SetPreferenceNamePhraseKey(IndicatorsJBColor, "pref.indicators_jb_color");

    IndicatorsPBColor = new MHudRGBPreference("indicators_pb_color", "Indicators - Perfect Bhop Color", 0, 255, 0);
    SetPreferenceNamePhraseKey(IndicatorsPBColor, "pref.indicators_pb_color");

    IndicatorsJBEnabled = new MHudBoolPreference("indicators_jb_enabled", "Indicators - Jump Bug", false);
    SetPreferenceNamePhraseKey(IndicatorsJBEnabled, "pref.indicators_jb_enabled");

    IndicatorsCJEnabled = new MHudBoolPreference("indicators_cj_enabled", "Indicators - Crouch Jump", false);
    SetPreferenceNamePhraseKey(IndicatorsCJEnabled, "pref.indicators_cj_enabled");

    IndicatorsPBEnabled = new MHudBoolPreference("indicators_pb_enabled", "Indicators - Perfect Bhop", false);
    SetPreferenceNamePhraseKey(IndicatorsPBEnabled, "pref.indicators_pb_enabled");

    IndicatorsEBEnabled = new MHudBoolPreference("indicators_eb_enabled", "Indicators - Edge Bug", false);
    SetPreferenceNamePhraseKey(IndicatorsEBEnabled, "pref.indicators_eb_enabled");

    IndicatorsFTGEnabled = new MHudBoolPreference("indicators_ftg", "Indicators - First Tick Gain", false);
    SetPreferenceNamePhraseKey(IndicatorsFTGEnabled, "pref.indicators_ftg");

    IndicatorsCrouchEnabled = new MHudBoolPreference("indicators_crouch", "Indicators - Crouch Status", false);
    SetPreferenceNamePhraseKey(IndicatorsCrouchEnabled, "pref.indicators_crouch");

    IndicatorsAbbreviations = new MHudBoolPreference("indicators_abbrs", "Indicators - Abbreviations", true);
    SetPreferenceNamePhraseKey(IndicatorsAbbreviations, "pref.indicators_abbrs");
}

void OnGameFrame_Element_Indicators(int client, int target)
{
    bool draw = IndicatorsMode.GetBool(client);
    bool drawJB = IndicatorsJBEnabled.GetBool(client) && gB_DidJumpBug[target];
    bool drawCJ = IndicatorsCJEnabled.GetBool(client) && gB_DidCrouchJump[target];
    bool drawPB = IndicatorsPBEnabled.GetBool(client) && gB_DidPerf[target];
    bool drawEB = IndicatorsEBEnabled.GetBool(client) && gB_DidEdgeBug[target];
    bool drawFTG = IndicatorsFTGEnabled.GetBool(client) && gB_FirstTickGain[target];
    bool isCrouched = (GetEntityFlags(target) & FL_DUCKING == FL_DUCKING);
    bool isInAir = !(GetEntityFlags(target) & FL_ONGROUND == FL_ONGROUND);
    bool notHoldingCrouch = !(gI_Buttons[target] & IN_DUCK == IN_DUCK);
    bool drawCrouch = IndicatorsCrouchEnabled.GetBool(client) && isCrouched && isInAir && notHoldingCrouch;

    // Nothing enabled
    if (!draw || (!drawJB && !drawCJ && !drawPB && !drawEB && !drawFTG && !drawCrouch))
    {
        return;
    }

    int rgb[3];
    if (drawJB)
    {
        IndicatorsJBColor.GetRGB(client, rgb);
    }
    else if (drawPB)
    {
        IndicatorsPBColor.GetRGB(client, rgb);
    }
    else
    {
        IndicatorsColor.GetRGB(client, rgb);
    }

    float xy[2];
    IndicatorsPosition.GetXY(client, xy);

    Call_OnDrawIndicators(client, xy, rgb);
    SetHudTextParams(xy[0], xy[1], GetTextHoldTimeMHUD(client), rgb[0], rgb[1], rgb[2], 255, _, _, 0.0, 0.0);

    bool useAbbr = IndicatorsAbbreviations.GetBool(client);

    char buffer[64];
    if (drawJB)
    {
        char label[32];
        GetIndicatorLabel(client, useAbbr, "indicator_abbr.jumpbug", "indicator.jumpbug", label, sizeof(label));

        Format(buffer, sizeof(buffer), "%s%s\n",
            buffer,
            label
        );
    }

    if (drawCJ)
    {
        char label[32];
        GetIndicatorLabel(client, useAbbr, "indicator_abbr.crouch_jump", "indicator.crouch_jump", label, sizeof(label));

        Format(buffer, sizeof(buffer), "%s%s\n",
            buffer,
            label
        );
    }

    if (drawPB)
    {
        char label[32];
        GetIndicatorLabel(client, useAbbr, "indicator_abbr.perfect_bhop", "indicator.perfect_bhop", label, sizeof(label));

        Format(buffer, sizeof(buffer), "%s%s\n",
            buffer,
            label
        );
    }

    if (drawEB)
    {
        char label[32];
        GetIndicatorLabel(client, useAbbr, "indicator_abbr.edge_bug", "indicator.edge_bug", label, sizeof(label));

        Format(buffer, sizeof(buffer), "%s%s\n",
            buffer,
            label
        );
    }

    if (drawFTG)
    {
        char label[32];
        GetIndicatorLabel(client, useAbbr, "indicator_abbr.first_tick_gain", "indicator.first_tick_gain", label, sizeof(label));

        Format(buffer, sizeof(buffer), "%s%s\n",
            buffer,
            label
        );
    }

    if (drawCrouch)
    {
        char label[32];
        GetIndicatorLabel(client, useAbbr, "indicator_abbr.crouched", "indicator.crouched", label, sizeof(label));

        Format(buffer, sizeof(buffer), "%s%s\n",
            buffer,
            label
        );
    }
    ShowSyncHudText(client, HudSync, "%s", buffer);
}
