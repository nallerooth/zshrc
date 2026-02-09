###############################################################################
### Aliases ###
###############################################################################
alias ls='ls -hG' # Change G to --color=auto on Linux
alias ll='ls -l'
alias la='ls -la'
alias l='ls -lA'
alias ..='cd ..'


###############################################################################
# Enable completion caching for faster performance
###############################################################################
zcompdump="$HOME/.zcompdump"

# Load compinit, but only run the slow audit check once a day
# Delete the cache file to force a re-audit if needed
# -i ignores insecure directories (skips compaudit)
# -C skips the cache-invalidation check
if [[ -s "$zcompdump" && (! -f "$zcompdump.zwc" || "$zcompdump" -nt "$zcompdump.zwc") ]]; then
  zcompile "$zcompdump"
fi

autoload -Uz compinit
compinit -C -d "$zcompdump"

# Case-insensitive AND allows partial matching before a dot or hyphen
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Accept abbreviations (optional but helpful)
# This allows 'cd /u/l/b' to match '/usr/local/bin'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select
bindkey '^I' menu-complete 			 # Tab for forward completion
bindkey '^[[Z' reverse-menu-complete # Shift-Tab for reverse completion

###############################################################################
### Prompt with Git and AWS info ###
###############################################################################

# Load Git integration
autoload -Uz vcs_info
precmd_vcs_info() {
	vcs_info_msg_0_="";
	vcs_info
}
precmd_functions+=(precmd_vcs_info)

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' get-revision true
zstyle ':vcs_info:git*:*' unstagedstr '%F{208}* %f'
zstyle ':vcs_info:git*:*' stagedstr '%F{76}+ %f'
zstyle ':vcs_info:git:*' formats '%F{244}(%b)%f %c%u'


# Function to get AWS status
aws_context() {
    if [[ -n $AWS_PROFILE ]]; then
        local region="${AWS_REGION:-no-region}"
        local color

        # Determine color based on profile name
        case "$AWS_PROFILE" in
            "production") color="160" ;; # Red
            "playground") color="33"  ;; # Blue
            *)            color="208" ;; # Orange (default)
        esac

        echo "%F{$color}aws:(%B$AWS_PROFILE%b|${region})%f"
    fi
}


###############################################################################
### History management ###
###############################################################################
# Setup History file (if not already there)
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY       # Append to history file, don't overwrite
setopt SHARE_HISTORY        # Share history between different tabs

# Bind Up/Down arrows to search history based on current input
# This handles the most common terminal codes for arrow keys
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

# Bind up/down arrows to seearch history based on current input
# The escape sequences can vary between terminals, so we bind both common forms
bindkey '^[[A' up-line-or-beginning-search	
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search


###############################################################################
### Prompt configuration and vertical spacing ###
###############################################################################

# Print a newline before each prompt to create vertical spacing between
# commands and their output, but only if we're not at the top of the terminal.
precmd_functions+=(print_newline)
print_newline() {
  print ""
}

# Enable parameter expansion in the prompt
setopt PROMPT_SUBST

# Define the prompt
# %~ = current directory
# %# = '#' for root, '%' for regular user
PROMPT='$(aws_context) %F{244}:: %F{255}%~%f ${vcs_info_msg_0_}
%(?.%F{244}.%F{160})%#%f '

# Fix slow typing/pasting on macOS
unset paste_magic_functions
