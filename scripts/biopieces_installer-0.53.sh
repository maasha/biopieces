#!/bin/bash

# Install script for Biopieces.
# Copyright (C) October 2011, Martin A. Hansen

bp_code="$HOME/biopieces"
bp_data="$HOME/BP_DATA"
 bp_log="$HOME/BP_LOG"
 bp_tmp="/tmp"

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

# Function to output an abort message and exit
function exit_abort
{
    echo_red "abort"

    exit
}

# Function to output an success message and exit
function exit_success
{
    echo ""
    echo_green "Congratulations - you have now installed Biopieces."
    echo ""
    echo "   Now you must either run 'source ~/.bashrc' or re-login to your system."
    echo ""
    echo "      * To test your Biopieces installation try 'bp_test'."
    echo "      * To list all available Biopieces try 'list_biopieces'."
    echo "      * To see the synopsis of a Biopiece try 'read_fastq'."
    echo "      * To see the full description and exampels try 'read_fastq -?'."
    echo ""
    echo "   Don't forget to join the Biopieces Google Group for important"
    echo "   messages, questions, discussion, and suggestions:"
    echo ""
    echo "      http://groups.google.com/group/biopieces"
    echo ""
    echo "   And of cause there is the introduction:"
    echo ""
    echo "      http://code.google.com/p/biopieces/wiki/Introduction"
    echo ""
    echo "   Happy hacking!"
    echo ""

    exit
}

# Function to create a directory if it doesn't exist.
function dir_create
{
    local dir=$1

    echo -n "Creating $dir: "

    if error=$( mkdir $dir 2>&1 ); then
        echo_green "OK"
    else
        echo_red "FAIL"
        echo "   $error"
        exit_abort
    fi
}

# Function check if a directory is writable.
function dir_writable
{
    local dir=$1
    local file="$dir/bp_writable"

    echo -n "Writable? $dir: "

    if error=$( touch $file 2>&1 ); then
        echo_green "OK"
        rm $file
    else
        echo_red "FAIL"
        echo "   $error"
        exit_abort
    fi
}

# Function to prompt for continuation of installation.
function prompt_install
{
    echo ""
    echo "Welcome to the Biopieces installer."
    echo ""
    echo "   This installer is experimental, and is being evaluated to replace"
    echo "   the previous, tedious way:"
    echo ""
    echo "      http://code.google.com/p/biopieces/wiki/Installation"
    echo ""
    echo "   The installer will now do the following:"
    echo ""
    echo "   *  Check for existing Biopieces installation."
    echo "   *  Check prerequisites:"
    echo "      -  Subversion client"
    echo "      -  Perl"
    echo "      -  Perl modules"
    echo "      -  Ruby"
    echo "      -  Ruby gems"
    echo "      -  Auxillary programs"
    echo ""
    echo "   *  Create installation directories."
    echo "   *  Download code from repository."
    echo "   *  Set environment in .bashrc."
    echo ""
    echo "   Problems? Check out the FAQ:"
    echo ""
    echo "      http://code.google.com/p/biopieces/wiki/FAQ"
    echo ""
    echo "   Help is available at the Biopieces Google Group:"
    echo ""
    echo "      http://groups.google.com/group/biopieces"
    echo ""
    echo "   Bugs & issues:"
    echo ""
    echo "      http://code.google.com/p/biopieces/issues/list"
    echo ""

    while true; do
        read -p "Continue (yes/no)? " answer
        case $answer in
            [Yy]* ) break;;
            [Nn]* ) exit_abort;;
        esac
    done
}

# Function to prompt the checking of any existing Biopieces installation.
function prompt_install_existing
{
    echo "Checking for existing Biopieces installation:"

    if [ $BP_DIR ]; then
        echo_yellow "   WARNING: \$BP_DIR is already set to: $BP_DIR"
        found=1
    fi

    if [ $BP_DATA ]; then
        echo_yellow "   WARNING: \$BP_DATA is already set to: $BP_DATA"
        found=1
    fi

    if [ $BP_TMP ]; then
        echo_yellow "   WARNING: \$BP_TMP is already set to: $BP_TMP"
        found=1
    fi

    if [ $BP_LOG ]; then
        echo_yellow "   WARNING: \$BP_LOG is already set to: $BP_LOG"
        found=1
    fi

    if [ $found ]; then
        echo ""
        echo "   An old installation of Biopeices appears to exists."
    else
        echo ""
        echo "   No installation of Biopeices found."
    fi

    while true; do
        read -p "Continue (yes/no)? " answer
        case $answer in
            [Yy]* ) break;;
            [Nn]* ) exit_abort;;
        esac
    done
}

# Function to prompt the testing of prerequisites.
function prompt_test_prerequisites
{
    echo "Testing prerequisites:"

    test_bash
    test_svn
    test_perl
    test_perl_module "Inline"
    test_perl_module "SVG"
    test_perl_module "Time::HiRes"
    test_ruby
    test_ruby_gem "gnuplot"
    test_ruby_gem "narray"
    test_ruby_gem "RubyInline"
    test_ruby_gem "terminal-table"
    test_aux_program "blastall"
    test_aux_program "blat"
    test_aux_program "bwa"
    test_aux_program "bowtie"
    test_aux_program "bowtie2"
    test_aux_program "formatdb"
    test_aux_program "gnuplot"
    test_aux_program "hmmsearch"
    test_aux_program "idba_hybrid"
    test_aux_program "muscle"
    test_aux_program "mummer"
    test_aux_program "mysql"
    test_aux_program "prodigal"
    test_aux_program "Ray"
    test_aux_program "scan_for_matches"
    test_aux_program "usearch"
    test_aux_program "velveth"
    test_aux_program "velvetg"
    test_aux_program "vmatch"

    echo ""
    echo "   Any WARNINGs indicate that the executable for that auxillary"
    echo "   program could not be found. While not critical, this will"
    echo "   cause some Biopieces to FAIL. You can install these afterwards."

    while true; do
        read -p "Continue (yes/no)? " answer
        case $answer in
            [Yy]* ) break;;
            [Nn]* ) exit_abort;;
        esac
    done
}

# Function to prompt the selection of the code directory.
function prompt_install_dir_code
{
    read -p "Enter directory for the Biopieces code (default: $bp_code): " answer;

    bp_code=${answer:-"$bp_code"}

    if [ ! -d "$bp_code" ]; then
        while true; do
            read -p "Create directory: $bp_code (yes/no)? " answer
            case $answer in
                [Yy]* ) dir_create $bp_code && break;;
                [Nn]* ) exit_abort;;
            esac
        done
    fi

    dir_writable $bp_code
}

# Function to prompt the selection of the data directory.
function prompt_install_dir_data
{
    read -p "Enter directory for the Biopieces data (default: $bp_data): " answer;

    bp_data=${answer:-"$bp_data"}

    if [ ! -d "$bp_data" ]; then
        while true; do
            read -p "Create directory: $bp_data (yes/no)? " answer
            case $answer in
                [Yy]* ) dir_create $bp_data && break;;
                [Nn]* ) exit_abort;;
            esac
        done
    fi

    dir_writable $bp_data
}

# Function to prompt the selection of the log directory.
function prompt_install_dir_log
{
    read -p "Enter directory for the Biopieces log file (default: $bp_log): " answer;

    bp_log=${answer:-"$bp_log"}

    if [ ! -d "$bp_log" ]; then
        while true; do
            read -p "Create directory: $bp_log (yes/no)? " answer
            case $answer in
                [Yy]* ) dir_create $bp_log && break;;
                [Nn]* ) exit_abort;;
            esac
        done
    fi

    dir_writable $bp_log
}

# Function to prompt the selection of the tmp directory.
function prompt_install_dir_tmp
{
    read -p "Enter directory for the Biopieces temporary files (default: $bp_tmp): " answer;

    bp_tmp=${answer:-"$bp_tmp"}

    if [ ! -d "$bp_tmp" ]; then
        while true; do
            read -p "Create directory: $bp_tmp (yes/no)? " answer
            case $answer in
                [Yy]* ) dir_create $bp_tmp && break;;
                [Nn]* ) exit_abort;;
            esac
        done
    fi

    dir_writable $bp_tmp
}

# Function to prompt the appending of a section to bashrc.
function prompt_append_bashrc
{
    local skip=0
    local section="

# >>>>>>>>>>>>>>>>>>>>>>> Enabling Biopieces <<<<<<<<<<<<<<<<<<<<<<<

export BP_DIR=\"$bp_code\"
export BP_DATA=\"$bp_data\"
export BP_TMP=\"$bp_tmp\"
export BP_LOG=\"$bp_log\"

source \"\$BP_DIR/bp_conf/bashrc\"

# >>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<

"

    echo ""
    echo "We need to append the below section to your .bashrc file."

    echo_yellow "$section"

    while true; do
        read -p "Append (yes/no/abort)? " answer
        case $answer in
            [Yy]* ) skip=0 && break;;
            [Nn]* ) skip=1 && break;;
            [Aa]* ) exit_abort;;
        esac
    done

    if [ $skip == 1 ]; then
        echo "Skipping"
    else
        if [ -f "$HOME/.bashrc" ]; then
            echo "Existing .bashrc file located: $HOME/.bashrc"
            echo -n "Creating backup: "

            if ! cp "$HOME/.bashrc" "$HOME/.bashrc_biopieces"; then
                echo_red "FAIL"
                abort
            else
                echo_green "OK"
                echo "   Backup is $HOME/.bashrc_biopieces"
            fi
        fi

        echo -n "Appending $HOME/.bashrc: "

        if ! echo "$section" >> "$HOME/.bashrc"; then
            echo_red "FAIL"
            abort
        else
            echo_green "OK"
        fi

        echo -n "Testing $HOME/.bashrc: "

        if ! source "$HOME/.bashrc"; then
            echo_red "FAIL"
            abort
        else
            echo_green "OK"
        fi

        export BP_DIR="$bp_code"
        export BP_DATA="$bp_data"
        export BP_TMP="$bp_tmp"
        export BP_LOG="$bp_log"

        echo ""
        echo "   \$BP_DIR is now set to: $BP_DIR"
        echo "   \$BP_DATA is now set to: $BP_DATA"
        echo "   \$BP_TMP is now set to: $BP_TMP"
        echo "   \$BP_LOG is now set to: $BP_LOG"
        echo ""

        while true; do
            read -p "Continue (yes/no)? " answer
            case $answer in
                [Yy]* ) break;;
                [Nn]* ) exit_abort;;
            esac
        done
    fi
}

# Function to test if we are running bash.
function test_bash
{
    echo -n "   Testing if the running shell is bash: "

    if [ `echo $SHELL | grep "bash"` ]; then
        echo_green "OK"
    else
        echo_red "FAIL"
        echo "      Biopieces requires bash shell not - $SHELL."
        exit_abort
    fi
}

# Function to test if subversion client is in $PATH.
function test_svn
{
    local program="svn"

    echo -n "   Testing subversion client - \"$program\": "

    if command -v $program >/dev/null; then
        echo_green "OK"
    else
        echo_red "FAIL"
        echo "      Subversion client $program was not found."
        exit_abort
    fi
}

# Function to test if the required version of Perl is installed.
function test_perl
{
    echo -n "   Testing Perl version: "

    if error=$( perl -e 'use 5.8.0;' 2>&1 ); then
        echo_green "OK"
    else
        echo_red "FAIL"
        echo "   $error" | sed "s/, stopped.*//"
        exit_abort
    fi  
}

# Function to test if a given Perl module is installed.
function test_perl_module
{
    local module=$1

    echo -n "   Testing required Perl module - \"$module\": "

    if ! error=$( perl -M$module -e '' 2>&1 > /dev/null ); then
        echo_red "FAIL"
        echo "   Try: perl -MCPAN -e 'install $module'"
        exit_abort
    else
        echo_green "OK"
    fi
}

# Function to test if the required version of Ruby is installed.
function test_ruby
{
    echo -n "   Testing Ruby version: "

    if ! [ `which ruby` ]; then
        echo_red "FAIL"
        echo "    Ruby version 1.9 required"
        exit_abort
    fi

    if error=$( ruby -e 'raise "Ruby version 1.9 required--this is only #{RUBY_VERSION}" if RUBY_VERSION < "1.9"' 2>&1 ); then
        echo_green "OK"
    else
        echo_red "FAIL"
        echo $error
        exit_abort
    fi  
}

# Function to test if a given Ruby gem is installed.
function test_ruby_gem
{
    local gem=$1

    echo -n "   Testing required Ruby gem - \"$gem\": "

    if error=$( gem list --local | grep $gem ); then
        echo_green "OK"
    elif [[ $gem == 'RubyInline' ]] && error=$( ruby -rinline -e '' ); then
        echo_yellow "OK"
    else
        echo_red "FAIL"
        echo "      Try: gem install $gem"
        exit_abort
    fi
}

# Function to test is a given auxillary program is in $PATH.
function test_aux_program
{
    local program=$1

    echo -n "   Testing auxiliary program - \"$program\": "

    if command -v $program >/dev/null; then
        echo_green "OK"
    else
        echo_yellow "WARNING"
    fi
}

# Function to checkout the Biopieces code from subversion.
function checkout_code
{
    echo -n "Downloading Biopieces code from repository (please wait): "

    if error=$( svn checkout http://biopieces.googlecode.com/svn/trunk/ $bp_code ); then
        echo_green "OK"
    else
        echo_red "FAIL"
        echo "   $error"
        exit_abort
    fi  
}

# Function to checkout the Biopieces wiki from subversion.
function checkout_wiki
{
    echo -n "Downloading Biopieces wiki from repository (please wait): "

    if error=$( svn checkout http://biopieces.googlecode.com/svn/wiki/ "$bp_code/bp_usage" ); then
        echo_green "OK"
    else
        echo_red "FAIL"
        echo "   $error"
        exit_abort
    fi  
}

prompt_install
prompt_install_existing
prompt_test_prerequisites
prompt_install_dir_code
prompt_install_dir_data
prompt_install_dir_log
prompt_install_dir_tmp

checkout_code
checkout_wiki

prompt_append_bashrc

exit_success

