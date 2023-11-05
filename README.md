# fespino .dotfiles

TODO

## FAQ

### Pairing a bluetooth headset in Debian

```bash
$ bluetoothctl
power on
agent on
default-agent
scan on
```

Make sure the device is pairing. When it is discovered:

```
pair <MAC>
connect <MAC> 
```

Then open Pulseaudio and control it as any other audio device.

If you want to automatically connect to the device in the future:

```
trust <MAC>
``` 