#origin=`pwd`
#cd ../../
origin="sample/no03.n0012"

# move input file and checkout
cp $origin/checkout.inp .
cp $origin/*.x .
./checkout.py

# move necessary input files
cp $origin/control.inp checkout/
rm checkout/control.raw.inp

cp $origin/condition.f90 checkout/
rm checkout/condition.raw.f90

# move to 'checkout' and make/run
cd checkout
make
ulimit -s unlimited
./main
