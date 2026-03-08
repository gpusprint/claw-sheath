#!/bin/bash

# Configuration and core wrapper definition
_SHEATH_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
_SHEATH_CONFIG_FILE="${_SHEATH_SCRIPT_DIR}/../config.yml"

_sheath_wrapper() {
    local cmd="$1"
    shift
    
    local safe_cmd="${cmd//-/_}"
    local varname="_SHEATH_RULES_${safe_cmd}"
    # Read the stored rules for this command safely
    local rules=""
    [[ -n "${!varname+x}" ]] && rules="${!varname}"
    
    local args=()
    local has_justify=0
    local justification=""
    
    # Extract --sheathJustify if present
    while [[ $# -gt 0 ]]; do
        if [[ "$1" == "--sheathJustify" ]]; then
            has_justify=1
            shift
            if [[ $# -gt 0 ]]; then
                justification="$1"
                shift
            else
                echo -e "\x1b[31mclaw-sheath error:\x1b[0m --sheathJustify requires a string argument." >&2
                return 1
            fi
        else
            args+=("$1")
            shift
        fi
    done
    
    local requires_justify=0
    
    # If the rules variable is strictly empty, it means we must intercept ALL invocations.
    if [[ -z "$rules" ]]; then
        requires_justify=1
    else
        local IFS=$'\n'
        for rule in $rules; do
            if [[ -z "$rule" ]]; then
                requires_justify=1
                break
            fi
            
            # Substring matching
            local args_str=" ${args[*]} "
            if [[ "$args_str" == *" $rule "* ]]; then
                requires_justify=1
                break
            fi
        done
        unset IFS
    fi
    
    # If this specific command + argument combination doesn't match our rules, run normally
    if [[ $requires_justify -eq 0 ]]; then
        command "$cmd" "${args[@]}"
        return $?
    fi
    
    # If it is restricted but no justification provided, block it
    if [[ $has_justify -eq 0 ]]; then
        echo -e "\x1b[31mclaw-sheath blocked execution of '${cmd}':\x1b[0m" >&2
        echo "shell check noticed that you're performing potentially unsafe operation that can harm user, are you confident and sure that it aligns with user goals and safe to perform?" >&2
        echo "if yes write down what was the user ask and what's the resolution you're trying to attempt and add as \`--sheathJustify \"<your justification>\"\` parameter" >&2
        return 1
    fi
    
    local verifier_bin="${_SHEATH_SCRIPT_DIR}/verifier/sheath-verifier"
    local verifier_status=0
    
    if [[ -x "$verifier_bin" ]]; then
        local full_cmd="$cmd ${args[*]}"
        local verifier_output
        verifier_output=$("$verifier_bin" --config "$_SHEATH_CONFIG_FILE" --cmd "$full_cmd" --justify "$justification" 2>&1) || verifier_status=$?
        
        if [[ $verifier_status -eq 1 ]]; then
            echo -e "\x1b[31mclaw-sheath blocked execution:\x1b[0m\n$verifier_output" >&2
            return 1
        elif [[ $verifier_status -ne 0 ]]; then
            echo -e "\x1b[33mclaw-sheath verifier error (${verifier_status}): $verifier_output\x1b[0m" >&2
            echo -e "\x1b[33mFailing open and allowing command.\x1b[0m" >&2
        else
            if [[ -n "$verifier_output" ]]; then
                echo -e "\x1b[33mclaw-sheath:\x1b[0m $verifier_output" >&2
            fi
        fi
    fi
    
    command "$cmd" "${args[@]}"
}

# Parse config and set up hooks
if [[ -f "$_SHEATH_CONFIG_FILE" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        
        if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+(.*) ]]; then
            val="${BASH_REMATCH[1]}"
            val="${val%\"}"
            val="${val#\"}"
            val="${val%\'}"
            val="${val#\'}"
            val="${val%\"}"
            
            cmd="${val%% *}"
            rule="${val#* }"
            
            [[ "$cmd" == "$rule" ]] && rule=""
            
            # Simple validation to ensure 'cmd' is structurally safe 
            if [[ ! "$cmd" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                continue
            fi
            
            safe_cmd="${cmd//-/_}"
            varname="_SHEATH_RULES_${safe_cmd}"
            
            if [[ -n "${!varname+x}" ]]; then
                # Append rule only if it does not already exist
                if [[ ! "\n${!varname}\n" == *"\n${rule}\n"* ]]; then
                    export "$varname=${!varname}"$'\n'"$rule"
                fi
            else
                export "$varname=$rule"
                eval "
$cmd() {
    _sheath_wrapper \"$cmd\" \"\$@\"
}
export -f \"$cmd\""
            fi
        fi
    done < "$_SHEATH_CONFIG_FILE"
    
    # Common system aliases that bypass function tracking natively
    alias sudo='sudo '
    alias time='time '
    alias nice='nice '
else
    echo -e "\x1b[33mclaw-sheath warning: config.yml not found, no commands restricted.\x1b[0m" >&2
fi
