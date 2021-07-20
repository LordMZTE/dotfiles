function extract_audio
    ffmpeg -i "$argv[1]" -q:a 0 -map a "$argv[2]"
end

