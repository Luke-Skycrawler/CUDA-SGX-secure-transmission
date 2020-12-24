#!/usr/bin/bash
for i in 5 10 20 50 100
do
    ./matrixMulCUBLAS -sizemult=${i} -verify=0 -iter=100 -encrypt=0>> c.txt
done
for i in 30 100 1000 10000
do
    ./matrixMulCUBLAS -sizemult=10 -verify=0 -iter=${i} -encrypt=0>> d.txt
done