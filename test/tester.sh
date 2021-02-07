x=0
while test $x -lt 5
do
    ./shpy.pl < demo0$x.sh > demo0$x.py
    # echo demo0$x.sh demo0$x.py 
    x=`expr $x + 1`
done
x=0
while test $x -lt 5
do
    ./shpy.pl < test0$x.sh > test0$x.py
    # echo demo0$x.sh demo0$x.py 
    x=`expr $x + 1`
done
