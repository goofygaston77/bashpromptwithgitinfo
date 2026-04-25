# Git information for the prompt
# Gets called automatically with every new prompt
__git_info() {
    local branch untracked modified color reset

    # Get the current branch name (e.g. "main" or "feature/xyz")
    # If no branch exists (detached HEAD), use the short commit hash instead
    # If not inside a git repo at all → exit immediately (return), print nothing
    branch=$(git symbolic-ref --short HEAD 2>/dev/null) || \
    branch=$(git rev-parse --short HEAD 2>/dev/null) || return

    # Single git call instead of 3 separate ones → less overhead.
    # timeout 3: abort if git hangs (e.g. repos with many untracked files).
    # --untracked-files=normal: treat untracked dirs as a single entry, don't recurse.
    #   Combined with: git config core.untrackedCache true   (set once per slow repo)
    #   → git only rescans directories whose mtime changed, making it fast.
    local status
    status=$(timeout 3 git status --porcelain --untracked-files=normal 2>/dev/null)

    # Staged or unstaged changes: any output line that is not an untracked marker
    [ -n "$status" ] && echo "$status" | grep -qv '^??' && modified="*"

    # Untracked files
    [ -n "$status" ] && echo "$status" | grep -q '^??' && untracked="?"

    # Reset sequence: restores color back to normal after the branch name
    # \001 and \002 are required here instead of \[ and \], because we are inside a function
    reset="\001\e[0m\002"

    # Color based on current state:
    # Red    → modified or staged changes exist (highest priority)
    # Yellow → only untracked files present
    # Green  → everything committed, working tree clean
    if [ -n "$modified" ]; then
        color="\001\e[1;31m\002"   # Red
    elif [ -n "$untracked" ]; then
        color="\001\e[1;33m\002"   # Yellow
    else
        color="\001\e[1;32m\002"   # Green
    fi

    # Output: space + color + (branchname + symbols) + reset
    # Examples: " (main)" / " (main?)" / " (main*)" / " (main*?)"
    echo -e " ${color}(${branch}${modified}${untracked})${reset}"
}

# The actual prompt (PS1):
# \[\e[1;33m\]\u   → username in yellow
# \[\e[0;37m\]@    → @ in white
# \[\e[1;33m\]\h   → hostname in yellow
# \[\e[0m\]:       → colon in default color
# \[\e[1;34m\]\w   → current directory in blue (\w = full path)
# \[\e[0m\]        → reset color
# $(__git_info)    → call git function (prints nothing if not in a repo)
# \[\e[1;37m\]\$   → $ or # (root) in white
# \[\e[0m\]        → reset color at the end
PS1='\[\e[1;33m\]\u\[\e[0;37m\]@\[\e[1;33m\]\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]$(__git_info)\[\e[1;37m\]\$\[\e[0m\] '