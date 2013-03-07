brainfuck interpreter benchmark scripts
========================================
some scripts to benchmark my brainfuck interpreter

Usage
------
### clone and rename the repostories ###
`git://github.com/xatier/brainfuck-bench.git`

`cd brainfuck-bench`

`git clone git://github.com/xatier/brainfuck-tools.git`

`mv brainfuck-tools/ bf-git`

------------
**Note in Mac OS X
!!**

the script equires [gnu time](http://www.gnu.org/software/time/), plz install it with [homebrew](http://mxcl.github.com/homebrew/)

`$ brew install gnu-time`

use `usr/local/bin/gtime` instead of `/usr/bin/time` in **bench.sh**

------------

### run ###

    $ ./bench.sh
    $ /avg.pl < bench
    
    $ /avg.pl < bench > output.csv

use Libreoffice Calc to open the csv file
Insert -> Chart


Licence
----------
Licensed under [GPL license][GPL].
[GPL]: http://www.gnu.org/licenses/gpl.html
