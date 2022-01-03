cat ~/.tool-versions | awk '{print $1}' | xargs -n1 asdf plugin add
