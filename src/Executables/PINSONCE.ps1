# Runs once at the first sign-in after the playbook: the ConfigureStartPins policy
# has already been applied and Windows has rebuilt the pinned list from it, so
# removing it here keeps the pins and gives the user their Start menu back.
$key = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start'

Remove-ItemProperty -LiteralPath $key -Name 'ConfigureStartPins' -ErrorAction SilentlyContinue
Remove-ItemProperty -LiteralPath $key -Name 'ConfigureStartPins_ProviderSet' -ErrorAction SilentlyContinue

# Windows deletes the RunOnce entry after it runs; remove the script itself too so
# nothing is left behind.
Remove-Item -LiteralPath $PSCommandPath -Force -ErrorAction SilentlyContinue
