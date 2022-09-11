if set -q MZTEINIT
    exit
end
set -gx MZTEINIT
exec mzteinit
