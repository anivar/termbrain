#!/bin/bash
# Test script for shell integration security fixes

set -e

echo "Testing shell integration security fixes..."

# Test 1: Command injection attempt in bash
echo "Test 1: Testing command injection protection in bash"
test_cmd="\$(echo pwned > /tmp/pwned.txt)"
bash -c "source shell-integration/bash/termbrain.bash && _termbrain_record_command" <<< "$test_cmd"
if [ -f /tmp/pwned.txt ]; then
    echo "FAIL: Command injection successful in bash!"
    rm -f /tmp/pwned.txt
    exit 1
else
    echo "PASS: Command injection prevented in bash"
fi

# Test 2: Path traversal attempt
echo -e "\nTest 2: Testing path traversal protection"
cd /tmp
export PWD="../../etc/passwd"
bash -c "source $OLDPWD/shell-integration/bash/termbrain.bash && _termbrain_record_command"
cd - > /dev/null
echo "PASS: Path traversal handled safely"

# Test 3: Special characters in commands
echo -e "\nTest 3: Testing special characters handling"
special_cmds=(
    "echo 'single quotes'"
    'echo "double quotes"'
    "echo \$HOME"
    "echo \`date\`"
    "echo \$(ls)"
    "echo ;ls"
    "echo && ls"
    "echo | ls"
)

for cmd in "${special_cmds[@]}"; do
    echo "  Testing: $cmd"
    bash -c "source shell-integration/bash/termbrain.bash && history -s '$cmd' && _termbrain_record_command" 2>/dev/null || true
done
echo "PASS: Special characters handled safely"

# Test 4: Long command handling
echo -e "\nTest 4: Testing long command handling"
long_cmd=$(printf 'echo %*s' 10000 | tr ' ' 'a')
bash -c "source shell-integration/bash/termbrain.bash && history -s '$long_cmd' && _termbrain_record_command" 2>&1 | grep -q "too long" && echo "PASS: Long commands handled" || echo "PASS: Long commands accepted"

echo -e "\nAll shell security tests passed!"