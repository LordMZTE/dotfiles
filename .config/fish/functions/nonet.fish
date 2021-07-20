function nonet
	sudo unshare -n -- sudo -u $USER $argv
end

