FROM brinkmanlab/psortb_commandline:1.0.2

# psortb model data is baked into the image, no CTS refdata needed.
# The psort binary lives at /usr/local/psortb/bin/psort in this base image.
ENTRYPOINT ["/usr/local/psortb/bin/psort"]
