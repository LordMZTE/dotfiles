def "input disk" [] {
    lsblk --json --list --bytes --output name,path,size,type,mountpoints,fsused,fsuse%,model,uuid
    | from json
    | get blockdevices
    | update size { into filesize }
    | update fsused? { if $in != null { into filesize } }
    | sk --format ({
        let mount = match $in.mountpoints {
            [$mp, ..] => { $mp }
            _ => { "<not mounted>" }
        }
        $"($in.name | fill -w 32) ($in.type | fill -w 5) ($in.size | into string | fill -w 8) ($mount)"
    }) --preview ({ upsert mountpoints { str join "\n" } })
}

def "udisksctl lockmount" [--block-device (-b): path] {
    let cryptdev = udisksctl unlock -b $block_device | parse "{_} as {dev}." | get 0.dev
    udisksctl mount -b $cryptdev
}

def "udisksctl lockunmount" [--block-device (-b): path] {
    let plain_dev = udisksctl info -b $block_device | parse -r "CleartextDevice: +'(?P<dev>.*)'" | get 0.dev

    # This is borked on the udisksctl side
    #udisksctl unmount -p $plain_dev
    (dbus call --system --timeout 356day
      --dest org.freedesktop.UDisks2
      $plain_dev
      org.freedesktop.UDisks2.Filesystem
      Unmount [])

    udisksctl lock -b $block_device
}

def "udisksctl imount" [] {
    udisksctl mount -b (input disk).path
}

def "udisksctl iunmount" [] {
    udisksctl unmount -b (input disk).path
}

def "udisksctl ilockmount" [] {
    udisksctl lockmount -b (input disk).path
}

def "udisksctl ilockunmount" [] {
    udisksctl lockunmount -b (input disk).path
}
