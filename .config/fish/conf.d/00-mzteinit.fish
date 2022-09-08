if set -q MZTEINIT
    exit
end
set -x MZTEINIT
exec mzteinit
