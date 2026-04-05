static Handle InputTimer[MAXPLAYERS + 1];

static int InputMenuSelection[MAXPLAYERS + 1];
static char InputPreferenceId[MAXPLAYERS + 1][MHUD_MAX_ID];

void OnClientPutInServer_PreferencesChatInput(int client)
{
	ResetWaitForPreferenceChatInputFromClient(client);
}

void WaitForPreferenceChatInputFromClient(int client, char preferenceId[MHUD_MAX_ID], int menuSelection = 0)
{
	Preference preference;

	bool found = GetPreferenceById(preferenceId, preference);
	if (!found)
	{
		return;
	}

	InputTimer[client] = CreateTimeoutTimer(client);
	InputPreferenceId[client] = preferenceId;
	InputMenuSelection[client] = menuSelection;

	char format[64];
	GetPreferenceFormat(client, false, preference, format, sizeof(format));

	char name[128];
	GetPreferenceDisplayName(client, preference, name, sizeof(name));

	MHud_PrintToChat(client, "%T", "chat.enter_value", GetTranslationTarget(client), name);
	MHud_PrintToChat(client, "%T", "chat.value_format", GetTranslationTarget(client), format);
	MHud_PrintToChat(client, "%T", "chat.custom_inputs", GetTranslationTarget(client));
}

static Handle CreateTimeoutTimer(int client)
{
	ResetWaitForPreferenceChatInputFromClient(client);

	int userId = GetClientUserId(client);
	return CreateTimer(15.0, Timer_InputTimeout, userId);
}

public Action Timer_InputTimeout(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client > 0 && IsClientConnected(client))
	{
		MHud_PrintToChat(client, "%T", "chat.input_timed_out", GetTranslationTarget(client));
		ResetWaitForPreferenceChatInputFromClient(client, true);
	}
	return Plugin_Continue;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (InputPreferenceId[client][0] == '\0')
	{
		return Plugin_Continue;
	}

	char inputBuffer[MHUD_MAX_VALUE];
	strcopy(inputBuffer, sizeof(inputBuffer), sArgs);

	TrimString(inputBuffer);

	if (StrEqual(inputBuffer, "cancel", false))
	{
		HandleCancelInput(client);
	}
	else if (StrEqual(inputBuffer, "reset", false))
	{
		HandleResetInput(client, InputPreferenceId[client]);
	}
	else
	{
		HandlePreferenceInput(client, InputPreferenceId[client], inputBuffer);
	}

	RedisplayPreferencesMenu(client, InputMenuSelection[client]);

	ResetWaitForPreferenceChatInputFromClient(client);
	return Plugin_Handled;
}

static void HandleCancelInput(int client)
{
	MHud_PrintToChat(client, "%T", "chat.input_cancelled", GetTranslationTarget(client));
}

static void HandleResetInput(int client, char preferenceId[MHUD_MAX_ID])
{
	Preference preference;

	bool found = GetPreferenceById(preferenceId, preference);
	if (!found)
	{
		return;
	}

	SetPreferenceValue(client, preference, preference.DefaultValue);
	PrintChangeMessage(client, preference);
}

static void HandlePreferenceInput(int client, char preferenceId[MHUD_MAX_ID], char input[MHUD_MAX_VALUE])
{
	Preference preference;

	bool found = GetPreferenceById(preferenceId, preference);
	if (!found)
	{
		return;
	}

	SetPreferenceValue(client, preference, input);
	PrintChangeMessage(client, preference);
}

static void ResetWaitForPreferenceChatInputFromClient(int client, bool fromTimer = false)
{
	InputPreferenceId[client] = "";
	InputMenuSelection[client] = 0;

	Handle timer = InputTimer[client];
	InputTimer[client] = null;

	// Non-repeating timers are auto-closed by SourceMod after callback execution.
	// Avoid manually deleting the handle when reset is called from the timer callback.
	if (!fromTimer && timer != null)
	{
		delete timer;
	}
}
