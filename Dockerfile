FROM brinkmanlab/psortb_commandline:1.0.2

# psort writes results to /tmp/results/; CTS only captures files in /out/.
# The wrapper runs psort per input file, checks the result, and moves it to /out/.
COPY run-psort.sh /usr/local/bin/run-psort
RUN chmod +x /usr/local/bin/run-psort

ENTRYPOINT ["/usr/local/bin/run-psort"]
