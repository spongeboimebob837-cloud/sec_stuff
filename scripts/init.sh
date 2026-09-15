#!/bin/bash

export BASE="$PWD"
export OBS="$BASE/environment"

cd $OBS 

./buildvectors
./buildbags
./buildfvs
./buildclasses

