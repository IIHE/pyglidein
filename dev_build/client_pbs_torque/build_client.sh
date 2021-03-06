#!/bin/bash -e
# Copy pyglidein egg to inside container
rm -f root/pyglidein-*
cp ../../dist/pyglidein* root/
rm -f root.tar.gz
cd root
tar czvf ../root.tar.gz .
cd ..
docker build -t wipac/pyglidein_client_pbs_torque:1.0 .
