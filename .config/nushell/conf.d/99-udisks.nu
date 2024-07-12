def "udisksctl lockmount" [--block-device (-b): path] {
    let cryptdev = udisksctl unlock -b $block_device | parse "{_} as {dev}." | get 0.dev
    udisksctl mount -b $cryptdev
}

def "udisksctl lockumount" [--block-device (-b): path] {
    let plain_dev = udisksctl info -b $block_device | parse -r "CleartextDevice: +'(?P<dev>.*)'" | get 0.dev

    # This is borked on the udisksctl side
    #udisksctl unmount -p $plain_dev
    (dbus call --system
      --dest org.freedesktop.UDisks2
      $plain_dev
      org.freedesktop.UDisks2.Filesystem
      Unmount [])

    udisksctl lock -b $block_device
}
