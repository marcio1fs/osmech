param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

# Force skipping any mavenrc hooks that can hang in this environment.
$env:MAVEN_SKIP_RC = 'on'

& mvn @Args
exit $LASTEXITCODE
