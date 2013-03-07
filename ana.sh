#!/bin/bash
# to analysis a brianfuck program
cat $1 | fold -w1  | sort | uniq -c | less
