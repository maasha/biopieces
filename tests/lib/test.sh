#!/bin/bash

bp=`basename $0 | sed s/^test_//`
in="$BP_DIR/tests/in/$bp.in"
out="$BP_DIR/tests/out/$bp.out"
tmp="$BP_TMP/$USER.$bp.out"
tmp_dir="$BP_TMP/$USER.test_tmp"
log_file="$BP_TMP/$USER.test.log"

# Function to run a given command (verbose).
function run
{
    local command=$1

    msg="${command/$BP_DIR/\$BP_DIR}"
    msg="${msg//$BP_TMP/\$BP_TMP}"
    msg="${msg/$BP_DIR/\$BP_DIR}"

    echo -n "Testing $msg ... "
    eval $command > /dev/null 2>&1
}

# Function to run a given command (quiet).
function run_quiet
{
    local command=$1

    eval $command > /dev/null 2>&1
}

# Function to assert no difference between
# two given files.
function assert_no_diff
{
    local src=$1
    local dst=$2
    local src_sort="$BP_TMP/`basename $src`.sort"
    local dst_sort="$BP_TMP/`basename $dst`.sort"

    if [ ! -f $src ]; then
        echo_red "FAIL"
        log "FAIL"
        return
    fi

    if [ ! -f $dst ]; then
        echo_red "FAIL"
        log "FAIL"
        return
    fi

    cat $src | perl -e '$/ = "\n---\n"; while (<>) {chomp; print join("\n", sort split "\n", $_), "\n---\n" }' > "$src_sort"
    cat $dst | perl -e '$/ = "\n---\n"; while (<>) {chomp; print join("\n", sort split "\n", $_), "\n---\n" }' > "$dst_sort"

    local diff=`diff -q "$src_sort" "$dst_sort"`

    rm "$src_sort"
    rm "$dst_sort"

    if [ "$diff" != "" ]; then
        echo_red "FAIL"
        log "FAIL"
    else
        echo_green "OK"
        log "OK"
    fi
}

# Function to assert no difference between the content
# of two given direcories (recursive).
function assert_no_diff_dir
{
    local src_dir=$1
    local dst_dir=$2

    if [ ! -d $src_dir ]; then
        echo_red "FAIL"
        log "FAIL"
        return
    fi

    if [ ! -d $dst_dir ]; then
        echo_red "FAIL"
        log "FAIL"
        return
    fi

    local src_cksum=`find $src_dir -type f | grep -v "\.svn" | sort | xargs cat | cksum`
    local dst_cksum=`find $dst_dir -type f | grep -v "\.svn" | sort | xargs cat | cksum`

    if [ "$src_cksum" == "$dst_cksum" ]; then
        echo_green "OK"
        log "OK"
    else
        echo_red "FAIL"
        log "FAIL"
    fi
}

# Function to assert that all given files do exists.
function assert_files_exists
{
    error=0

    for arg in "$@"; do
        if [ ! -f $arg ]; then
            error=1
        fi
    done

    if [ $error = 1 ]; then
        echo_red "FAIL"
        log "FAIL"
    else
        echo_green "OK"
        log "OK"
    fi
}

# Function to output a given message to the log file.
function log
{
    local msg=$1

    echo "$msg" >> $log_file
}

# Function that renders a given message in ASCII green.
function echo_green
{
    local msg=$1

    echo -e "\033[32;38m$msg\033[0m"
}

# Function that renders a given message in ASCII yellow.
function echo_yellow
{
    local msg=$1

    echo -e "\033[33;38m$msg\033[0m"
}

# Function that renders a given message in ASCII red.
function echo_red
{
    local msg=$1

    echo -e "\033[31;38m$msg\033[0m"
}

# Function to clean the temporary file.
function clean
{
    if [ -f "$tmp" ]; then
        rm "$tmp"
    fi
}

# Function to test if the required version of Perl is installed.
function test_perl
{
    echo -n "Testing Perl version ... "

    if error=$( perl -e 'use 5.8.0;' 2>&1 ); then
        echo_green "OK"
        log "OK"
    else
        echo $error | sed "s/, stopped.*//"
        echo_red "FAIL"
        exit
    fi
}

# Function to test if a given Perl module is installed.
function test_perl_module
{
    local module=$1

    echo -n "Testing required Perl module - \"$module\": "

    if ! error=$( perl -M$module -e '' 2>&1 > /dev/null ); then
        echo_red "FAIL"
        echo "   Try: perl -MCPAN -e 'install $module'"
        exit
    else
        echo_green "OK"
        log "OK"
    fi
}

# Function to test if the required version of Ruby is installed.
function test_ruby
{
    echo -n "Testing Ruby version ... "

    if error=$( ruby -e 'raise "Ruby version 1.9 required--this is only #{RUBY_VERSION}" if RUBY_VERSION < "1.9"' 2>&1 ); then
        echo_green "OK"
        log "OK"
    else
        echo $error | sed "s/.*: //"
        echo_red "FAIL"
        exit
    fi
}

# Function to test if a given Ruby gem is installed.
function test_ruby_gem
{
    local gem=$1

    echo -n "Testing required Ruby gem - \"$gem\": "

    if error=$( gem list --local | grep $gem ); then
        echo_green "OK"
        log "OK"
    else
        echo_red "FAIL"
        echo "   Try: gem install $gem"
        exit
    fi
}

# Function to test is a given auxillary program is in $PATH.
function test_aux_program
{
    local program=$1

    echo -n "Testing auxiliary program - \"$program\": "

    if command -v $program >/dev/null; then
        echo_green "OK"
        log "OK"
    else
        echo_yellow "WARNING"
        log "WARNING"
    fi
}
