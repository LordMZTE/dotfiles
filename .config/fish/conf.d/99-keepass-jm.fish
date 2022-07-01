function jm --wraps=jm
    if [ $argv[1] = up ]
        set token (keepassxc-cli show $KEEPASS_DB jensmemes -sa password)
        command jm up --token $token $argv[2..]
    else
        command jm $argv[1..]
    end
end
