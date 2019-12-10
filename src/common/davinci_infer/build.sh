#!/bin/bash

rm -rf ./src/out
rm -rf DavinciInfer
rm -rf *.so
echo "clean success"

make -f ./src/Makefile_device
make -f ./src/Makefile_host
echo "make success"

cp ./src/out/DavinciInfer ./
echo "copy success"



