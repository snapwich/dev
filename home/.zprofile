
export N_PREFIX="$HOME/n"
export PATH="$PATH:$HOME/n/bin"

export VISUAL=vim
export EDITOR="$VISUAL"

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

gs() {
  git switch $(git branch | fzf | tr -d '[:space:]')
}

ports() {
    sudo lsof -iTCP -sTCP:LISTEN -n -P | \
    awk 'NR>1 {print $9, $1, $2}' | \
    sed 's/.*://' | \
    while read port process pid; do
        echo "Port $port: $(ps -p $pid -o command= | sed 's/^-//') (PID: $pid)"
    done | sort -n
}

unsetopt PROMPT_SP

