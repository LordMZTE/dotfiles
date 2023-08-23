# makes the `jm up` command get the token from bitwarden using rbw
function jm --wraps=jm
    if [ $argv[1] = up ]
        set token (rbw get jensmemes)
        command jm up --token $token $argv[2..]
    else
        command jm $argv[1..]
    end
end
