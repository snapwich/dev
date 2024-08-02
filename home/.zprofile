
export N_PREFIX="$HOME/n"
export PATH="$PATH:$HOME/n/bin"

export VISUAL=vim
export EDITOR="$VISUAL"

gs() {
  git switch $(git branch | fzf | tr -d '[:space:]')
}
