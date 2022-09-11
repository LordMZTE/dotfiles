if set -q SSH_AUTH_SOCK
    exit
end

eval (ssh-agent -c)
ssh-add
