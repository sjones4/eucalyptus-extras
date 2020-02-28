# Eucalyptus Build Utilities

Environment
------
These build scripts are intended for use with the CentOS 7 image:

```
http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.raw.tar.gz
```

which can be installed using the installer / catalog from this repository.

The build scripts should be run as root.

To build the service image you will want to ensure nested virtualization is enabled:

```
# cat /sys/module/kvm_intel/parameters/nested
Y
```

if not, then to enable you may need to set:

```
# cat /etc/modprobe.d/kvm-nested.conf
options kvm_intel nested=1
```

and enable **_/etc/eucalyptus/eucalyptus.conf_** on the node controllers:

```
USE_CPU_PASSTHROUGH="1"
```

the build for the service image will be slow without nested virtualization.

The recommended instance type to use for building is **_m3.2xlarge_**. If not building the service image then a smaller instance type would suffice.

Build Scripts
------
To build rpms for the latest code run:

```
./build-all-rpms.sh
```

RPM artifacts will be in the **_rpms_** directory.

Docker Image
------
These build scripts are available in a docker image for use building rpms or intermediate artifacts:

```
  docker pull sjones4/eucalyptus-builder:5
```

To build the eucalyptus java dependencies rpm you would use:

```
  mkdir -p eucalyptus/rpms
  docker run --rm \
    --env RPM_OUT=/eucalyptus/rpms \
    -v "$(pwd)"/eucalyptus:/eucalyptus \
    sjones4/eucalyptus-builder:5 \
    build-eucalyptus-cloud-libs-rpm.sh
```

To build eucalyptus software using an existing checkout you would use:

```
  git clone --depth 1 \
    https://github.com/corymbia/eucalyptus.git
  pushd eucalyptus/clc
  git clone --depth 1 \
    https://github.com/corymbia/eucalyptus-cloud-libs.git lib
  touch .nogit
  popd
  docker run --rm \
    -v "$(pwd)"/eucalyptus:/eucalyptus \
    -w /eucalyptus \
    sjones4/eucalyptus-builder:5 \
    bash -c "./configure --prefix=/ --with-axis2c=/usr/lib64/axis2c && make"
```




