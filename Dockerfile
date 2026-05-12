FROM brinkmanlab/psortb_commandline:1.0.2

# psort always writes results to stdout; CTS only captures files in /out/.
# Wrap psort in a shell script that redirects stdout to a file in /out/.
COPY run-psort.sh /usr/local/bin/run-psort
RUN chmod +x /usr/local/bin/run-psort

ENTRYPOINT ["/usr/local/bin/run-psort"]
