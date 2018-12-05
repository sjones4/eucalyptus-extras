# LinuxKit for Eucalyptus

Dockerfile for LinuxKit and an example `image.yaml` for a minimal
Eucalyptus compatible image.

## Building images
To build the example image, run:

```
# docker run --rm -it \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $(pwd):/working \
  -w /working \
  eucalyptus-linuxkit \
  linuxkit build \
  -name image.img \
  -format raw-bios \
  image.yaml
```

*WARNING* this allows the `eucalyptus-linuxkit` to access docker.

## Installing images
The resulting image can be installed on a Eucalyptus cloud using:

```
# euca-install-image \
  -i image.img \
  --name image \
  --arch x86_64 \
  --virt hvm \
  --bucket image
```
