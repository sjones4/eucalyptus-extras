# Eucalyptus Cookbooks

Image with faststart script and all chef cookbooks needed to deploy a
eucalyptus cloud.

## Cookbooks Package

The cookbooks package location is:

```
/eucalyptus-cookbook/eucalyptus-cookbooks.tgz
```

## Faststart script

The faststart script location is:

```
/eucalyptus-cookbook/cloud-in-a-box.sh
```

Run the script using the `-u` option to specify an alternative cookbook
location, for example:

```
./cloud-in-a-box.sh -u file:$(pwd)/eucalyptus-cookbooks.tgz 
```

to use the `eucalyptus-cookbooks.tgz` file in the current directory.
