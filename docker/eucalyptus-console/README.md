# Eucalyptus console image

Dockerfile for the eucalyptus console (`eucaconsole`) on Fedora 29.

## Direct use
When run in a eucalyptus cloud no additional configuration is required
but it is recommended to use an ELB with `https` for accessing the
console.

If running outside of a eucalyptus cloud the ufshost must be configured,
for example:

```
[app:main]
use = config:/etc/eucaconsole/console-main-defaults.ini
ufshost = ec2.my-euca-cloud-10-10-10-42.euca.me
```

and run with:

```
# docker run --rm -it \
  -p 8888:8888 \
  -v $(pwd)/console-main.ini:/etc/eucaconsole/console-main.ini \
  sjones4/eucalyptus-console:4.4 eucaconsole
```

## LinuxKit use
The `eucalyptus-console.yaml` enables use of the eucaconsole container
in a LinuxKit image.

The image size should be updated when installing, e.g.

```
# truncate --size 5G eucalyptus-console-bios.img
# euca-install-image -i eucalyptus-console-bios.img ...
```

