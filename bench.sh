bench () {
    cd bf-git/
    git checkout $1
    gcc -O2 int.c -o int
    echo "$1" >> ../bench
    for i in `seq 5`
    do
        /usr/bin/time --format=%U -a -o ../bench ./int < $2 > /dev/null
    done
    cd ..
}


#echo "mandelbrot.b" >> bench
#bench "loop" "../mandelbrot.b"
#bench "compact" "../mandelbrot.b"
#bench "zero" "../mandelbrot.b"
#bench "master" "../mandelbrot.b"

echo "hanoi.bf" >> bench
bench "loop" "../hanoi.bf"
bench "compact" "../hanoi.bf"
bench "zero" "../hanoi.bf"
bench "master" "../hanoi.bf"


echo "loops.bf" >> bench
bench "loop" "../loops.bf"
bench "compact" "../loops.bf"
bench "zero" "../loops.bf"
bench "master" "../loops.bf"

echo "bench.bf" >> bench
bench "loop" "../bench.bf"
bench "compact" "../bench.bf"
bench "zero" "../bench.bf"
bench "master" "../bench.bf"

#./avg.pl < bench > output.csv
