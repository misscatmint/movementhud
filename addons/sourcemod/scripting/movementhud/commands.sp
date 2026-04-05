void OnPluginStart_Commands()
{
    RegConsoleCmd("sm_mhud", Command_MHud);
    RegConsoleCmd("sm_mhud_export", Command_MHud_Export);
    RegConsoleCmd("sm_mhud_import", Command_MHud_Import);

    RegConsoleCmd("sm_mhud_preferences", Command_MHud_Preferences);

    // Backwards compat aliases
    RegConsoleCmd("sm_mhud_settings_export", Command_MHud_Export);
    RegConsoleCmd("sm_mhud_settings_import", Command_MHud_Import);

    RegConsoleCmd("sm_mhud_preferences_export", Command_MHud_Export);
    RegConsoleCmd("sm_mhud_preferences_import", Command_MHud_Import);
}

void HookPreferenceCommand(Preference preference)
{
    char cmdName[64];
    Format(cmdName, sizeof(cmdName), "sm_mhud_%s", preference.Id);

    if (!CommandExists(cmdName))
    {
        RegConsoleCmd(cmdName, Command_Preference, "MovementHUD preference command");
    }
}

public Action Command_MHud(int client, int args)
{
    char mode[32];
    GetCmdArg(1, mode, sizeof(mode));

    if (StrEqual(mode, "a")
        || StrEqual(mode, "adv")
        || StrEqual(mode, "advanced")
    ) {
        DisplayPreferencesMenu(client, true);
        return Plugin_Handled;
    }

    if (StrEqual(mode, "s") || StrEqual(mode, "simple"))
    {
        DisplayPreferencesMenu(client, false);
        return Plugin_Handled;
    }

    DisplayMainMenu(client);
    return Plugin_Handled;
}

public Action Command_MHud_Export(int client, int args)
{
    char code[256];
    GeneratePreferencesCode(client, code, sizeof(code));

    PrintToConsole(client, "%s\n", code);
    return Plugin_Handled;
}

public Action Command_MHud_Import(int client, int args)
{
    char code[256];
    GetCmdArgString(code, sizeof(code));

    bool loaded = LoadFromPreferencesCode(client, code);
    if (!loaded)
    {
        MHud_PrintToChat(client, "%T", "chat.import_failed", GetTranslationTarget(client));
        return Plugin_Handled;
    }

    MHud_PrintToChat(client, "%T", "chat.import_success", GetTranslationTarget(client));
    return Plugin_Handled;
}

public Action Command_MHud_Preferences(int client, int args)
{
    char szPage[16];
    GetCmdArg(1, szPage, sizeof(szPage));

    int entriesPerPage = 10;
    int availablePages = RoundToCeil(g_Preferences.Length / float(entriesPerPage));

    int page = MHud_ClampInt(StringToInt(szPage), 1, availablePages);

    // Slicing
    int cursor = (page - 1) * entriesPerPage;
    int goUntil = MHud_ClampInt(page * entriesPerPage, 0, g_Preferences.Length);

    PrintToConsole(client, "%T", "console.page_header", GetTranslationTarget(client), page, availablePages);

    for (int i = cursor; i < goUntil; i++)
    {
        Preference preference;
        g_Preferences.GetArray(i, preference);

        char name[128];
        GetPreferenceDisplayName(client, preference, name, sizeof(name));

        PrintToConsole(client, "- sm_mhud_%s (%s)", preference.Id, name);
    }

    if (page < availablePages)
    {
        char cmdName[64];
        GetCmdArg(0, cmdName, sizeof(cmdName));

        PrintToConsole(client, "%T", "console.more_preferences", GetTranslationTarget(client), cmdName, page + 1);
    }

    PrintToConsole(client, "");
    return Plugin_Handled;
}

public Action Command_Preference(int client, int args)
{
    char cmdName[64];
    GetCmdArg(0, cmdName, sizeof(cmdName));

    Preference preference;

    bool found = GetPreferenceById(cmdName[8], preference);
    if (!found)
    {
        // Commands cannot be unregistered, so
        // plugins unloaded since registration will end up here
        return Plugin_Handled;
    }

    char szArgs[256];
    GetCmdArgString(szArgs, sizeof(szArgs));

    char action[32];
    int valueIdx = BreakString(szArgs, action, sizeof(action));

    if (StrEqual(action, "get", false))
    {
        HandleGetCommand(client, preference);
        return Plugin_Handled;
    }

    if (StrEqual(action, "set", false))
    {
        HandleSetCommand(client, preference, szArgs[valueIdx]);
        return Plugin_Handled;
    }

    if (StrEqual(action, "info", false))
    {
        HandleInfoCommand(client, preference);
        return Plugin_Handled;
    }

    if (StrEqual(action, "cycle", false))
    {
        HandleCycleCommand(client, preference);
        return Plugin_Handled;
    }

    if (StrEqual(action, "reset", false))
    {
        HandleResetCommand(client, preference);
        return Plugin_Handled;
    }

    char format[64];
    GetPreferenceFormat(client, true, preference, format, sizeof(format));

    char name[128];
    GetPreferenceDisplayName(client, preference, name, sizeof(name));

    PrintToConsole(client, "%T", "console.usage_header", GetTranslationTarget(client), MHUD_TAG_RAW, name);
    PrintToConsole(client, "- %s get", cmdName);
    PrintToConsole(client, "- %s set %s", cmdName, format);
    PrintToConsole(client, "- %s info", cmdName);
    PrintToConsole(client, "- %s cycle", cmdName);
    PrintToConsole(client, "- %s reset", cmdName);
    return Plugin_Handled;
}

// =====[ PRIVATE ]=====

static void HandleGetCommand(int client, Preference preference)
{
    char value[MHUD_MAX_VALUE];
    GetPreferenceValue(client, preference, value);

    char name[128];
    GetPreferenceDisplayName(client, preference, name, sizeof(name));

    PrintToConsole(client, "%s %s: %s", MHUD_TAG_RAW, name, value);
}

static void HandleSetCommand(int client, Preference preference, char[] value)
{
    if (GetCmdArgs() <= 1)
    {
        char format[64];
        GetPreferenceFormat(client, true, preference, format, sizeof(format));

        char cmdName[64];
        GetCmdArg(0, cmdName, sizeof(cmdName));

        PrintToConsole(client, "%T", "console.usage_set", GetTranslationTarget(client), cmdName, format);
        return;
    }

    bool isSet = SetPreferenceValue(client, preference, value);
    if (!isSet)
    {
        return;
    }

    PrintChangeMessage(client, preference);
}

static void HandleInfoCommand(int client, Preference preference)
{
    char type[32] = "N/A";
    preference.Metadata.GetString("type", type, sizeof(type));

    char typeDisplay[32];
    GetLocalizedPreferenceType(client, type, typeDisplay, sizeof(typeDisplay));

    char format[64];
    GetPreferenceFormat(client, true, preference, format, sizeof(format));

    char defaultVal[MHUD_MAX_VALUE];
    GetPreferenceDefault(preference.Id, defaultVal);

    char pluginFile[PLATFORM_MAX_PATH];
    GetPluginFilename(preference.OwningPlugin, pluginFile, sizeof(pluginFile));

    char name[128];
    GetPreferenceDisplayName(client, preference, name, sizeof(name));

    PrintToConsole(client, "%s", MHUD_TAG_RAW);
    PrintToConsole(client, "- %T: %s", "console.label_id", GetTranslationTarget(client), preference.Id);
    PrintToConsole(client, "- %T: %s", "console.label_name", GetTranslationTarget(client), name);
    PrintToConsole(client, "- %T: %s", "console.label_type", GetTranslationTarget(client), typeDisplay);
    PrintToConsole(client, "- %T: %s", "console.label_format", GetTranslationTarget(client), format);
    PrintToConsole(client, "- %T: %s", "console.label_provider", GetTranslationTarget(client), pluginFile);
    PrintToConsole(client, "- %T: %s", "console.label_default_value", GetTranslationTarget(client), defaultVal);
}

static void HandleCycleCommand(int client, Preference preference)
{
    char value[MHUD_MAX_VALUE];

    bool hasCapability = Call_GetNextHandler(client, preference, value);
    if (!hasCapability)
    {
        return;
    }

    bool isSet = SetPreferenceValue(client, preference, value);
    if (!isSet)
    {
        return;
    }

    PrintChangeMessage(client, preference);
}

static void HandleResetCommand(int client, Preference preference)
{
    // TODO: Param to bypass hooks?
    SetPreferenceValue(client, preference, preference.DefaultValue);
    PrintChangeMessage(client, preference);
}
